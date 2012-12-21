unit imaqUnit;
// -------------------------------------------------------
// National Instruments IMAQ image capture library support
// -------------------------------------------------------
// 2.01.08 Tested with PCI-1405 card
// 16.04.09 IMAQ_CheckROIBoundaries now checks image boundaries correctly,
//          fixing bug which prevented CCD area from being expanded
// 27.07.10 External trigger supported added.
//          Camera now also outputs pulse on trigger at end of frame

interface

uses WinTypes,sysutils, classes, dialogs, mmsystem, math ;

const

//----------------------------------------------------------------------------
//  Attribute Keys
//----------------------------------------------------------------------------

  _IMG_BASE = $3FF60000 ;
  IMG_ATTR_INTERFACE_TYPE= _IMG_BASE + $0001; // id of board - see constants below
  IMG_ATTR_PIXDEPTH      = _IMG_BASE + $0002; // pixel depth in bits
  IMG_ATTR_COLOR         = _IMG_BASE + $0003; // true = supports color
  IMG_ATTR_HASRAM        = _IMG_BASE + $0004; // true = has on-board SRAM
  IMG_ATTR_RAMSIZE       = _IMG_BASE + $0005; // SRAM size
  IMG_ATTR_CHANNEL       = _IMG_BASE + $0006;
  IMG_ATTR_FRAME_FIELD   = _IMG_BASE + $0007; // supports frame and field
  IMG_ATTR_HORZ_RESOLUTION =              _IMG_BASE + $0009;
  IMG_ATTR_VERT_RESOLUTION =              _IMG_BASE + $000A;
  IMG_ATTR_LUT           = _IMG_BASE + $000B;
  IMG_ATTR_LINESCAN      = _IMG_BASE + $000C;
  IMG_ATTR_GAIN          = _IMG_BASE + $000D;
  IMG_ATTR_CHROMA_FILTER = _IMG_BASE + $000E;
  IMG_ATTR_WHITE_REF     = _IMG_BASE + $000F;
  IMG_ATTR_BLACK_REF     = _IMG_BASE + $0010;
  IMG_ATTR_DATALINES     = _IMG_BASE + $0011; // pass in uInt32 array of size up to 16 elements to swap incoming data lines (0,1,2...15; - must be 16 x uInt32 array
  IMG_ATTR_NUM_EXT_LINES = _IMG_BASE + $0012;
  IMG_ATTR_NUM_RTSI_LINES= _IMG_BASE + $0013;
  IMG_ATTR_NUM_RTSI_IN_USE = _IMG_BASE + $0014;
  IMG_ATTR_MEM_LOCKED    = _IMG_BASE + $0065;
  IMG_ATTR_BITSPERPIXEL  = _IMG_BASE + $0066;
  IMG_ATTR_BYTESPERPIXEL = _IMG_BASE + $0067;
  IMG_ATTR_ACQWINDOW_LEFT= _IMG_BASE + $0068;
  IMG_ATTR_ACQWINDOW_TOP = _IMG_BASE + $0069;
  IMG_ATTR_ACQWINDOW_WIDTH =              _IMG_BASE + $006A;
  IMG_ATTR_ACQWINDOW_HEIGHT =             _IMG_BASE + $006B;
  IMG_ATTR_LINE_COUNT    = _IMG_BASE + $0070;
  IMG_ATTR_FREE_BUFFERS  = _IMG_BASE + $0071;
  IMG_ATTR_HSCALE        = _IMG_BASE + $0072;
  IMG_ATTR_VSCALE        = _IMG_BASE + $0073;
  IMG_ATTR_ACQ_IN_PROGRESS             = _IMG_BASE + $0074;
  IMG_ATTR_START_FIELD   = _IMG_BASE + $0075;
  IMG_ATTR_FRAME_COUNT   = _IMG_BASE + $0076;
  IMG_ATTR_LAST_VALID_BUFFER =            _IMG_BASE + $0077;
  IMG_ATTR_ROWBYTES      = _IMG_BASE + $0078;
  IMG_ATTR_CALLBACK      = _IMG_BASE + $007B;
  IMG_ATTR_CURRENT_BUFLIST               = _IMG_BASE + $007C;
  IMG_ATTR_FRAMEWAIT_MSEC= _IMG_BASE + $007D;
  IMG_ATTR_TRIGGER_MODE  = _IMG_BASE + $007E;
  IMG_ATTR_INVERT        = _IMG_BASE + $0082;
  IMG_ATTR_XOFF_BUFFER   = _IMG_BASE + $0083;
  IMG_ATTR_YOFF_BUFFER   = _IMG_BASE + $0084;
  IMG_ATTR_NUM_BUFFERS   = _IMG_BASE + $0085;
  IMG_ATTR_LOST_FRAMES   = _IMG_BASE + $0088;
  IMG_ATTR_COLOR_WHITE_REF               = _IMG_BASE + $008F; // Color white reference
  IMG_ATTR_COLOR_BLACK_REF               = _IMG_BASE + $0090; // Color black reference
  IMG_ATTR_COLOR_CLAMP_START             = _IMG_BASE + $0091; // Color clamp start
  IMG_ATTR_COLOR_CLAMP_STOP              = _IMG_BASE + $0092; // Color clamp stop
  IMG_ATTR_COLOR_ZERO_START              = _IMG_BASE + $0093; // Color zero start
  IMG_ATTR_COLOR_ZERO_STOP               = _IMG_BASE + $0094; // Color zero stop
  IMG_ATTR_COLOR_AVG_COUNT               = _IMG_BASE + $0095; // Color averaging count
  IMG_ATTR_COLOR_SW_CHROMA_FILTER        = _IMG_BASE + $0096; // Color SW chroma filter
  IMG_ATTR_COLOR_NTSC_SETUP_ENABLE       = _IMG_BASE + $0097; // Color NTSC Setup enable
  IMG_ATTR_COLOR_NTSC_SETUP_VALUE        = _IMG_BASE + $0098; // Color NTSC Setup value
  IMG_ATTR_COLOR_BRIGHTNESS              = _IMG_BASE + $0099; // Color brightness
  IMG_ATTR_COLOR_CONTRAST= _IMG_BASE + $009A; // Color contrast
  IMG_ATTR_COLOR_SATURATION              = _IMG_BASE + $009B; // Color saturation
  IMG_ATTR_COLOR_TINT    = _IMG_BASE + $009C; // Color tint (chroma phase;
  IMG_ATTR_COLOR_SW_POST_GAIN            = _IMG_BASE + $009D; // Color SW post-gain
  IMG_ATTR_COLOR_BURST_START             = _IMG_BASE + $009E; // Color burst start
  IMG_ATTR_COLOR_BURST_STOP              = _IMG_BASE + $009F; // Color burst stop
  IMG_ATTR_COLOR_BLANK_START             = _IMG_BASE + $00A0; // Color blank start
  IMG_ATTR_COLOR_BLANK_STOP              = _IMG_BASE + $00A1; // Color blank stop
  IMG_ATTR_COLOR_IMAGE_X_SHIFT           = _IMG_BASE + $00A2; // Color acquisition left shift
  IMG_ATTR_COLOR_GAIN    = _IMG_BASE + $00A3; // Color HW pre-gain
  IMG_ATTR_COLOR_CLAMP_START_REF         = _IMG_BASE + $00A5; // Color clamp start reference
  IMG_ATTR_COLOR_CLAMP_STOP_REF          = _IMG_BASE + $00A6; // Color clamp stop reference
  IMG_ATTR_COLOR_ZERO_START_REF          = _IMG_BASE + $00A7; // Color zero start reference
  IMG_ATTR_COLOR_ZERO_STOP_REF           = _IMG_BASE + $00A8; // Color zero stop reference
  IMG_ATTR_COLOR_BURST_START_REF         = _IMG_BASE + $00A9; // Color burst start reference
  IMG_ATTR_COLOR_BURST_STOP_REF          = _IMG_BASE + $00AA; // Color burst stop reference
  IMG_ATTR_COLOR_BLANK_START_REF         = _IMG_BASE + $00AB; // Color blank start reference
  IMG_ATTR_COLOR_BLANK_STOP_REF          = _IMG_BASE + $00AC; // Color blank stop reference
  IMG_ATTR_COLOR_MODE    = _IMG_BASE + $00AD; // Color acquisition mode
  IMG_ATTR_COLOR_IMAGE_REP               = _IMG_BASE + $00AE; // Color Image representation
  IMG_ATTR_GENLOCK_SWITCH_CHAN           = _IMG_BASE + $00AF; // switch channel fast
  IMG_ATTR_CLAMP_START   = _IMG_BASE + $00B0; // clamp start
  IMG_ATTR_CLAMP_STOP    = _IMG_BASE + $00B1; // clamp stop
  IMG_ATTR_ZERO_START    = _IMG_BASE + $00B2; // zero start
  IMG_ATTR_ZERO_STOP     = _IMG_BASE + $00B3; // zero stop
  IMG_ATTR_COLOR_HUE_OFFS_ANGLE          = _IMG_BASE + $00B5; // Color hue offset angle
  IMG_ATTR_COLOR_IMAGE_X_SHIFT_REF       = _IMG_BASE + $00B6; // Color acquisition left shift reference
  IMG_ATTR_LAST_VALID_FRAME              = _IMG_BASE + $00BA; // returns the cummulative buffer index (frame#;
  IMG_ATTR_CLOCK_FREQ    = _IMG_BASE + $00BB; // returns the max clock freq of the board
  IMG_ATTR_BLACK_REF_VOLT= _IMG_BASE + $00BC; // defines the black reference in volts
  IMG_ATTR_WHITE_REF_VOLT= _IMG_BASE + $00BD; // defines the white reference in volts
  IMG_ATTR_COLOR_LOW_REF_VOLT            = _IMG_BASE + $00BE; // defines the color low reference in volts
  IMG_ATTR_COLOR_HIGH_REF_VOLT           = _IMG_BASE + $00BF;
  IMG_ATTR_GETSERIAL     = _IMG_BASE + $00C0; // get the serial number of the board
  IMG_ATTR_ROWPIXELS     = _IMG_BASE + $00C1;
  IMG_ATTR_ACQUIRE_FIELD = _IMG_BASE + $00C2;
  IMG_ATTR_PCLK_DETECT   = _IMG_BASE + $00C3;
  IMG_ATTR_VHA_MODE      = _IMG_BASE + $00C4; // Variable Height Acquisition mode
  IMG_ATTR_BIN_THRESHOLD_LOW             = _IMG_BASE + $00C5; // Binary threshold low
  IMG_ATTR_BIN_THRESHOLD_HIGH            = _IMG_BASE + $00C6; // Binary threshold hi
  IMG_ATTR_COLOR_LUMA_BANDWIDTH          = _IMG_BASE + $00C7; // selects different bandwidths for the luminance signal
  IMG_ATTR_COLOR_CHROMA_TRAP             = _IMG_BASE + $00C8; // enables and disables the chroma trap filter in the luma signal path
  IMG_ATTR_COLOR_LUMA_COMB               = _IMG_BASE + $00C9; // select the type of comb filter used in the luma path
  IMG_ATTR_COLOR_PEAKING_ENABLE          = _IMG_BASE + $00CA; // enable the peaking filter in the luma path
  IMG_ATTR_COLOR_PEAKING_LEVEL           = _IMG_BASE + $00CB;
  IMG_ATTR_COLOR_CHROMA_PROCESS          = _IMG_BASE + $00CC; // specifies the processing applied to the chroma signal
  IMG_ATTR_COLOR_CHROMA_BANDWIDTH        = _IMG_BASE + $00CD; // bandwidth of the chroma information of the image
  IMG_ATTR_COLOR_CHROMA_COMB             = _IMG_BASE + $00CE; // select the type of comb filter used in the chroma path
  IMG_ATTR_COLOR_CHROMA_PHASE            = _IMG_BASE + $00CF; // sets value of correction angle applied to the chroma vector.  Active only for NTSC cameras
  IMG_ATTR_COLOR_RGB_CORING_LEVEL        = _IMG_BASE + $00D0; // select RGB coring level
  IMG_ATTR_COLOR_HSL_CORING_LEVEL        = _IMG_BASE + $00D1; // select HSL coring level
  IMG_ATTR_COLOR_HUE_REPLACE_VALUE       = _IMG_BASE + $00D2; // hue value to replace if saturation value is less than HSL coring level
  IMG_ATTR_COLOR_GAIN_RED= _IMG_BASE + $00D3; // Red Gain
  IMG_ATTR_COLOR_GAIN_GREEN              = _IMG_BASE + $00D4; // Green Gian
  IMG_ATTR_COLOR_GAIN_BLUE               = _IMG_BASE + $00D5; // Blue Gain
  IMG_ATTR_CALIBRATION_DATE_LV           = _IMG_BASE + $00D6; // 0 if board is uncalibrated, else seconds since Jan 1 1904
  IMG_ATTR_CALIBRATION_DATE              = _IMG_BASE + $00D7; // 0 if board is uncalibrated, else seconds since Jan 1 1970
  IMG_ATTR_IMAGE_TYPE    = _IMG_BASE + $00D8; // return the IMAQ Vision image type for LabVIEW
  IMG_ATTR_DYNAMIC_RANGE = _IMG_BASE + $00D9; // the effective bits per pixel of the user's white-black level
  IMG_ATTR_ACQUIRE_TO_SYSTEM_MEMORY      = _IMG_BASE + $011B;
  IMG_ATTR_ONBOARD_HOLDING_BUFFER_PTR    = _IMG_BASE + $011C;
  IMG_ATTR_SYNCHRONICITY = _IMG_BASE + $011D;
  IMG_ATTR_LAST_ACQUIRED_BUFFER_NUM      = _IMG_BASE + $011E;
  IMG_ATTR_LAST_ACQUIRED_BUFFER_INDEX    = _IMG_BASE + $011F;
  IMG_ATTR_LAST_TRANSFERRED_BUFFER_NUM   = _IMG_BASE + $0120;
  IMG_ATTR_LAST_TRANSFERRED_BUFFER_INDEX = _IMG_BASE + $0121;
  IMG_ATTR_SERIAL_NUM_BYTES_RECEIVED     = _IMG_BASE + $012C; // # bytes currently in the internal serial read buffer
  IMG_ATTR_EXPOSURE_TIME_INTERNAL        = _IMG_BASE + $013C; // exposure time for 1454 (internal value - specified in 40MHz clks;
  IMG_ATTR_SERIAL_TERM_STRING            = _IMG_BASE + $0150; // The serial termination string
  IMG_ATTR_DETECT_VIDEO  = _IMG_BASE + $01A3; // Determines whether to detect a video signal prior to acquiring
  IMG_ATTR_ROI_LEFT      = _IMG_BASE + $01A4;
  IMG_ATTR_ROI_TOP       = _IMG_BASE + $01A5;
  IMG_ATTR_ROI_WIDTH     = _IMG_BASE + $01A6;
  IMG_ATTR_ROI_HEIGHT    = _IMG_BASE + $01A7;
  IMG_ATTR_NUM_ISO_IN_LINES              = _IMG_BASE + $01A8; // The number of iso in lines the device supports
  IMG_ATTR_NUM_ISO_OUT_LINES             = _IMG_BASE + $01A9; // The number of iso out lines the device supports
  IMG_ATTR_NUM_POST_TRIGGER_BUFFERS      = _IMG_BASE + $01AA; // The number of buffers that hardware should continue acquire after sensing a stop trigger before it finally does stop
  IMG_ATTR_EXT_TRIG_LINE_FILTER          = _IMG_BASE + $01AB; // Whether to use filtering on the TTL trigger lines
  IMG_ATTR_RTSI_LINE_FILTER              = _IMG_BASE + $01AC; // Whether to use filtering on the RTSI trigger lines
  IMG_ATTR_NUM_PORTS     = _IMG_BASE + $01AD; // Returns the number of ports that this device supports.
  IMG_ATTR_CURRENT_PORT_NUM              = _IMG_BASE + $01AE; // Returns the port number that the given interface is using.
  IMG_ATTR_ENCODER_PHASE_A_POLARITY      = _IMG_BASE + $01AF; // The polarity of the phase A encoder input
  IMG_ATTR_ENCODER_PHASE_B_POLARITY      = _IMG_BASE + $01B0; // The polarity of the phase B encoder input
  IMG_ATTR_ENCODER_FILTER= _IMG_BASE + $01B1; // Specifies whether to use filtering on the encoder input
  IMG_ATTR_ENCODER_DIVIDE_FACTOR         = _IMG_BASE + $01B2; // The divide factor for the encoder scaler
  IMG_ATTR_ENCODER_POSITION              = _IMG_BASE + $01B3; // Returns the current value of the absolute encoder position as a uInt64



//============================================================================
//  Attribute Defines
//============================================================================

//----------------------------------------------------------------------------
//  LUT
//----------------------------------------------------------------------------
  IMG_LUT_NORMAL =                     0 ;
  IMG_LUT_INVERSE =                    1 ;
  IMG_LUT_LOG =                        2 ;
  IMG_LUT_INVERSE_LOG =                3 ;
  IMG_LUT_BINARY =                     4 ;
  IMG_LUT_INVERSE_BINARY =             5 ;
  IMG_LUT_USER =                       6 ;


  IMG_LUT_TYPE_DEFAULT       = $00000010 ;
  IMG_LUT_TYPE_RED           = $00000020 ;
  IMG_LUT_TYPE_GREEN         = $00000040 ;
  IMG_LUT_TYPE_BLUE          = $00000080 ;
  IMG_LUT_TYPE_TAP0          = $00000100 ;
  IMG_LUT_TYPE_TAP1          = $00000200 ;
  IMG_LUT_TYPE_TAP2          = $00000400 ;
  IMG_LUT_TYPE_TAP3          = $00000800 ;


//------------------------------------------------------------------------------
//  Frame or Field Mode
//------------------------------------------------------------------------------
  IMG_FIELD_MODE =                     0 ;
  IMG_FRAME_MODE =                     1 ;


//----------------------------------------------------------------------------
//  Chrominance Filters
//----------------------------------------------------------------------------
 IMG_FILTER_NONE =                     0 ;
 IMG_FILTER_NTSC =                     1 ;
 IMG_FILTER_PAL =                      2 ;


//------------------------------------------------------------------------------
//  Possible start field values
//------------------------------------------------------------------------------
  IMG_FIELD_EVEN =                     0 ;
  IMG_FIELD_ODD =                      1 ;


//----------------------------------------------------------------------------
//  Scaling
//----------------------------------------------------------------------------
  IMG_SCALE_NONE = 1 ;
  IMG_SCALE_DIV2 = 2 ;
  IMG_SCALE_DIV4 = 4 ;
  IMG_SCALE_DIV8 = 8  ;


//----------------------------------------------------------------------------
//  Triggering Mode
//----------------------------------------------------------------------------
  IMG_TRIGMODE_NONE =                  0 ;
  IMG_TRIGMODE_NOREPEAT =              1 ;
  IMG_TRIGMODE_REPEAT =                2 ;


//----------------------------------------------------------------------------
//  Field Acquisition Selection
//----------------------------------------------------------------------------
  IMG_ACQUIRE_EVEN                  =  0 ;
  IMG_ACQUIRE_ODD                   =  1 ;
  IMG_ACQUIRE_ALL                   =  2 ;
  IMG_ACQUIRE_ALTERNATING           =  3 ;


//----------------------------------------------------------------------------
//  Luma bandwidth
//----------------------------------------------------------------------------
  IMG_COLOR_LUMA_BANDWIDTH_FULL     =  0 ; // All filters including decimation filter disabled. Default for CCIR or RS-170
  IMG_COLOR_LUMA_BANDWIDTH_HIGH     =  1 ; // Highest available bandwidth with decimation filter enabled. Default for PAL or NTSC
  IMG_COLOR_LUMA_BANDWIDTH_MEDIUM   =  2 ; // Decimation filtered enabled, medium bandwidth.
  IMG_COLOR_LUMA_BANDWIDTH_LOW      =  3 ; // Decimation filtered enabled, lowest bandwidth.


//----------------------------------------------------------------------------
//  Comb filters
//----------------------------------------------------------------------------
  IMG_COLOR_COMB_OFF                =  0 ; // Comb filtered disabled (default in S-Video/Y/C mode)
  IMG_COLOR_COMB_1LINE              =  1 ; // Comb filtered using 1 delayed line
  IMG_COLOR_COMB_2LINES             =  2 ; // Comb filtered using 2 delayed lines


//----------------------------------------------------------------------------
//  Chroma processing
//----------------------------------------------------------------------------
  IMG_COLOR_CHROMA_PROCESS_ALWAYS_OFF =0 ; // should be used when a monochrome camera is used. Default for RS-170 or CCIR
  IMG_COLOR_CHROMA_PROCESS_ALWAYS_ON  =1 ; // should be used when a color camera is used.  Default for NTSC or PAL
  IMG_COLOR_CHROMA_PROCESS_AUTODETECT =2 ; // can be used if the camera type is unknown.


//----------------------------------------------------------------------------
//  Chroma bandwidth
//----------------------------------------------------------------------------
  IMG_COLOR_CHROMA_BANDWIDTH_HIGH   =  0 ; // Highest bandwidth (default)
  IMG_COLOR_CHROMA_BANDWIDTH_LOW    =  1 ; // Lowest bandwidth


//----------------------------------------------------------------------------
//  RGB Coring
//----------------------------------------------------------------------------
  IMG_COLOR_RGB_CORING_LEVEL_NOCORING =0 ; // The coring function is disabled
  IMG_COLOR_RGB_CORING_LEVEL_C1       =1 ; // Coring activated for saturation equal or below 1 lsb
  IMG_COLOR_RGB_CORING_LEVEL_C3       =2 ; // Coring activated for saturation equal or below 3 lsb
  IMG_COLOR_RGB_CORING_LEVEL_C7       =3 ; // Coring activated for saturation equal or below 7 lsb


//----------------------------------------------------------------------------
//  Video Signal Types
//----------------------------------------------------------------------------
  IMG_VIDEO_NTSC                    =  0 ;
  IMG_VIDEO_PAL                     =  1 ;


//----------------------------------------------------------------------------
//  imgSessionExamineBuffer constants
//----------------------------------------------------------------------------
  IMG_LAST_BUFFER                   =  $FFFFFFFE ;
  IMG_OLDEST_BUFFER                 =  $FFFFFFFD ;
  IMG_CURRENT_BUFFER                =  $FFFFFFFC ;


//----------------------------------------------------------------------------
//  Buffer Element Specifiers
//----------------------------------------------------------------------------
  IMG_BUFF_ADDRESS                    =(_IMG_BASE + $007E);
  IMG_BUFF_COMMAND                    =(_IMG_BASE + $007F);
  IMG_BUFF_SKIPCOUNT                  =(_IMG_BASE + $0080);
  IMG_BUFF_SIZE                       =(_IMG_BASE + $0082);
  IMG_BUFF_TRIGGER                    =(_IMG_BASE + $0083);
  IMG_BUFF_NUMBUFS                    =(_IMG_BASE + $00B0);
  IMG_BUFF_CHANNEL                    =(_IMG_BASE + $00Bc);
  IMG_BUFF_ACTUALHEIGHT               =(_IMG_BASE + $0400);


//----------------------------------------------------------------------------
//  Possible Buffer Command Values
//----------------------------------------------------------------------------
  IMG_CMD_NEXT                        =$01;  // Proceed to next list entry
  IMG_CMD_LOOP                        =$02;  // Loop back to start of buffer list and continue processing - RING ACQUISITION
  IMG_CMD_PASS                        =$04;  // Do nothing here
  IMG_CMD_STOP                        =$08;  // Stop
  IMG_CMD_INVALID                     =$10;  // Reserved for internal use


//----------------------------------------------------------------------------
//  Possible Triggered Acquisition Actions
//----------------------------------------------------------------------------
  IMG_TRIG_ACTION_NONE                =0; // no trigger action
  IMG_TRIG_ACTION_CAPTURE             =1; // one trigger required to start the acquisition once
  IMG_TRIG_ACTION_BUFLIST             =2; // one trigger required to start the buflist each time
  IMG_TRIG_ACTION_BUFFER              =3; // one trigger required for each buffer
  IMG_TRIG_ACTION_STOP                =4; // one trigger is used to stop the acquisition


//----------------------------------------------------------------------------
// Old RTSI mapping constants (imgSessionSetRTSImap)
//----------------------------------------------------------------------------
  IMG_TRIG_MAP_RTSI0_DISABLED         =$0000000f;
  IMG_TRIG_MAP_RTSI0_EXT0             =$00000001;
  IMG_TRIG_MAP_RTSI0_EXT1             =$00000002;
  IMG_TRIG_MAP_RTSI0_EXT2             =$00000003;
  IMG_TRIG_MAP_RTSI0_EXT3             =$00000004;
  IMG_TRIG_MAP_RTSI0_EXT4             =$00000005;
  IMG_TRIG_MAP_RTSI0_EXT5             =$00000006;
  IMG_TRIG_MAP_RTSI0_EXT6             =$00000007;

  IMG_TRIG_MAP_RTSI1_DISABLED         =$000000f0;
  IMG_TRIG_MAP_RTSI1_EXT0             =$00000010;
  IMG_TRIG_MAP_RTSI1_EXT1             =$00000020;
  IMG_TRIG_MAP_RTSI1_EXT2             =$00000030;
  IMG_TRIG_MAP_RTSI1_EXT3             =$00000040;
  IMG_TRIG_MAP_RTSI1_EXT4             =$00000050;
  IMG_TRIG_MAP_RTSI1_EXT5             =$00000060;
  IMG_TRIG_MAP_RTSI1_EXT6             =$00000070;

  IMG_TRIG_MAP_RTSI2_DISABLED         =$00000f00;
  IMG_TRIG_MAP_RTSI2_EXT0             =$00000100;
  IMG_TRIG_MAP_RTSI2_EXT1             =$00000200;
  IMG_TRIG_MAP_RTSI2_EXT2             =$00000300;
  IMG_TRIG_MAP_RTSI2_EXT3             =$00000400;
  IMG_TRIG_MAP_RTSI2_EXT4             =$00000500;
  IMG_TRIG_MAP_RTSI2_EXT5             =$00000600;
  IMG_TRIG_MAP_RTSI2_EXT6             =$00000700;

  IMG_TRIG_MAP_RTSI3_DISABLED         =$0000f000;
  IMG_TRIG_MAP_RTSI3_EXT0             =$00001000;
  IMG_TRIG_MAP_RTSI3_EXT1             =$00002000;
  IMG_TRIG_MAP_RTSI3_EXT2             =$00003000;
  IMG_TRIG_MAP_RTSI3_EXT3             =$00004000;
  IMG_TRIG_MAP_RTSI3_EXT4             =$00005000;
  IMG_TRIG_MAP_RTSI3_EXT5             =$00006000;
  IMG_TRIG_MAP_RTSI3_EXT6             =$00007000;


//----------------------------------------------------------------------------
//  Frame timeout values
//----------------------------------------------------------------------------
  IMG_FRAMETIME_STANDARD              =100;      //    100 milliseconds
  IMG_FRAMETIME_1SECOND               =1000;     //   1000 milliseconds -  1 second
  IMG_FRAMETIME_2SECONDS              =2000;     //   2000 milliseconds -  2 seconds
  IMG_FRAMETIME_5SECONDS              =5000;     //   5000 milliseconds -  5 seconds
  IMG_FRAMETIME_10SECONDS             =10000;    //  10000 milliseconds - 10 seconds
  IMG_FRAMETIME_1MINUTE               =60000;    //  60000 milliseconds -  1 minute
  IMG_FRAMETIME_2MINUTES              =120000;   // 120000 milliseconds -  2 minutes
  IMG_FRAMETIME_5MINUTES              =300000;   // 300000 milliseconds -  5 minutes
  IMG_FRAMETIME_10MINUTES             =600000;   // 600000 milliseconds - 10 minutes


//----------------------------------------------------------------------------
//  Gain values
//----------------------------------------------------------------------------
  IMG_GAIN_0DB                       = 0 ;
  IMG_GAIN_3DB                       = 1 ;
  IMG_GAIN_6DB                       = 2 ;


//----------------------------------------------------------------------------
//  Gain values for the 1409
//----------------------------------------------------------------------------
  IMG_GAIN_2_00                      = 0 ;
  IMG_GAIN_1_75                      = 1 ;
  IMG_GAIN_1_50                      = 2 ;
  IMG_GAIN_1_00                      = 3 ;


//----------------------------------------------------------------------------
//  Analog bandwidth
//----------------------------------------------------------------------------
  IMG_BANDWIDTH_FULL                 = 0 ;
  IMG_BANDWIDTH_9MHZ                 = 1 ;


//----------------------------------------------------------------------------
//  White and black reference ranges
//----------------------------------------------------------------------------
  IMG_WHITE_REFERENCE_MIN            = 0 ;
  IMG_WHITE_REFERENCE_MAX            = 63 ;
  IMG_BLACK_REFERENCE_MIN            = 0 ;
  IMG_BLACK_REFERENCE_MAX            = 63 ;


//----------------------------------------------------------------------------
//  Possible Trigger Polarities
//----------------------------------------------------------------------------
  IMG_TRIG_POLAR_ACTIVEH             =0;
  IMG_TRIG_POLAR_ACTIVEL             =1;


//----------------------------------------------------------------------------
//  The Trigger Lines
//  Important!!!  If you change the number of lines or add a different
//  kind of line, be sure to update IsExtTrigLine(), IsRTSILine(), or add
//  a new IsXXXLine() function, as appropriate.
//----------------------------------------------------------------------------
  IMG_EXT_TRIG0                       =0;
  IMG_EXT_TRIG1                       =1;
  IMG_EXT_TRIG2                       =2;
  IMG_EXT_TRIG3                       =3;
  IMG_EXT_RTSI0                       =4;
  IMG_EXT_RTSI1                       =5;
  IMG_EXT_RTSI2                       =6;
  IMG_EXT_RTSI3                       =7;
  IMG_EXT_RTSI4                       =12;
  IMG_EXT_RTSI5                       =13;
  IMG_EXT_RTSI6                       =14;
  IMG_TRIG_ROUTE_DISABLED             =$FFFFFFFF;


//----------------------------------------------------------------------------
//  Internal Signals
//  These are the signals that you can wait on or use to trigger the start
//  of pulse generation.
//----------------------------------------------------------------------------
  IMG_AQ_DONE                         =8;     // wait for the entire acquisition to complete
  IMG_FRAME_START                     =9;     // wait for the frame to start
  IMG_FRAME_DONE                      =10;    // wait for the frame to complete
  IMG_BUF_COMPLETE                    =11;    // wait for the buffer to complete
  IMG_AQ_IN_PROGRESS                  =15;
  IMG_IMMEDIATE                       =16;
  IMG_FIXED_FREQUENCY                 =17;    // used in imgSessionLineTrigSrouce (linescan)


//----------------------------------------------------------------------------
//  IMAQ Vision Compatible Image Types.
//----------------------------------------------------------------------------
  IMG_IMAGE_U8                        =0;  // Unsigned 8-bit image
  IMG_IMAGE_I16                       =1;  // Signed 16-bit image
  IMG_IMAGE_RGB32                     =4;  // 32-bit RGB image
  IMG_IMAGE_HSL32                     =5;  // 32-bit HSL image
  IMG_IMAGE_RGB64                     =6;  // 64-bit RGB image


//----------------------------------------------------------------------------
//  Color representations
//----------------------------------------------------------------------------
  IMG_COLOR_REP_RGB32 =  0  ; // 32 bits RGB
  IMG_COLOR_REP_RED8 =   1  ; // 8 bits Red
  IMG_COLOR_REP_GREEN8 = 2  ; // 8 bits Green
  IMG_COLOR_REP_BLUE8 =  3  ; // 8 bits Blue
  IMG_COLOR_REP_LUM8 =   4  ; // 8 bits Light
  IMG_COLOR_REP_HUE8 =   5  ; // 8 bits Hue
  IMG_COLOR_REP_SAT8 =   6  ; // 8 bits Saturation
  IMG_COLOR_REP_INT8 =   7  ; // 8 bits Intensity
  IMG_COLOR_REP_LUM16 =  8  ; // 16 bits Light
  IMG_COLOR_REP_HUE16 =  9  ; // 16 bits Hue
  IMG_COLOR_REP_SAT16 =  10 ; // 16 bits Saturation
  IMG_COLOR_REP_INT16 =  11 ; // 16 bits Intensity
  IMG_COLOR_REP_RGB48 =  12 ; // 48 bits RGB
  IMG_COLOR_REP_RGB24 =  13 ; // 24 bits RGB
  IMG_COLOR_REP_RGB16 =  14 ; // 16 bits RGB (x555)
  IMG_COLOR_REP_HSL32 =  15 ; // 32 bits HSL
  IMG_COLOR_REP_HSI32 =  16 ; // 32 bits HSI
  IMG_COLOR_REP_NONE =   17 ; // No color information. Use bit-depth
  IMG_COLOR_REP_MONO10 = 18 ; // 10 bit Monochrome


//----------------------------------------------------------------------------
//  Specifies the size of each array element in the interface names array
//----------------------------------------------------------------------------
  INTERFACE_NAME_SIZE              =256;


//----------------------------------------------------------------------------
//  Pulse timebases
//----------------------------------------------------------------------------
  PULSE_TIMEBASE_PIXELCLK             =$00000001;
  PULSE_TIMEBASE_50MHZ                =$00000002;
  PULSE_TIMEBASE_100KHZ               =$00000003;
  PULSE_TIMEBASE_SCALED_ENCODER       =$00000004;


//----------------------------------------------------------------------------
//  Pulse mode
//----------------------------------------------------------------------------
  PULSE_MODE_TRAIN                    =$00000001;
  PULSE_MODE_SINGLE                   =$00000002;
  PULSE_MODE_SINGLE_REARM             =$00000003;


//----------------------------------------------------------------------------
//  Pulse polarities
//----------------------------------------------------------------------------
  IMG_PULSE_POLAR_ACTIVEH             =0;
  IMG_PULSE_POLAR_ACTIVEL             =1;


//----------------------------------------------------------------------------
//  Trigger drive
//----------------------------------------------------------------------------
  IMG_TRIG_DRIVE_DISABLED             =0;
  IMG_TRIG_DRIVE_AQ_IN_PROGRESS       =1;
  IMG_TRIG_DRIVE_AQ_DONE              =2;
  IMG_TRIG_DRIVE_PIXEL_CLK            =3;
  IMG_TRIG_DRIVE_UNASSERTED           =4;
  IMG_TRIG_DRIVE_ASSERTED             =5;
  IMG_TRIG_DRIVE_HSYNC                =6;
  IMG_TRIG_DRIVE_VSYNC                =7;
  IMG_TRIG_DRIVE_FRAME_START          =8;
  IMG_TRIG_DRIVE_FRAME_DONE           =9;
  IMG_TRIG_DRIVE_SCALED_ENCODER       =10;


//----------------------------------------------------------------------------
//  imgPlot Flags
//----------------------------------------------------------------------------
  IMGPLOT_MONO_8                      =$00000000;
  IMGPLOT_INVERT                      =$00000001;
  IMGPLOT_COLOR_RGB24                 =$00000002;
  IMGPLOT_COLOR_RGB32                 =$00000004;
  IMGPLOT_MONO_10                     =$00000008;
  IMGPLOT_MONO_12                     =$00000010;
  IMGPLOT_MONO_14                     =$00000020;
  IMGPLOT_MONO_16                     =$00000040;
  IMGPLOT_MONO_32                     =$00000080;
  IMGPLOT_AUTO                        =$00000100;


//----------------------------------------------------------------------------
//  Stillcolor modes.  OBSOLETE.
//----------------------------------------------------------------------------
  IMG_COLOR_MODE_DISABLED             =0;        // Color mode disabled
  IMG_COLOR_MODE_RGB                  =1;        // Color mode RGB StillColor
  IMG_COLOR_MODE_COMPOSITE_STLC       =2;        // Color mode Composite StillColor

//----------------------------------------------------------------------------
//  Signal states
//----------------------------------------------------------------------------

   IMG_SIGNAL_STATE_RISING  = 0;
   IMG_SIGNAL_STATE_FALLING = 1;
   IMG_SIGNAL_STATE_HIGH    = 2;
   IMG_SIGNAL_STATE_LOW     = 3;
   IMG_SIGNAL_STATE_HI_Z    = 4;


//----------------------------------------------------------------------------
//  ROI Fit Modes
//----------------------------------------------------------------------------
    IMG_ROI_FIT_LARGER = 0 ;
    IMG_ROI_FIT_SMALLER = 1 ;

//----------------------------------------------------------------------------
//  Signal Types
//----------------------------------------------------------------------------
    IMG_SIGNAL_NONE           = $FFFFFFFF;
    IMG_SIGNAL_EXTERNAL       = 0;
    IMG_SIGNAL_RTSI           = 1;
    IMG_SIGNAL_ISO_IN         = 2;
    IMG_SIGNAL_ISO_OUT        = 3;
    IMG_SIGNAL_STATUS         = 4;
    IMG_SIGNAL_SCALED_ENCODER = 5;


//----------------------------------------------------------------------------
//  Buffer location specifier.
//----------------------------------------------------------------------------
 IMG_HOST_FRAME                    =0;
 IMG_DEVICE_FRAME                  =1;


//----------------------------------------------------------------------------
//  Bayer decoding pattern.
//----------------------------------------------------------------------------
  IMG_BAYER_PATTERN_GBGB_RGRG      =0;
  IMG_BAYER_PATTERN_GRGR_BGBG      =1;
  IMG_BAYER_PATTERN_BGBG_GRGR      =2;
  IMG_BAYER_PATTERN_RGRG_GBGB      =3;


//============================================================================
//  Error Codes
//============================================================================

 _IMG_ERR                                =$BFF60000 ;
 IMG_ERR_GOOD                            =0 ;                   // no error
//============================================================================
//  Warnings
//============================================================================
  IMG_WRN_BCAM                           = _IMG_BASE + $0001; // corrupt camera file detected
  IMG_WRN_CONF                           = _IMG_BASE + $0002; // change requires reconfigure to take effect
  IMG_WRN_ILCK                           = _IMG_BASE + $0003; // interface still locked
  IMG_WRN_BLKG                           = _IMG_BASE + $0004; // STC: unstable blanking reference
  IMG_WRN_BRST                           = _IMG_BASE + $0005; // STC: bad quality colorburst
  IMG_WRN_OATTR                          = _IMG_BASE + $0006; // old attribute used
  IMG_WRN_WLOR                           = _IMG_BASE + $0007; // white level out of range
  IMG_WRN_IATTR                          = _IMG_BASE + $0008; // invalid attribute in current state
  IMG_WRN_LATEST                         = _IMG_BASE + $000A;

//----------------------------------------------------------------------------
//  Old errors (from 2.X)
//----------------------------------------------------------------------------
  IMG_ERR_NCAP                           = _IMG_ERR + $0001; // function not implemented
  IMG_ERR_OVRN                           = _IMG_ERR + $0002; // too many interfaces open
  IMG_ERR_EMEM                           = _IMG_ERR + $0003; // could not allocate memory in user mode (calloc failed)
  IMG_ERR_OSER                           = _IMG_ERR + $0004; // operating system error occurred
  IMG_ERR_PAR1                           = _IMG_ERR + $0005; // Error with parameter 1
  IMG_ERR_PAR2                           = _IMG_ERR + $0006; // Error with parameter 2
  IMG_ERR_PAR3                           = _IMG_ERR + $0007; // Error with parameter 3
  IMG_ERR_PAR4                           = _IMG_ERR + $0008; // Error with parameter 4
  IMG_ERR_PAR5                           = _IMG_ERR + $0009; // Error with parameter 5
  IMG_ERR_PAR6                           = _IMG_ERR + $000A; // Error with parameter 6
  IMG_ERR_PAR7                           = _IMG_ERR + $000B; // Error with parameter 7
  IMG_ERR_MXBF                           = _IMG_ERR + $000C; // too many buffers already allocated
  IMG_ERR_DLLE                           = _IMG_ERR + $000D; // DLL internal error - bad logic state
  IMG_ERR_BSIZ                           = _IMG_ERR + $000E; // buffer size used is too small for minimum acquisition frame
  IMG_ERR_MXBI                           = _IMG_ERR + $000F; // exhausted buffer id's
  IMG_ERR_ELCK                           = _IMG_ERR + $0010; // not enough physical memory - the system could not allocate page locked memory
  IMG_ERR_DISE                           = _IMG_ERR + $0011; // error releasing the image buffer
  IMG_ERR_BBUF                           = _IMG_ERR + $0012; // bad buffer pointer in list
  IMG_ERR_NLCK                           = _IMG_ERR + $0013; // buffer list is not locked
  IMG_ERR_NCAM                           = _IMG_ERR + $0014; // no camera defined for this channel
  IMG_ERR_BINT                           = _IMG_ERR + $0015; // bad interface
  IMG_ERR_BROW                           = _IMG_ERR + $0016; // rowbytes is less than region of interest
  IMG_ERR_BROI                           = _IMG_ERR + $0017; // bad region of interest; check width, heigh, rowpixels, and scaling
  IMG_ERR_BCMF                           = _IMG_ERR + $0018; // bad camera file (check syntax)
  IMG_ERR_NVBL                           = _IMG_ERR + $0019; // not successful because of hardware limitations
  IMG_ERR_NCFG                           = _IMG_ERR + $001A; // invalid action - no buffers configured for session
  IMG_ERR_BBLF                           = _IMG_ERR + $001B; // buffer list does not contain a valid final command
  IMG_ERR_BBLE                           = _IMG_ERR + $001C; // buffer list does contains an invalid command
  IMG_ERR_BBLB                           = _IMG_ERR + $001D; // a buffer list buffer is null
  IMG_ERR_NAIP                           = _IMG_ERR + $001E; // no acquisition in progress
  IMG_ERR_VLCK                           = _IMG_ERR + $001F; // can't get video lock
  IMG_ERR_BDMA                           = _IMG_ERR + $0020; // bad DMA transfer
  IMG_ERR_AIOP                           = _IMG_ERR + $0021; // can't perform request - acquisition in progress
  IMG_ERR_TIMO                           = _IMG_ERR + $0022; // wait timed out - acquisition not complete
  IMG_ERR_NBUF                           = _IMG_ERR + $0023; // no buffers available - too early in acquisition
  IMG_ERR_ZBUF                           = _IMG_ERR + $0024; // zero buffer size - no bytes filled
  IMG_ERR_HLPR                           = _IMG_ERR + $0025; // bad parameter to low level - check attributes and high level arguments
  IMG_ERR_BTRG                           = _IMG_ERR + $0026; // trigger loopback problem - can't drive trigger with action enabled
  IMG_ERR_NINF                           = _IMG_ERR + $0027; // no interface found
  IMG_ERR_NDLL                           = _IMG_ERR + $0028; // unable to load DLL
  IMG_ERR_NFNC                           = _IMG_ERR + $0029; // unable to find API function in DLL
  IMG_ERR_NOSR                           = _IMG_ERR + $002A; // unable to allocate system resources (CVI only)
  IMG_ERR_BTAC                           = _IMG_ERR + $002B; // no trigger action - acquisition will time out
  IMG_ERR_FIFO                           = _IMG_ERR + $002C; // fifo overflow caused acquisition to halt
  IMG_ERR_MLCK                           = _IMG_ERR + $002D; // memory lock error - the system could not page lock the buffer(s)
  IMG_ERR_ILCK                           = _IMG_ERR + $002E; // interface locked
  IMG_ERR_NEPK                           = _IMG_ERR + $002F; // no external pixel clock
  IMG_ERR_SCLM                           = _IMG_ERR + $0030; // field scaling mode not supported
  IMG_ERR_SCC1                           = _IMG_ERR + $0031; // still color rgb, channel not set to 1
  IMG_ERR_SMALLALLOC                     = _IMG_ERR + $0032; // Error during small buffer allocation
  IMG_ERR_ALLOC                          = _IMG_ERR + $0033; // Error during large buffer allocation
  IMG_ERR_BADCAMTYPE                     = _IMG_ERR + $0034; // Bad camera type - (Not a NTSC or PAL)
  IMG_ERR_BADPIXTYPE                     = _IMG_ERR + $0035; // Camera not supported (not 8 bits)
  IMG_ERR_BADCAMPARAM                    = _IMG_ERR + $0036; // Bad camera parameter from the configuration file
  IMG_ERR_PALKEYDTCT                     = _IMG_ERR + $0037; // PAL key detection error
  IMG_ERR_BFRQ                           = _IMG_ERR + $0038; // Bad frequency values
  IMG_ERR_BITP                           = _IMG_ERR + $0039; // Bad interface type
  IMG_ERR_HWNC                           = _IMG_ERR + $003A; // Hardware not capable of supporting this
  IMG_ERR_SERIAL                         = _IMG_ERR + $003B; // serial port error
  IMG_ERR_MXPI                           = _IMG_ERR + $003C; // exhausted pulse id's
  IMG_ERR_BPID                           = _IMG_ERR + $003D; // bad pulse id
  IMG_ERR_NEVR                           = _IMG_ERR + $003E; // should never get this error - bad code!
  IMG_ERR_SERIAL_TIMO                    = _IMG_ERR + $003F; // serial transmit/receive timeout
  IMG_ERR_PG_TOO_MANY                    = _IMG_ERR + $0040; // too many PG transitions defined
  IMG_ERR_PG_BAD_TRANS                   = _IMG_ERR + $0041; // bad PG transition time
  IMG_ERR_PLNS                           = _IMG_ERR + $0042; // pulse not started error
  IMG_ERR_BPMD                           = _IMG_ERR + $0043; // bad pulse mode
  IMG_ERR_NSAT                           = _IMG_ERR + $0044; // non settable attribute
  IMG_ERR_HYBRID                         = _IMG_ERR + $0045; // can't mix onboard and system memory buffers
  IMG_ERR_BADFILFMT                      = _IMG_ERR + $0046; // the pixel depth is not supported by this file format
  IMG_ERR_BADFILEXT                      = _IMG_ERR + $0047; // This file extension is not supported
  IMG_ERR_NRTSI                          = _IMG_ERR + $0048; // exhausted RTSI map registers
  IMG_ERR_MXTRG                          = _IMG_ERR + $0049; // exhausted trigger resources
  IMG_ERR_MXRC                           = _IMG_ERR + $004A; // exhausted resources (general)
  IMG_ERR_OOR                            = _IMG_ERR + $004B; // parameter out of range
  IMG_ERR_NPROG                          = _IMG_ERR + $004C; // FPGA not programmed
  IMG_ERR_NEOM                           = _IMG_ERR + $004D; // not enough onboard memory to perform operation
  IMG_ERR_BDTYPE                         = _IMG_ERR + $004E; // bad display type -- buffer cannot be displayed with imgPlot
  IMG_ERR_THRDACCDEN                     = _IMG_ERR + $004F; // thread denied access to function
  IMG_ERR_BADFILWRT                      = _IMG_ERR + $0050; // Could not write the file
  IMG_ERR_AEXM                           = _IMG_ERR + $0051; // Already called ExamineBuffer once.  Call ReleaseBuffer.


//----------------------------------------------------------------------------
//  New Error codes (3.0)
//----------------------------------------------------------------------------
 IMG_ERR_FIRST_ERROR = IMG_ERR_NCAP ;
  IMG_ERR_NOT_SUPPORTED                      = _IMG_ERR + $0001; // function not implemented
  IMG_ERR_SYSTEM_MEMORY_FULL                 = _IMG_ERR + $0003; // could not allocate memory in user mode (calloc failed)
  IMG_ERR_BUFFER_SIZE_TOO_SMALL              = _IMG_ERR + $000E; // buffer size used is too small for minimum acquisition frame
  IMG_ERR_BUFFER_LIST_NOT_LOCKED             = _IMG_ERR + $0013; // buffer list is not locked
  IMG_ERR_BAD_INTERFACE_FILE                 = _IMG_ERR + $0015; // bad interface
  IMG_ERR_BAD_USER_RECT                      = _IMG_ERR + $0017; // bad region of interest; check width, heigh, rowpixels, and scaling
  IMG_ERR_BAD_CAMERA_FILE                    = _IMG_ERR + $0018; // bad camera file (check syntax)
  IMG_ERR_NO_BUFFERS_CONFIGURED              = _IMG_ERR + $001A; // invalid action - no buffers configured for session
  IMG_ERR_BAD_BUFFER_LIST_FINAL_COMMAND      = _IMG_ERR + $001B; // buffer list does not contain a valid final command
  IMG_ERR_BAD_BUFFER_LIST_COMMAND            = _IMG_ERR + $001C; // buffer list does contains an invalid command
  IMG_ERR_BAD_BUFFER_POINTER                 = _IMG_ERR + $001D; // a buffer list buffer is null
  IMG_ERR_BOARD_NOT_RUNNING                  = _IMG_ERR + $001E; // no acquisition in progress
  IMG_ERR_VIDEO_LOCK                         = _IMG_ERR + $001F; // can't get video lock
  IMG_ERR_BOARD_RUNNING                      = _IMG_ERR + $0021; // can't perform request - acquisition in progress
  IMG_ERR_TIMEOUT                            = _IMG_ERR + $0022; // wait timed out - acquisition not complete
  IMG_ERR_ZERO_BUFFER_SIZE                   = _IMG_ERR + $0024; // zero buffer size - no bytes filled
  IMG_ERR_NO_INTERFACE_FOUND                 = _IMG_ERR + $0027; // no interface found
  IMG_ERR_FIFO_OVERFLOW                      = _IMG_ERR + $002C; // fifo overflow caused acquisition to halt
  IMG_ERR_MEMORY_PAGE_LOCK_FAULT             = _IMG_ERR + $002D; // memory lock error - the system could not page lock the buffer(s)
  IMG_ERR_BAD_CLOCK_FREQUENCY                = _IMG_ERR + $0038; // Bad frequency values
  IMG_ERR_BAD_CAMERA_TYPE                    = _IMG_ERR + $0034; // Bad camera type - (Not a NTSC or PAL)
  IMG_ERR_HARDWARE_NOT_CAPABLE               = _IMG_ERR + $003A; // Hardware not capable of supporting this
  IMG_ERR_ATTRIBUTE_NOT_SETTABLE             = _IMG_ERR + $0044; // non settable attribute
  IMG_ERR_ONBOARD_MEMORY_FULL                = _IMG_ERR + $004D; // not enough onboard memory to perform operation
  IMG_ERR_BUFFER_NOT_RELEASED                = _IMG_ERR + $0051; // Already called ExamineBuffer once.  Call ReleaseBuffer.
  IMG_ERR_BAD_LUT_TYPE                       = _IMG_ERR + $0052; // Invalid LUT type
  IMG_ERR_ATTRIBUTE_NOT_READABLE             = _IMG_ERR + $0053; // non readable attribute
  IMG_ERR_BOARD_NOT_SUPPORTED                = _IMG_ERR + $0054; // This version of the driver doesn't support the board.
  IMG_ERR_BAD_FRAME_FIELD                    = _IMG_ERR + $0055; // The value for frame/field was invalid.
  IMG_ERR_INVALID_ATTRIBUTE                  = _IMG_ERR + $0056; // The requested attribute is invalid.
  IMG_ERR_BAD_LINE_MAP                       = _IMG_ERR + $0057; // The line map is invalid
  IMG_ERR_BAD_CHANNEL                        = _IMG_ERR + $0059; // The requested channel is invalid.
  IMG_ERR_BAD_CHROMA_FILTER                  = _IMG_ERR + $005A; // The value for the anti-chrominance filter is invalid.
  IMG_ERR_BAD_SCALE                          = _IMG_ERR + $005B; // The value for scaling is invalid.
  IMG_ERR_BAD_TRIGGER_MODE                   = _IMG_ERR + $005D; // The value for trigger mode is invalid.
  IMG_ERR_BAD_CLAMP_START                    = _IMG_ERR + $005E; // The value for clamp start is invalid.
  IMG_ERR_BAD_CLAMP_STOP                     = _IMG_ERR + $005F; // The value for clamp stop is invalid.
  IMG_ERR_BAD_BRIGHTNESS                     = _IMG_ERR + $0060; // The brightness level is out of range
  IMG_ERR_BAD_CONTRAST                       = _IMG_ERR + $0061; // The constrast  level is out of range
  IMG_ERR_BAD_SATURATION                     = _IMG_ERR + $0062; // The saturation level is out of range
  IMG_ERR_BAD_TINT                           = _IMG_ERR + $0063; // The tint level is out of range
  IMG_ERR_BAD_HUE_OFF_ANGLE                  = _IMG_ERR + $0064; // The hue offset angle is out of range.
  IMG_ERR_BAD_ACQUIRE_FIELD                  = _IMG_ERR + $0065; // The value for acquire field is invalid.
  IMG_ERR_BAD_LUMA_BANDWIDTH                 = _IMG_ERR + $0066; // The value for luma bandwidth is invalid.
  IMG_ERR_BAD_LUMA_COMB                      = _IMG_ERR + $0067; // The value for luma comb is invalid.
  IMG_ERR_BAD_CHROMA_PROCESS                 = _IMG_ERR + $0068; // The value for chroma processing is invalid.
  IMG_ERR_BAD_CHROMA_BANDWIDTH               = _IMG_ERR + $0069; // The value for chroma bandwidth is invalid.
  IMG_ERR_BAD_CHROMA_COMB                    = _IMG_ERR + $006A; // The value for chroma comb is invalid.
  IMG_ERR_BAD_RGB_CORING                     = _IMG_ERR + $006B; // The value for RGB coring is invalid.
  IMG_ERR_BAD_HUE_REPLACE_VALUE              = _IMG_ERR + $006C; // The value for HSL hue replacement is out of range.
  IMG_ERR_BAD_RED_GAIN                       = _IMG_ERR + $006D; // The value for red gain is out of range.
  IMG_ERR_BAD_GREEN_GAIN                     = _IMG_ERR + $006E; // The value for green gain is out of range.
  IMG_ERR_BAD_BLUE_GAIN                      = _IMG_ERR + $006F; // The value for blue gain is out of range.
  IMG_ERR_BAD_START_FIELD                    = _IMG_ERR + $0070; // Invalid start field
  IMG_ERR_BAD_TAP_DIRECTION                  = _IMG_ERR + $0071; // Invalid tap scan direction
  IMG_ERR_BAD_MAX_IMAGE_RECT                 = _IMG_ERR + $0072; // Invalid maximum image rect
  IMG_ERR_BAD_TAP_TYPE                       = _IMG_ERR + $0073; // Invalid tap configuration type
  IMG_ERR_BAD_SYNC_RECT                      = _IMG_ERR + $0074; // Invalid sync rect
  IMG_ERR_BAD_ACQWINDOW_RECT                 = _IMG_ERR + $0075; // Invalid acquisition window
  IMG_ERR_BAD_HSL_CORING                     = _IMG_ERR + $0076; // The value for HSL coring is out of range.
  IMG_ERR_BAD_TAP_0_VALID_RECT               = _IMG_ERR + $0077; // Invalid tap 0 valid rect
  IMG_ERR_BAD_TAP_1_VALID_RECT               = _IMG_ERR + $0078; // Invalid tap 1 valid rect
  IMG_ERR_BAD_TAP_2_VALID_RECT               = _IMG_ERR + $0079; // Invalid tap 2 valid rect
  IMG_ERR_BAD_TAP_3_VALID_RECT               = _IMG_ERR + $007A; // Invalid tap 3 valid rect
  IMG_ERR_BAD_TAP_RECT                       = _IMG_ERR + $007B; // Invalid tap rect
  IMG_ERR_BAD_NUM_TAPS                       = _IMG_ERR + $007C; // Invalid number of taps
  IMG_ERR_BAD_TAP_NUM                        = _IMG_ERR + $007D; // Invalid tap number
  IMG_ERR_BAD_QUAD_NUM                       = _IMG_ERR + $007E; // Invalid Scarab quadrant number
  IMG_ERR_BAD_NUM_DATA_LINES                 = _IMG_ERR + $007F; // Invalid number of requested data lines
  IMG_ERR_BAD_BITS_PER_COMPONENT             = _IMG_ERR + $0080; // The value for bits per component is invalid.
  IMG_ERR_BAD_NUM_COMPONENTS                 = _IMG_ERR + $0081; // The value for number of components is invalid.
  IMG_ERR_BAD_BIN_THRESHOLD_LOW              = _IMG_ERR + $0082; // The value for the lower binary threshold is out of range.
  IMG_ERR_BAD_BIN_THRESHOLD_HIGH             = _IMG_ERR + $0083; // The value for the upper binary threshold is out of range.
  IMG_ERR_BAD_BLACK_REF_VOLT                 = _IMG_ERR + $0084; // The value for the black reference voltage is out of range.
  IMG_ERR_BAD_WHITE_REF_VOLT                 = _IMG_ERR + $0085; // The value for the white reference voltage is out of range.
  IMG_ERR_BAD_FREQ_STD                       = _IMG_ERR + $0086; // The value for the 6431 frequency standard is out of range.
  IMG_ERR_BAD_HDELAY                         = _IMG_ERR + $0087; // The value for HDELAY is out of range.
  IMG_ERR_BAD_LOCK_SPEED                     = _IMG_ERR + $0088; // Invalid lock speed.
  IMG_ERR_BAD_BUFFER_LIST                    = _IMG_ERR + $0089; // Invalid buffer list
  IMG_ERR_BOARD_NOT_INITIALIZED              = _IMG_ERR + $008A; // An attempt was made to access the board before it was initialized.
  IMG_ERR_BAD_PCLK_SOURCE                    = _IMG_ERR + $008B; // Invalid pixel clock source
  IMG_ERR_BAD_VIDEO_LOCK_CHANNEL             = _IMG_ERR + $008C; // Invalid video lock source
  IMG_ERR_BAD_LOCK_SEL                       = _IMG_ERR + $008D; // Invalid locking mode
  IMG_ERR_BAD_BAUD_RATE                      = _IMG_ERR + $008E; // Invalid baud rate for the UART
  IMG_ERR_BAD_STOP_BITS                      = _IMG_ERR + $008F; // The number of stop bits for the UART is out of range.
  IMG_ERR_BAD_DATA_BITS                      = _IMG_ERR + $0090; // The number of data bits for the UART is out of range.
  IMG_ERR_BAD_PARITY                         = _IMG_ERR + $0091; // Invalid parity setting for the UART
  IMG_ERR_TERM_STRING_NOT_FOUND              = _IMG_ERR + $0092; // Couldn't find the termination string in a serial read
  IMG_ERR_SERIAL_READ_TIMEOUT                = _IMG_ERR + $0093; // Exceeded the user specified timeout for a serial read
  IMG_ERR_SERIAL_WRITE_TIMEOUT               = _IMG_ERR + $0094; // Exceeded the user specified timeout for a serial write
  IMG_ERR_BAD_SYNCHRONICITY                  = _IMG_ERR + $0095; // Invalid setting for whether the acquisition is synchronous.
  IMG_ERR_BAD_INTERLACING_CONFIG             = _IMG_ERR + $0096; // Bad interlacing configuration
  IMG_ERR_BAD_CHIP_CODE                      = _IMG_ERR + $0098; // Bad chip code.  Couldn't find a matching chip.
  IMG_ERR_LUT_NOT_PRESENT                    = _IMG_ERR + $0099; // The LUT chip doesn't exist
  IMG_ERR_DSPFILTER_NOT_PRESENT              = _IMG_ERR + $009A; // The DSP filter doesn't exist
  IMG_ERR_DEVICE_NOT_FOUND                   = _IMG_ERR + $009B; // The IMAQ device was not found
  IMG_ERR_ONBOARD_MEM_CONFIG                 = _IMG_ERR + $009C; // There was a problem while configuring onboard memory
  IMG_ERR_BAD_POINTER                        = _IMG_ERR + $009D; // The pointer is bad.  It might be NULL when it shouldn't be NULL or non-NULL when it should be NULL.
  IMG_ERR_BAD_BUFFER_LIST_INDEX              = _IMG_ERR + $009E; // The given buffer list index is invalid
  IMG_ERR_INVALID_BUFFER_ATTRIBUTE           = _IMG_ERR + $009F; // The given buffer attribute is invalid
  IMG_ERR_INVALID_BUFFER_PTR                 = _IMG_ERR + $00A0; // The given buffer wan't created by the NI-IMAQ driver
  IMG_ERR_BUFFER_LIST_ALREADY_LOCKED         = _IMG_ERR + $00A1; // A buffer list is already locked down in memory for this device
  IMG_ERR_BAD_DEVICE_TYPE                    = _IMG_ERR + $00A2; // The type of IMAQ device is invalid
  IMG_ERR_BAD_BAR_SIZE                       = _IMG_ERR + $00A3; // The size of one or more BAR windows is incorrect
  IMG_ERR_NO_VALID_COUNTER_RECT              = _IMG_ERR + $00A5; // Couldn't settle on a valid counter rect
  IMG_ERR_ACQ_STOPPED                        = _IMG_ERR + $00A6; // The wait terminated because the acquisition stopped.
  IMG_ERR_BAD_TRIGGER_ACTION                 = _IMG_ERR + $00A7; // The trigger action is invalid.
  IMG_ERR_BAD_TRIGGER_POLARITY               = _IMG_ERR + $00A8; // The trigger polarity is invalid.
  IMG_ERR_BAD_TRIGGER_NUMBER                 = _IMG_ERR + $00A9; // The requested trigger line is invalid.
  IMG_ERR_BUFFER_NOT_AVAILABLE               = _IMG_ERR + $00AA; // The requested buffer has been overwritten and is no longer available.
  IMG_ERR_BAD_PULSE_ID                       = _IMG_ERR + $00AC; // The given pulse id is invalid
  IMG_ERR_BAD_PULSE_TIMEBASE                 = _IMG_ERR + $00AD; // The given timebase is invalid.
  IMG_ERR_BAD_PULSE_GATE                     = _IMG_ERR + $00AE; // The given gate signal for the pulse is invalid.
  IMG_ERR_BAD_PULSE_GATE_POLARITY            = _IMG_ERR + $00AF; // The polarity of the gate signal is invalid.
  IMG_ERR_BAD_PULSE_OUTPUT                   = _IMG_ERR + $00B0; // The given output signal for the pulse is invalid.
  IMG_ERR_BAD_PULSE_OUTPUT_POLARITY          = _IMG_ERR + $00B1; // The polarity of the output signal is invalid.
  IMG_ERR_BAD_PULSE_MODE                     = _IMG_ERR + $00B2; // The given pulse mode is invalid.
  IMG_ERR_NOT_ENOUGH_RESOURCES               = _IMG_ERR + $00B3; // There are not enough resources to complete the requested operation.
  IMG_ERR_INVALID_RESOURCE                   = _IMG_ERR + $00B4; // The requested resource is invalid
  IMG_ERR_BAD_FVAL_ENABLE                    = _IMG_ERR + $00B5; // Invalid enable mode for FVAL
  IMG_ERR_BAD_WRITE_ENABLE_MODE              = _IMG_ERR + $00B6; // Invalid combination of enables to write to DRAM
  IMG_ERR_COMPONENT_MISMATCH                 = _IMG_ERR + $00B7; // Internal Error: The installed components of the driver are incompatible.  Reinstall the driver.
  IMG_ERR_FPGA_PROGRAMMING_FAILED            = _IMG_ERR + $00B8; // Internal Error: Downloading the program to an FPGA didn't work.
  IMG_ERR_CONTROL_FPGA_FAILED                = _IMG_ERR + $00B9; // Internal Error: The Control FPGA didn't initialize properly
  IMG_ERR_CHIP_NOT_READABLE                  = _IMG_ERR + $00BA; // Internal Error: Attempt to read a write-only chip.
  IMG_ERR_CHIP_NOT_WRITABLE                  = _IMG_ERR + $00BB; // Internal Error: Attempt to write a read-only chip.
  IMG_ERR_I2C_BUS_FAILED                     = _IMG_ERR + $00BC; // Internal Error: The I2C bus didn't respond correctly.
  IMG_ERR_DEVICE_IN_USE                      = _IMG_ERR + $00BD; // The requested IMAQ device is already open
  IMG_ERR_BAD_TAP_DATALANES                  = _IMG_ERR + $00BE; // The requested data lanes on a particular tap are invalid
  IMG_ERR_BAD_VIDEO_GAIN                     = _IMG_ERR + $00BF; // Bad video gain value
  IMG_ERR_VHA_MODE_NOT_ALLOWED               = _IMG_ERR + $00C0; // VHA mode not allowed, based upon the current configuration
  IMG_ERR_BAD_TRACKING_SPEED                 = _IMG_ERR + $00C1; // Bad color video tracking speed
  IMG_ERR_BAD_COLOR_INPUT_SELECT             = _IMG_ERR + $00C2; // Invalid input select for the 1411
  IMG_ERR_BAD_HAV_OFFSET                     = _IMG_ERR + $00C3; // Invalid HAV offset
  IMG_ERR_BAD_HS1_OFFSET                     = _IMG_ERR + $00C4; // Invalid HS1 offset
  IMG_ERR_BAD_HS2_OFFSET                     = _IMG_ERR + $00C5; // Invalid HS2 offset
  IMG_ERR_BAD_IF_CHROMA                      = _IMG_ERR + $00C6; // Invalid chroma IF compensation
  IMG_ERR_BAD_COLOR_OUTPUT_FORMAT            = _IMG_ERR + $00C7; // Invalid format for color output
  IMG_ERR_BAD_SAMSUNG_SCHCMP                 = _IMG_ERR + $00C8; // Invalid phase constant
  IMG_ERR_BAD_SAMSUNG_CDLY                   = _IMG_ERR + $00C9; // Invalid chroma path group delay
  IMG_ERR_BAD_SECAM_DETECT                   = _IMG_ERR + $00CA; // Invalid method for secam detection
  IMG_ERR_BAD_FSC_DETECT                     = _IMG_ERR + $00CB; // Invalid method for fsc detection
  IMG_ERR_BAD_SAMSUNG_CFTC                   = _IMG_ERR + $00CC; // Invalid chroma frequency tracking time constant
  IMG_ERR_BAD_SAMSUNG_CGTC                   = _IMG_ERR + $00CD; // Invalid chroma gain tracking time constant
  IMG_ERR_BAD_SAMSUNG_SAMPLE_RATE            = _IMG_ERR + $00CE; // Invalid pixel sampling rate
  IMG_ERR_BAD_SAMSUNG_VSYNC_EDGE             = _IMG_ERR + $00CF; // Invalid edge for vsync to follow
  IMG_ERR_SAMSUNG_LUMA_GAIN_CTRL             = _IMG_ERR + $00D0; // Invalid method to control the luma gain
  IMG_ERR_BAD_SET_COMB_COEF                  = _IMG_ERR + $00D1; // Invalid way to set the chroma comb coefficients
  IMG_ERR_SAMSUNG_CHROMA_TRACK               = _IMG_ERR + $00D2; // Invalid method to track chroma
  IMG_ERR_SAMSUNG_DROP_LINES                 = _IMG_ERR + $00D3; // Invalid algorithm to drop video lines
  IMG_ERR_VHA_OPTIMIZATION_NOT_ALLOWED       = _IMG_ERR + $00D4; // VHA optimization not allowed, based upon the current configuration
  IMG_ERR_BAD_PG_TRANSITION                  = _IMG_ERR + $00D5; // A pattern generation transition is invalid
  IMG_ERR_TOO_MANY_PG_TRANSITIONS            = _IMG_ERR + $00D6; // User is attempting to generate more pattern generation transitions than we support
  IMG_ERR_BAD_CL_DATA_CONFIG                 = _IMG_ERR + $00D7; // Invalid data configuration for the Camera Link chips
  IMG_ERR_BAD_OCCURRENCE                     = _IMG_ERR + $00D8; // The given occurrence is not valid.
  IMG_ERR_BAD_PG_MODE                        = _IMG_ERR + $00D9; // Invalid pattern generation mode
  IMG_ERR_BAD_PG_SOURCE                      = _IMG_ERR + $00DA; // Invalid pattern generation source signal
  IMG_ERR_BAD_PG_GATE                        = _IMG_ERR + $00DB; // Invalid pattern generation gate signal
  IMG_ERR_BAD_PG_GATE_POLARITY               = _IMG_ERR + $00DC; // Invalid pattern generation gate polarity
  IMG_ERR_BAD_PG_WAVEFORM_INITIAL_STATE      = _IMG_ERR + $00DD; // Invalid pattern generation waveform initial state
  IMG_ERR_INVALID_CAMERA_ATTRIBUTE           = _IMG_ERR + $00DE; // The requested camera attribute is invalid
  IMG_ERR_BOARD_CLOSED                       = _IMG_ERR + $00DF; // The request failed because the board was closed
  IMG_ERR_FILE_NOT_FOUND                     = _IMG_ERR + $00E0; // The requested file could not be found
  IMG_ERR_BAD_1409_DSP_FILE                  = _IMG_ERR + $00E1; // The dspfilter1409.bin file was corrupt or missing
  IMG_ERR_BAD_SCARABXCV200_32_FILE           = _IMG_ERR + $00E2; // The scarabXCV200.bin file was corrupt or missing
  IMG_ERR_BAD_SCARABXCV200_16_FILE           = _IMG_ERR + $00E3; // The scarab16bit.bin file was corrupt or missing
  IMG_ERR_BAD_CAMERA_LINK_FILE               = _IMG_ERR + $00E4; // The data1428.bin file was corrupt or missing
  IMG_ERR_BAD_1411_CSC_FILE                  = _IMG_ERR + $00E5; // The colorspace.bin file was corrupt or missing
  IMG_ERR_BAD_ERROR_CODE                     = _IMG_ERR + $00E6; // The error code passed into imgShowError was unknown.
  IMG_ERR_DRIVER_TOO_OLD                     = _IMG_ERR + $00E7; // The board requires a newer version of the driver.
  IMG_ERR_INSTALLATION_CORRUPT               = _IMG_ERR + $00E8; // A driver piece is not present (.dll, registry entry, etc).
  IMG_ERR_NO_ONBOARD_MEMORY                  = _IMG_ERR + $00E9; // There is no onboard memory, thus an onboard acquisition cannot be performed.
  IMG_ERR_BAD_BAYER_PATTERN                  = _IMG_ERR + $00EA; // The Bayer pattern specified is invalid.
  IMG_ERR_CANNOT_INITIALIZE_BOARD            = _IMG_ERR + $00EB; // The board is not operating correctly and cannot be initialized.
  IMG_ERR_CALIBRATION_DATA_CORRUPT           = _IMG_ERR + $00EC; // The stored calibration data has been corrupted.
  IMG_ERR_DRIVER_FAULT                       = _IMG_ERR + $00ED; // The driver attempted to perform an illegal operation.
  IMG_ERR_ADDRESS_OUT_OF_RANGE               = _IMG_ERR + $00EE; // An attempt was made to access a chip beyond it's addressable range.
  IMG_ERR_ONBOARD_ACQUISITION                = _IMG_ERR + $00EF; // The requested operation is not valid for onboard acquisitions.
  IMG_ERR_NOT_AN_ONBOARD_ACQUISITION         = _IMG_ERR + $00F0; // The requested operation is only valid for onboard acquisitions.
  IMG_ERR_BOARD_ALREADY_INITIALIZED          = _IMG_ERR + $00F1; // An attempt was made to call an initialization function on a board that was already initialized.
  IMG_ERR_NO_SERIAL_PORT                     = _IMG_ERR + $00F2; // Tried to use the serial port on a board that doesn't have one
  IMG_ERR_BAD_VENABLE_GATING_MODE            = _IMG_ERR + $00F3; // The VENABLE gating mode selection is invalid
  IMG_ERR_BAD_1407_LUT_FILE                  = _IMG_ERR + $00F4; // The lutfpga1407.bin was corrupt or missing
  IMG_ERR_BAD_SYNC_DETECT_LEVEL              = _IMG_ERR + $00F5; // The detect sync level is out of range for the 1407 rev A-D
  IMG_ERR_BAD_1405_GAIN_FILE                 = _IMG_ERR + $00F6; // The gain1405.bin file was corrupt or missing
  IMG_ERR_CLAMP_DAC_NOT_PRESENT              = _IMG_ERR + $00F7; // The device doesn't have a clamp DAC
  IMG_ERR_GAIN_DAC_NOT_PRESENT               = _IMG_ERR + $00F8; // The device doesn't have a gain DAC
  IMG_ERR_REF_DAC_NOT_PRESENT                = _IMG_ERR + $00F9; // The device doesn't have a reference DAC
  IMG_ERR_BAD_SCARABXC2S200_FILE             = _IMG_ERR + $00FA; // The scarab16bit.bin file was corrupt or missing
  IMG_ERR_BAD_LUT_GAIN                       = _IMG_ERR + $00FB; // The desired LUT gain is invalid
  IMG_ERR_BAD_MAX_BUF_LIST_ITER              = _IMG_ERR + $00FC; // The desired maximum number of buffer list iterations to store on onboard memory is invalid
  IMG_ERR_BAD_PG_LINE_NUM                    = _IMG_ERR + $00FD; // The desired pattern generation line number is invalid
  IMG_ERR_BAD_BITS_PER_PIXEL                 = _IMG_ERR + $00FE; // The desired number of bits per pixel is invalid
  IMG_ERR_TRIGGER_ALARM                      = _IMG_ERR + $00FF; // Triggers are coming in too fast to handle them and maintain system responsiveness.  Check for glitches on your trigger line.
  IMG_ERR_BAD_SCARABXC2S200_03052009_FILE    = _IMG_ERR + $0100; // The scarabXC2S200_03052009.bin file was corrupt or missing
  IMG_ERR_LUT_CONFIG                         = _IMG_ERR + $0101; // There was an error configuring the LUT
  IMG_ERR_CONTROL_FPGA_REQUIRES_NEWER_DRIVER = _IMG_ERR + $0102; // The Control FPGA requires a newer version of the driver than is currently installed.  This can happen when field upgrading the Control FPGA.
  IMG_ERR_CONTROL_FPGA_PROGRAMMING_FAILED    = _IMG_ERR + $0103; // The FlashCPLD reported that the Control FPGA did not program successfully.
  IMG_ERR_BAD_TRIGGER_SIGNAL_LEVEL           = _IMG_ERR + $0104; // A trigger signalling level is invalid.
  IMG_ERR_CAMERA_FILE_REQUIRES_NEWER_DRIVER  = _IMG_ERR + $0105; // The camera file requires a newer version of the driver
  IMG_ERR_DUPLICATED_BUFFER                  = _IMG_ERR + $0106; // The same image was put in the buffer list twice.  LabVIEW only.
  IMG_ERR_NO_ERROR                           = _IMG_ERR + $0107; // No error.  Never returned by the driver.
  IMG_ERR_INTERFACE_NOT_SUPPORTED            = _IMG_ERR + $0108; // The camera file does not support the board that is trying to open it.
  IMG_ERR_BAD_PCLK_POLARITY                  = _IMG_ERR + $0109; // The requested polarity for the pixel clock is invalid.
  IMG_ERR_BAD_ENABLE_POLARITY                = _IMG_ERR + $010A; // The requested polarity for the enable line is invalid.
  IMG_ERR_BAD_PCLK_SIGNAL_LEVEL              = _IMG_ERR + $010B; // The requested signaling level for the pixel clock is invalid.
  IMG_ERR_BAD_ENABLE_SIGNAL_LEVEL            = _IMG_ERR + $010C; // The requested signaling level for the enable line is invalid.
  IMG_ERR_BAD_DATA_SIGNAL_LEVEL              = _IMG_ERR + $010D; // The requested signaling level for the data lines is invalid.
  IMG_ERR_BAD_CTRL_SIGNAL_LEVEL              = _IMG_ERR + $010E; // The requested signaling level for the control lines is invalid.
  IMG_ERR_BAD_WINDOW_HANDLE                  = _IMG_ERR + $010F; // The given window handle is invalid
  IMG_ERR_CANNOT_WRITE_FILE                  = _IMG_ERR + $0110; // Cannot open the requested file for writing.
  IMG_ERR_CANNOT_READ_FILE                   = _IMG_ERR + $0111; // Cannot open the requested file for reading.
  IMG_ERR_BAD_SIGNAL_TYPE                    = _IMG_ERR + $0112; // The signal passed into imgSessionWaitSignal(Async) was invalid.
  IMG_ERR_BAD_SAMPLES_PER_LINE               = _IMG_ERR + $0113; // Invalid samples per line
  IMG_ERR_BAD_SAMPLES_PER_LINE_REF           = _IMG_ERR + $0114; // Invalid samples per line reference
  IMG_ERR_USE_EXTERNAL_HSYNC                 = _IMG_ERR + $0115; // The current video signal requires an external HSYNC to be used to lock the signal.
  IMG_ERR_BUFFER_NOT_ALIGNED                 = _IMG_ERR + $0116; // An image buffer is not properly aligned.  It must be aligned to a DWORD boundary.
  IMG_ERR_ROWPIXELS_TOO_SMALL                = _IMG_ERR + $0117; // The number of pixels per row is less than the region of interest width.
  IMG_ERR_ROWPIXELS_NOT_ALIGNED              = _IMG_ERR + $0118; // The number of pixels per row is not properly aligned.  The total number of bytes per row must be aligned to a DWORD boundary.
  IMG_ERR_ROI_WIDTH_NOT_ALIGNED              = _IMG_ERR + $0119; // The ROI width is not properly aligned.  The total number of bytes bounded by ROI width must be aligned to a DWORD boundary.
  IMG_ERR_LINESCAN_NOT_ALLOWED               = _IMG_ERR + $011A; // Linescan mode is not allowed for this tap configuration.
  IMG_ERR_INTERFACE_FILE_REQUIRES_NEWER_DRIVER = _IMG_ERR + $011B; // The camera file requires a newer version of the driver
  IMG_ERR_BAD_SKIP_COUNT                     = _IMG_ERR + $011C; // The requested skip count value is out of range.
  IMG_ERR_BAD_NUM_X_ZONES                    = _IMG_ERR + $011D; // The number of X-zones is invalid
  IMG_ERR_BAD_NUM_Y_ZONES                    = _IMG_ERR + $011E; // The number of Y-zones is invalid
  IMG_ERR_BAD_NUM_TAPS_PER_X_ZONE            = _IMG_ERR + $011F; // The number of taps per X-zone is invalid
  IMG_ERR_BAD_NUM_TAPS_PER_Y_ZONE            = _IMG_ERR + $0120; // The number of taps per Y-zone is invalid
  IMG_ERR_BAD_TEST_IMAGE_TYPE                = _IMG_ERR + $0121; // The requested test image type is invalid
  IMG_ERR_CANNOT_ACQUIRE_FROM_CAMERA         = _IMG_ERR + $0122; // This firmware is not capable of acquiring from a camera
  IMG_ERR_BAD_CTRL_LINE_SOURCE               = _IMG_ERR + $0123; // The selected source for one of the camera control lines is bad
  IMG_ERR_BAD_PIXEL_EXTRACTOR                = _IMG_ERR + $0124; // The desired pixel extractor is invalid
  IMG_ERR_BAD_NUM_TIME_SLOTS                 = _IMG_ERR + $0125; // The desired number of time slots is invalid
  IMG_ERR_BAD_PLL_VCO_DIVIDER                = _IMG_ERR + $0126; // The VCO divide by number was invalide for the ICS1523
  IMG_ERR_CRITICAL_TEMP                      = _IMG_ERR + $0127; // The device temperature exceeded the critical temperature threshold
  IMG_ERR_BAD_DPA_OFFSET                     = _IMG_ERR + $0128; // The requested dynamic phase aligner offset is invalid
  IMG_ERR_BAD_NUM_POST_TRIGGER_BUFFERS       = _IMG_ERR + $0129; // The requested number of post trigger buffers is invalid
  IMG_ERR_BAD_DVAL_MODE                      = _IMG_ERR + $012A; // The requested DVAL mode is invalid
  IMG_ERR_BAD_TRIG_GEN_REARM_SOURCE          = _IMG_ERR + $012B; // The requested trig gen rearm source signal is invalid
  IMG_ERR_BAD_ASM_GATE_SOURCE                = _IMG_ERR + $012C; // The requested ASM gate signal is invalid
  IMG_ERR_TOO_MANY_BUFFERS                   = _IMG_ERR + $012D; // The requested number of buffer list buffers is not supported by this IMAQ device
  IMG_ERR_BAD_TAP_4_VALID_RECT               = _IMG_ERR + $012E; // Invalid tap 4 valid rect
  IMG_ERR_BAD_TAP_5_VALID_RECT               = _IMG_ERR + $012F; // Invalid tap 5 valid rect
  IMG_ERR_BAD_TAP_6_VALID_RECT               = _IMG_ERR + $0130; // Invalid tap 6 valid rect
  IMG_ERR_BAD_TAP_7_VALID_RECT               = _IMG_ERR + $0131; // Invalid tap 7 valid rect
  IMG_ERR_FRONT_END_BANDWIDTH_EXCEEDED       = _IMG_ERR + $0132; // The camera is providing image data faster than the IMAQ device can receive it.
  IMG_ERR_BAD_PORT_NUMBER                    = _IMG_ERR + $0133; // The requested port number does not exist.
  IMG_ERR_PORT_CONFIG_CONFLICT               = _IMG_ERR + $0134; // The requested port cannot be cannot be configured due to a conflict with another port that is currently opened.
  IMG_ERR_BITSTREAM_INCOMPATIBLE             = _IMG_ERR + $0135; // The requested bitstream is not compatible with the IMAQ device.
  IMG_ERR_SERIAL_PORT_IN_USE                 = _IMG_ERR + $0136; // The requested serial port is currently in use and is not accessible.
  IMG_ERR_BAD_ENCODER_DIVIDE_FACTOR          = _IMG_ERR + $0137; // The requested encoder divide factor is invalid.
  IMG_ERR_ENCODER_NOT_SUPPORTED              = _IMG_ERR + $0138; // Encoder support is not present for this IMAQ device.  Please verify that this device is capable of handling encoder signals and that phase A and B are connected.
  IMG_ERR_BAD_ENCODER_POLARITY               = _IMG_ERR + $0139; // The requested encoder phase signal polarity is invalid.
  IMG_ERR_BAD_ENCODER_FILTER                 = _IMG_ERR + $013A; // The requested encoder filter setting is invalid.
  IMG_ERR_ENCODER_POSITION_NOT_SUPPORTED     = _IMG_ERR + $013B; // This IMAQ device does not support reading the absolute encoder position.
  IMG_ERR_IMAGE_IN_USE                       = _IMG_ERR + $013C; // The IMAQ image appears to be in use.  Please name the images differently to avoid this situation.
  IMG_ERR_BAD_SCARABXL4000_FILE              = _IMG_ERR + $013D; // The scarab.bin file is corrupt or missing
  IMG_ERR_BAD_CAMERA_ATTRIBUTE_VALUE         = _IMG_ERR + $013E; // The requested camera attribute value is invalid.  For numeric camera attributes, please ensure that the value is properly aligned and within the allowable range.
  IMG_ERR_BAD_PULSE_WIDTH                    = _IMG_ERR + $013F; // The requested pulse width is invalid.
  IMG_ERR_FPGA_FILE_NOT_FOUND                = _IMG_ERR + $0140; // The requested FPGA bitstream file could not be found.
  IMG_ERR_FPGA_FILE_CORRUPT                  = _IMG_ERR + $0141; // The requested FPGA bitstream file is corrupt.
  IMG_ERR_BAD_PULSE_DELAY                    = _IMG_ERR + $0142; // The requested pulse delay is invalid.
 IMG_ERR_LAST_ERROR           = _IMG_ERR + $142 ;

//============================================================================
//  Old 1408 revision numbers
//============================================================================
  PCIIMAQ1408_REVA                    = $00000000 ;
  PCIIMAQ1408_REVB                    = $00000001 ;
  PCIIMAQ1408_REVC                    = $00000002 ;
  PCIIMAQ1408_REVF                    = $00000003 ;
  PCIIMAQ1408_REVX                    = $00000004 ;


//============================================================================
//  PCI device IDs
//============================================================================
  IMAQ_PCI_1405                       = $70CA1093 ;
  IMAQ_PXI_1405                       = $70CE1093 ;
  IMAQ_PCI_1407                       = $B0411093 ;
  IMAQ_PXI_1407                       = $B0511093 ;
  IMAQ_PCI_1408                       = $B0011093 ;
  IMAQ_PXI_1408                       = $B0111093 ;
  IMAQ_PCI_1409                       = $B0B11093 ;
  IMAQ_PXI_1409                       = $B0C11093 ;
  IMAQ_PCI_1410                       = $71871093 ;
  IMAQ_PCI_1411                       = $B0611093 ;
  IMAQ_PXI_1411                       = $B0911093 ;
  IMAQ_PCI_1413                       = $B0311093 ;
  IMAQ_PXI_1413                       = $B0321093 ;
  IMAQ_PCI_1422                       = $B0711093 ;
  IMAQ_PXI_1422                       = $B0811093 ;
  IMAQ_PCI_1423                       = $70281093 ;
  IMAQ_PXI_1423                       = $70291093 ;
  IMAQ_PCI_1424                       = $B0211093 ;
  IMAQ_PXI_1424                       = $B0221093 ;
  IMAQ_PCI_1426                       = $715D1093 ;
  IMAQ_PCI_1428                       = $B0E11093 ;
  IMAQ_PXI_1428                       = $707C1093 ;
  IMAQ_PCIX_1429                      = $71041093 ;
  IMAQ_PCIe_1429                      = $71051093 ;

type

 TIMAQSession = record
    SessionID : Integer ;
    SessionOpen : Boolean ;
    InterfaceID : Integer ;
    InterfaceOpen : Boolean ;
    AcquisitionInProgress : Boolean ;
    NumFrameBuffers : Integer ;
    FrameBufPointer : Pointer ;
    NumBytesPerFrame : Integer ;
    BufferList: Array[0..255] of Pointer ;
    BufferIndex : Integer ;
    end ;

//============================================================================
//  Functions
//============================================================================
 TimgInterfaceOpen = function(
                     interface_name : PChar ;
                     var InterfaceID : Integer
                     ) : Integer ; stdcall ;
 TimgSessionOpen = function(
                   InterfaceID : Integer;
                   var SessionID : Integer
                   ) : Integer ; stdcall ;
 TimgClose = function(
             ID : Integer ;
             freeResources : Integer
             ) : Integer ; stdcall ;
 TimgSnap = function(
            SessionID : Integer;
            var bufAddr : Pointer
            ) : Integer ; stdcall ;
 TimgSnapArea = function(
                SessionID : Integer;
                var bufAddr : Pointer ;
                top : Integer ;
                left : Integer ;
                height : Integer ;
                width : Integer ;
                rowBytes : Integer
                ) : Integer ; stdcall ;
 TimgGrabSetup = function(
                 SessionID : Integer;
                 startNow : Integer
                 ) : Integer ; stdcall ;
 TimgGrab = function(
            SessionID : Integer;
           var bufAddr : Pointer ;
            syncOnVB : Integer
            ) : Integer ; stdcall ;
 TimgGrabArea = function(
                SessionID : Integer;
                var bufAddr : Pointer ;
                syncOnVB : Integer ;
                top : Integer ;
                left : Integer ;
                height : Integer ;
                width : Integer ;
                rowBytes : Integer
                ) : Integer ; stdcall ;
 TimgRingSetup = function(
                 SessionID : Integer;
                 numberBuffer : Integer ;
                 bufferList : Pointer ;
                 skipCount : Integer ;
                 startnow : Integer
                 ) : Integer ; stdcall ;
 TimgSequenceSetup = function(
                     SessionID : Integer;
                     numberBuffer : Integer;
                     var bufferList : Array of Pointer ;
                     skipCount : Array of Integer ;
                     startnow : Integer ;
                     async : Integer
                     ) : Integer ; stdcall ;
 TimgSessionStartAcquisition = function(
                               SessionID : Integer
                               ) : Integer ; stdcall ;
 TimgSessionStopAcquisition = function(
                              SessionID : Integer
                              ) : Integer ; stdcall ;
 TimgSessionStatus = function(
                     SessionID : Integer;
                     var boardStatus : Integer ;
                     var bufIndex : Integer
                     ) : Integer ; stdcall ;
 TimgSessionConfigureROI = function(
                           SessionID : Integer;
                           top : Integer ;
                           left : Integer ;
                           height : Integer ;
                           width : Integer
                           ) : Integer ; stdcall ;
 TimgSessionGetROI = function(
                     SessionID : Integer;
                     var top : Integer ;
                     var left : Integer ;
                     var height : Integer ;
                     var width : Integer
                     ) : Integer ; stdcall ;
 TimgSessionGetBufferSize = function(
                            SessionID : Integer;
                            var sizeNeeded : Integer
                            ) : Integer ; stdcall ;
 TimgGetAttribute = function(
                    ID : Integer ;
                    Attribtype : Integer ;
                    var Value : Integer
                    ) : Integer ; stdcall ;
 TimgSetAttribute = function(
                    ID : Integer ;
                    Attribtype : Integer ;
                    value : Integer
                    ) : Integer ; stdcall ;
 TimgCreateBuffer = function(
                    SessionID : Integer;
                    where : Integer ;
                    bufferSize : Integer ;
                    var bufAddr : Pointer
                    ) : Integer ; stdcall ;
 TimgDisposeBuffer = function(
                     bufAddr : Pointer
                     ) : Integer ; stdcall ;
 TimgCreateBufList = function(
                     numElements : Integer ;
                     var BUFLIST_ID : Integer
                     ) : Integer ; stdcall ;
 TimgDisposeBufList = function(
                      BUFLIST_ID : Integer ;
                      freeResources : Integer
                      ) : Integer ; stdcall ;
 TimgSetBufferElement = function(
                        BUFLIST_ID : Integer ;
                        elemement : Integer ;
                        itemType : Integer ;
                        itemValue : Integer
                        ) : Integer ; stdcall ;
 TimgGetBufferElement = function(
                        BUFLIST_ID : Integer ;
                        element : Integer ;
                        itemType : Integer ;
                        var itemValue : Integer
                        ) : Integer ; stdcall ;
 TimgSessionConfigure = function(
                        SessionID : Integer;
                        BUFLIST_ID : Integer
                        ) : Integer ; stdcall ;
 TimgSessionAcquire = function(
                      SessionID : Integer;
                      async : Integer ;
                      callback : Pointer
                      ) : Integer ; stdcall ;
 TimgSessionAbort = function(
                    SessionID : Integer;
                    var bufNum : Integer
                    ) : Integer ; stdcall ;
 TimgSessionExamineBuffer = function(
                            SessionID : Integer;
                            whichBuffer : Integer ;
                            var bufferNumber : Integer ;
                            var bufferAddr : Pointer
                            ) : Integer ; stdcall ;
 TimgSessionReleaseBuffer = function(
                            SessionID : Integer
                            ) : Integer ; stdcall ;
 TimgSessionClearBuffer = function(
                          SessionID : Integer;
                          buf_num : Integer ;
                          pixel_value : Byte
                          ) : Integer ; stdcall ;
 TimgSessionCopyArea = function(
                       SessionID : Integer;
                       buf_num : Integer ;
                       top : Integer ;
                       left : Integer ;
                       height : Integer ;
                       width : Integer ;
                       Buffer : Pointer ;
                       rowbytes : Integer ;
                       vsync : Integer
                       ) : Integer ; stdcall ;
 TimgSessionCopyBuffer = function(
                         SessionID : Integer;
                         buf_num : Integer ;
                         Buffer : Pointer ;
                         vsync : Integer
                         ) : Integer ; stdcall ;
 TimgSessionGetLostFramesList = function(
                                SessionID : Integer;
                                var framelist;
                                numEntries : Integer
                                ) : Integer ; stdcall ;
 TimgSessionSetUserLUT8bit = function(
                             SessionID : Integer;
                             lutType : Integer ;
                             lut : Pointer
                             ) : Integer ; stdcall ;
 TimgSessionSetUserLUT16bit = function(
                              SessionID : Integer;
                              lutType : Integer ;
                              lut : Pointer
                              ) : Integer ; stdcall ;
 TimgGetCameraAttributeNumeric = function(
                                 SessionID : Integer;
                                 attributeString : PChar ;
                                 var currentValueNumeric : Double
                                 ) : Integer ; stdcall ;
 TimgSetCameraAttributeNumeric = function(
                                 SessionID : Integer;
                                 attributeString : PChar ;
                                 newValueNumeric : Double
                                 ) : Integer ; stdcall ;
 TimgGetCameraAttributeString = function(
                                SessionID : Integer;
                                attributeString : PChar ;
                                currentValueString : PChar ;
                                sizeofCurrentValueString : Integer
                                ) : Integer ; stdcall ;
 TimgSetCameraAttributeString = function(
                                SessionID : Integer;
                                attributeString : PChar ;
                                newValueString : PChar
                                ) : Integer ; stdcall ;
 TimgSessionSerialWrite = function(
                          SessionID : Integer;
                          Buffer : Pointer ;
                          var bufSize : Integer ;
                          timeout : Integer
                          ) : Integer ; stdcall ;
 TimgSessionSerialRead = function(
                         SessionID : Integer;
                         Buffer : Pointer ;
                         var bufSize : Integer ;
                         timeout : Integer
                         ) : Integer ; stdcall ;
 TimgSessionSerialReadBytes = function(
                              SessionID : Integer;
                              Buffer : Pointer ;
                              var bufferSize : Integer ;
                              timeout : Integer
                              ) : Integer ; stdcall ;
 TimgSessionSerialFlush = function(
                          SessionID : Integer
                          ) : Integer ; stdcall ;
 TimgPulseCreate2 = function(
                    timeBase : Integer ;
                    delay : Integer ;
                    width : Integer ;
                    signalType : Integer ;
                    signalIdentifier : Integer ;
                    signalPolarity : Integer ;
                    IoutputType : Integer ;
                    outputNumber : Integer ;
                    outputPolarity : Integer ;
                    pulseMode : Integer ;
                    var PULSE_ID : Integer
                    ) : Integer ; stdcall ;
 TimgPulseDispose = function(
                    var PULSE_ID : Integer
                    ) : Integer ; stdcall ;
 TimgPulseRate = function(
                 delaytime : Double ;
                 widthtime : Double ;
                 var delay : Integer ;
                 var width : Integer ;
                 var timebase : Integer
                 ) : Integer ; stdcall ;
 TimgPulseStart = function(
                  PULSE_ID : Integer ;
                  SessionID : Integer
                  ) : Integer ; stdcall ;
 TimgPulseStop = function(
                 PULSE_ID  : Integer
                 ) : Integer ; stdcall ;
 TimgSessionWaitSignal2 = function(
                          SessionID : Integer;
                          signalType : Integer ;
                          signalIdentifier : Integer ;
                          signalPolarity : Integer ;
                          timeout : Integer
                          ) : Integer ; stdcall ;
 TimgSessionWaitSignalAsync2 = function(
                               SessionID : Integer;
                               signalType : Integer ;
                               signalIdentifier : Integer ;
                               signalPolarity : Integer ;
                               funcptr : Pointer ;
                               var callbackData : Pointer
                               ) : Integer ; stdcall ;
 TimgSessionTriggerDrive2 = function(
                            SessionID : Integer ;
                            trigType : Integer ;
                            trigNum : Integer ;
                            polarity : Integer ;
                            signal : Integer
                            ) : Integer ; stdcall ;
 TimgSessionTriggerRead2 = function(
                           SessionID : Integer;
                           trigType : Integer ;
                           trigNum : Integer ;
                           polarity : Integer ;
                           var status : Integer
                           ) : Integer ; stdcall ;
 TimgSessionTriggerRoute2 = function(
                            boardid : Integer ;
                            srcTriggerType : Integer ;
                            srcTriggerNumber : Integer ;
                            dstTriggerType : Integer ;
                            dstTriggerNumber : Integer
                            ) : Integer ; stdcall ;
 TimgSessionTriggerClear = function(
                           SessionID : Integer
                           ) : Integer ; stdcall ;
 TimgSessionTriggerConfigure2 = function(
                                boardid : Integer ;
                                trigType : Integer ;
                                trigNum : Integer ;
                                polarity : Integer ;
                                timeout : Integer ;
                                action : Integer
                                ) : Integer ; stdcall ;
 TimgPlot = function(
            window : THandle ;
            buffer : Pointer ;
            leftBufOffset : Integer ;
            topBufOffset : Integer ;
            xsize : Integer ;
            ysize : Integer ;
            xpos : Integer ;
            ypos : Integer ;
            flags : Integer
            ) : Integer ; stdcall ;
 TimgPlotDC = function(
              DeviceContext : THandle ;
              buffer : Pointer ;
              xbuffoff : Integer ;
              ybuffoff : Integer ;
              xsize : Integer ;
              ysize : Integer ;
              xscreen : Integer ;
              yscreen : Integer ;
              flags : Integer
              ) : Integer ; stdcall ;
 TimgSessionSaveBufferEx = function(
                           SessionID : Integer;
                           buffer : Pointer ;
                           file_name : PChar
                           ) : Integer ; stdcall ;
 TimgShowError = function(
                 IMG_ERR : Integer ;
                 text : PChar
                 ) : Integer ; stdcall ;
 TimgInterfaceReset = function(
                      InterfaceID : Integer
                      ) : Integer ; stdcall ;
 TimgInterfaceQueryNames = function(
                           index : Integer ;
                           queryName : PChar
                           ) : Integer ; stdcall ;
 TimgCalculateBayerColorLUT = function(
                              redGain : Double ;
                              greenGain : Double ;
                              blueGain : Double ;
                              var redLUT : Integer ;
                              var greenLUT : Integer ;
                              var blueLUT : Integer ;
                              bitDepth : Integer
                              ) : Integer ; stdcall ;
 TimgBayerColorDecode = function(
                        dst : Pointer ;
                        src : Pointer ;
                        rows : Integer ;
                        cols : Integer ;
                        dstRowPixels : Integer ;
                        srcRowPixels : Integer ;
                        var redLUT : Integer ;
                        var greenLUT : Integer ;
                        var blueLUT : Integer ;
                        bayerPattern : Byte ;
                        bitDepth : Integer ;
                        reserved : Integer
                        ) : Integer ; stdcall ;
 TimgSessionLineTrigSource2 = function(
                              SESSION_ID : Integer ;
                              trigType : Integer ;
                              trigNum : Integer ;
                              polarity : Integer ;
                              skip : Integer
                              ) : Integer ; stdcall ;
 TimgSessionFitROI = function(
                     SessionID : Integer ;
                     fitMode : Integer ;
                     top : Integer ;
                     left : Integer ;
                     height : Integer ;
                     width : Integer ;
                     var fittedTop : Integer ;
                     var fittedLeft : Integer ;
                     var fittedHeight : Integer ;
                     var fittedWidth : Integer
                     ) : Integer ; stdcall ;
 TimgEncoderResetPosition = function(
                            SessionID : Integer
                            ) : Integer ; stdcall ;


function IMAQ_OpenCamera(
          var Session : TIMAQSession ;
          var FrameWidthMax : Integer ;
          var FrameHeightMax : Integer ;
          var NumBytesPerPixel : Integer ;
          var PixelDepth : Integer ;
          CameraInfo : TStringList
          ) : Boolean ;

procedure IMAQ_CloseCamera(
          var Session : TIMAQSession
          ) ;

function IMAQ_StartCapture(
         var Session : TIMAQSession ;
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

procedure IMAQ_StopCapture(
          var Session : TIMAQSession              // Camera session #
          ) ;

procedure IMAQ_GetImage(
          var Session : TIMAQSession
          ) ;

procedure IMAQ_GetCameraGainList( CameraGainList : TStringList ) ;

function IMAQ_CheckFrameInterval(
          var Session : TIMAQSession ;
          var FrameInterval : Double ) : Integer ;

procedure IMAQ_LoadLibrary  ;
function IMAQ_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;

procedure IMAQ_CheckROIBoundaries( Session : TIMAQSession ;
                                   var FFrameLeft : Integer ;
                                   var FFrameRight : Integer ;
                                   var FFrameTop : Integer ;
                                   var FFrameBottom : Integer ;
                                   var FFrameWidth : Integer ;
                                   var FFrameHeight : Integer
                                   ) ;


procedure IMAQ_CheckError( ErrNum : Integer ) ;

function IMAQ_CharArrayToString( cBuf : Array of Char ) : String ;


var

 imgInterfaceOpen : TimgInterfaceOpen ;
 imgSessionOpen  : TimgSessionOpen  ;
 imgClose  : TimgClose  ;
 imgSnap  : TimgSnap  ;
 imgSnapArea  : TimgSnapArea  ;
 imgGrabSetup : TimgGrabSetup ;
 imgGrab : TimgGrab ;
 imgGrabArea : TimgGrabArea ;
 imgRingSetup : TimgRingSetup ;
 imgSequenceSetup : TimgSequenceSetup ;
 imgSessionStartAcquisition : TimgSessionStartAcquisition ;
 imgSessionStopAcquisition : TimgSessionStopAcquisition ;

 imgSessionStatus  : TimgSessionStatus  ;
 imgSessionConfigureROI : TimgSessionConfigureROI ;
 imgSessionGetROI : TimgSessionGetROI ;
 imgSessionGetBufferSize : TimgSessionGetBufferSize ;
 imgGetAttribute : TimgGetAttribute ;
 imgSetAttribute  : TimgSetAttribute  ;
 imgDisposeBuffer  : TimgDisposeBuffer  ;
 imgCreateBufList  : TimgCreateBufList  ;
 imgDisposeBufList  : TimgDisposeBufList  ;
 imgSetBufferElement : TimgSetBufferElement ;
 imgGetBufferElement  : TimgGetBufferElement  ;
 imgSessionConfigure  : TimgSessionConfigure  ;
 imgSessionAcquire  : TimgSessionAcquire  ;
 imgSessionAbort : TimgSessionAbort ;
 imgSessionExamineBuffer : TimgSessionExamineBuffer ;
 imgSessionReleaseBuffer : TimgSessionReleaseBuffer ;
 imgSessionClearBuffer : TimgSessionClearBuffer ;
 imgSessionCopyArea : TimgSessionCopyArea ;
 imgSessionCopyBuffer  : TimgSessionCopyBuffer  ;
 imgSessionGetLostFramesList  : TimgSessionGetLostFramesList  ;
 imgSessionSetUserLUT8bit  : TimgSessionSetUserLUT8bit  ;
 imgSessionSetUserLUT16bit  : TimgSessionSetUserLUT16bit  ;
 imgGetCameraAttributeNumeric  : TimgGetCameraAttributeNumeric  ;
 imgSetCameraAttributeNumeric  : TimgSetCameraAttributeNumeric  ;
 imgGetCameraAttributeString : TimgGetCameraAttributeString ;
 imgSetCameraAttributeString : TimgSetCameraAttributeString ;
 imgSessionSerialWrite : TimgSessionSerialWrite ;
 imgSessionSerialRead : TimgSessionSerialRead ;
 imgSessionSerialReadBytes  : TimgSessionSerialReadBytes  ;
 imgSessionSerialFlush : TimgSessionSerialFlush ;
 imgPulseCreate2  : TimgPulseCreate2  ;
 imgPulseDispose  : TimgPulseDispose  ;
 imgPulseRate  : TimgPulseRate  ;
 imgPulseStart : TimgPulseStart ;
 imgPulseStop : TimgPulseStop ;
 imgSessionWaitSignal2 : TimgSessionWaitSignal2 ;
 imgSessionWaitSignalAsync2  : TimgSessionWaitSignalAsync2  ;
 imgSessionTriggerDrive2 : TimgSessionTriggerDrive2 ;
 imgSessionTriggerRead2 : TimgSessionTriggerRead2 ;
 imgSessionTriggerRoute2 : TimgSessionTriggerRoute2 ;
 imgSessionTriggerClear : TimgSessionTriggerClear ;
 imgSessionTriggerConfigure2 : TimgSessionTriggerConfigure2 ;
 imgPlot : TimgPlot ;
 imgPlotDC : TimgPlotDC ;
 imgSessionSaveBufferEx : TimgSessionSaveBufferEx ;
 imgShowError : TimgShowError ;
 imgInterfaceReset : TimgInterfaceReset ;
 imgInterfaceQueryNames : TimgInterfaceQueryNames ;
 imgCalculateBayerColorLUT : TimgCalculateBayerColorLUT ;
 imgBayerColorDecode : TimgBayerColorDecode ;
 imgSessionLineTrigSource2 : TimgSessionLineTrigSource2 ;
 imgSessionFitROI : TimgSessionFitROI ;
 imgEncoderResetPosition : TimgEncoderResetPosition ;


implementation
uses sescam ;


var
    LibraryHnd : THandle ;         // PVCAM32.DLL library handle
    LibraryLoaded : boolean ;      // PVCAM32.DLL library loaded flag


procedure IMAQ_LoadLibrary  ;
{ -------------------------------------
  Load IMAQ.DLL library into memory
  -------------------------------------}
var
    LibFileName : string ;
begin

     { Load interface DLL library }
     LibFileName := 'IMAQ.DLL' ;
     LibraryHnd := LoadLibrary( PChar(LibFileName));

     { Get addresses of procedures in library }
     if LibraryHnd > 0 then begin
        @imgInterfaceOpen := IMAQ_GetDLLAddress(LibraryHnd,'imgInterfaceOpen') ;
        @imgSessionOpen := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionOpen') ;
        @imgClose := IMAQ_GetDLLAddress(LibraryHnd,'imgClose') ;
        @imgSnap := IMAQ_GetDLLAddress(LibraryHnd,'imgSnap') ;
        @imgSnapArea := IMAQ_GetDLLAddress(LibraryHnd,'imgSnapArea') ;
        @imgGrabSetup := IMAQ_GetDLLAddress(LibraryHnd,'imgGrabSetup') ;
        @imgGrab := IMAQ_GetDLLAddress(LibraryHnd,'imgGrab') ;
        @imgGrabArea := IMAQ_GetDLLAddress(LibraryHnd,'imgGrabArea') ;
        @imgRingSetup := IMAQ_GetDLLAddress(LibraryHnd,'imgRingSetup') ;
        @imgSequenceSetup := IMAQ_GetDLLAddress(LibraryHnd,'imgSequenceSetup') ;
        @imgSessionStartAcquisition := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionStartAcquisition') ;
        @imgSessionStopAcquisition := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionStopAcquisition') ;
        @imgSessionStatus := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionStatus') ;
        @imgSessionConfigureROI := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionConfigureROI') ;
        @imgSessionGetROI := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionGetROI') ;
        @imgSessionGetBufferSize := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionGetBufferSize') ;
        @imgGetAttribute := IMAQ_GetDLLAddress(LibraryHnd,'imgGetAttribute') ;
        @imgSetAttribute := IMAQ_GetDLLAddress(LibraryHnd,'imgSetAttribute') ;
        @imgSetAttribute := IMAQ_GetDLLAddress(LibraryHnd,'imgSetAttribute') ;
        @imgDisposeBuffer := IMAQ_GetDLLAddress(LibraryHnd,'imgDisposeBuffer') ;
        @imgCreateBufList := IMAQ_GetDLLAddress(LibraryHnd,'imgCreateBufList') ;
        @imgDisposeBufList := IMAQ_GetDLLAddress(LibraryHnd,'imgDisposeBufList') ;
        @imgSetBufferElement := IMAQ_GetDLLAddress(LibraryHnd,'imgSetBufferElement') ;
        @imgGetBufferElement := IMAQ_GetDLLAddress(LibraryHnd,'imgGetBufferElement') ;
        @imgSessionConfigure := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionConfigure') ;
        @imgSessionAcquire := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionAcquire') ;
        @imgSessionAbort := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionAbort') ;
        @imgSessionExamineBuffer := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionExamineBuffer') ;
        @imgSessionReleaseBuffer := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionReleaseBuffer') ;
        @imgSessionClearBuffer := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionClearBuffer') ;
        @imgSessionCopyArea := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionCopyArea') ;
        @imgSessionCopyBuffer := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionCopyBuffer') ;
        @imgSessionGetLostFramesList := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionGetLostFramesList') ;
        @imgSessionSetUserLUT8bit := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionSetUserLUT8bit') ;
        @imgSessionSetUserLUT16bit := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionSetUserLUT16bit') ;
        @imgGetCameraAttributeNumeric := IMAQ_GetDLLAddress(LibraryHnd,'imgGetCameraAttributeNumeric') ;
        @imgSetCameraAttributeNumeric := IMAQ_GetDLLAddress(LibraryHnd,'imgSetCameraAttributeNumeric') ;
        @imgGetCameraAttributeString := IMAQ_GetDLLAddress(LibraryHnd,'imgGetCameraAttributeString') ;
        @imgSetCameraAttributeString := IMAQ_GetDLLAddress(LibraryHnd,'imgSetCameraAttributeString') ;
        @imgSessionSerialWrite := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionSerialWrite') ;
        @imgSessionSerialRead := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionSerialRead') ;
        @imgSessionSerialReadBytes := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionSerialReadBytes') ;
        @imgSessionSerialFlush := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionSerialFlush') ;
        @imgPulseCreate2 := IMAQ_GetDLLAddress(LibraryHnd,'imgPulseCreate2') ;
        @imgPulseDispose := IMAQ_GetDLLAddress(LibraryHnd,'imgPulseDispose') ;
        @imgPulseRate := IMAQ_GetDLLAddress(LibraryHnd,'imgPulseRate') ;
        @imgPulseStart := IMAQ_GetDLLAddress(LibraryHnd,'imgPulseStart') ;
        @imgPulseStop := IMAQ_GetDLLAddress(LibraryHnd,'imgPulseStop') ;
        @imgSessionWaitSignal2 := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionWaitSignal2') ;
        @imgSessionWaitSignalAsync2 := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionWaitSignalAsync2') ;
        @imgSessionTriggerDrive2 := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionTriggerDrive2') ;
        @imgSessionTriggerRead2 := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionTriggerRead2') ;
        @imgSessionTriggerRoute2 := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionTriggerRoute2') ;
        @imgSessionTriggerClear := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionTriggerClear') ;
        @imgSessionTriggerConfigure2 := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionTriggerConfigure2') ;
        @imgPlot := IMAQ_GetDLLAddress(LibraryHnd,'imgPlot') ;
        @imgPlotDC := IMAQ_GetDLLAddress(LibraryHnd,'imgPlotDC') ;
        @imgSessionSaveBufferEx := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionSaveBufferEx') ;
        @imgShowError := IMAQ_GetDLLAddress(LibraryHnd,'imgShowError') ;
        @imgInterfaceReset := IMAQ_GetDLLAddress(LibraryHnd,'imgInterfaceReset') ;
        @imgInterfaceQueryNames := IMAQ_GetDLLAddress(LibraryHnd,'imgInterfaceQueryNames') ;
        @imgCalculateBayerColorLUT := IMAQ_GetDLLAddress(LibraryHnd,'imgCalculateBayerColorLUT') ;
        @imgBayerColorDecode := IMAQ_GetDLLAddress(LibraryHnd,'imgBayerColorDecode') ;
        @imgSessionLineTrigSource2 := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionLineTrigSource2') ;
        @imgSessionFitROI := IMAQ_GetDLLAddress(LibraryHnd,'imgSessionFitROI') ;
//        @imgEncoderResetPosition := IMAQ_GetDLLAddress(LibraryHnd,'imgEncoderResetPosition') ;
        LibraryLoaded := True ;
        end
     else begin
          ShowMessage( 'IMAQ: ' + LibFileName + ' not found!' ) ;
          LibraryLoaded := False ;
          end ;

     end ;


function IMAQ_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;
// -----------------------------------------
// Get address of procedure within PVCAM32.DLL
// -----------------------------------------
begin
    Result := GetProcAddress(Handle,PChar(ProcName)) ;
    if Result = Nil then
       ShowMessage('IMAQ.DLL: ' + ProcName + ' not found') ;
    end ;


function IMAQ_OpenCamera(
          var Session : TIMAQSession ;   // Camera session
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
    Err : Integer ;
    i,j :Integer ;
    Supported : Boolean ;
    s : String ;
    InterfaceName : Array[0..255] of char ;
    InterfaceType : Integer ;
    ColourSupported : Integer ;
    BoardType : String ;
begin

     Result := False ;

     // Load DLL libray
     if not LibraryLoaded then IMAQ_LoadLibrary  ;
     if not LibraryLoaded then Exit ;

     // Get name of first interface found
     i := 0 ;
     repeat
        Err := imgInterfaceQueryNames( i, InterfaceName ) ;
        until (Err = 0) or (i > 10) ;
     CameraInfo.Add( String(InterfaceName)) ;

     // Open interface
     Err := imgInterfaceOpen( InterfaceName, Session.InterfaceID ) ;
     IMAQ_CheckError( Err ) ;
     if Err <> 0 then Exit ;
     Session.InterfaceOpen := True ;

     // Open session
     Err := imgSessionOpen( Session.InterfaceID, Session.SessionID ) ;
     IMAQ_CheckError( Err ) ;
     if Err <> 0 then Exit ;
     Session.SessionOpen := True ;

     imgGetAttribute( Session.SessionID, IMG_ATTR_INTERFACE_TYPE, InterfaceType ) ;
     case CArdinal(InterfaceType) of
        PCIIMAQ1408_REVA : BoardType := 'PCI-1408 (Rev A)' ;
        PCIIMAQ1408_REVB : BoardType := 'PCI-1408 (Rev B)' ;
        PCIIMAQ1408_REVC : BoardType := 'PCI-1408 (Rev C)' ;
        PCIIMAQ1408_REVF : BoardType := 'PCI-1408 (Rev F)' ;
        PCIIMAQ1408_REVX : BoardType := 'PCI-1408 (Rev X)' ;
        IMAQ_PCI_1405 : BoardType := 'PCI-1405' ;
        IMAQ_PXI_1405 : BoardType := 'PCX-1405' ;
        IMAQ_PCI_1407 : BoardType := 'PCI-1407' ;
        IMAQ_PXI_1407 : BoardType := 'PCX-1407' ;
        IMAQ_PCI_1408 : BoardType := 'PCI-1408' ;
        IMAQ_PXI_1408 : BoardType := 'PCX-1408' ;
        IMAQ_PCI_1409 : BoardType := 'PCI-1409' ;
        IMAQ_PXI_1409 : BoardType := 'PCX-1409' ;
        IMAQ_PCI_1410 : BoardType := 'PCI-1410' ;
        IMAQ_PCI_1411 : BoardType := 'PCI-1411' ;
        IMAQ_PXI_1411 : BoardType := 'PCX-1411' ;
        IMAQ_PCI_1413 : BoardType := 'PCI-1413' ;
        IMAQ_PXI_1413 : BoardType := 'PCX-1413' ;
        IMAQ_PCI_1422 : BoardType := 'PCI-1422' ;
        IMAQ_PXI_1422 : BoardType := 'PCX-1422' ;
        IMAQ_PCI_1423 : BoardType := 'PCI-1423' ;
        IMAQ_PXI_1423 : BoardType := 'PCX-1423' ;
        IMAQ_PCI_1424 : BoardType := 'PCI-1424' ;
        IMAQ_PXI_1424 : BoardType := 'PCX-1424' ;
        IMAQ_PCI_1426 : BoardType := 'PCI-1426' ;
        IMAQ_PCI_1428 : BoardType := 'PCI-1428' ;
        IMAQ_PXI_1428 : BoardType := 'PCX-1428' ;
        IMAQ_PCIX_1429 : BoardType := 'PCI-1429' ;
        IMAQ_PCIe_1429 : BoardType := 'PCIe-1429' ;
        else BoardType := 'Unknown' ;
        end ;

     CameraInfo.Add(Format('Board Type: PCI-%x',[InterfaceType]) ) ;

     // If this is a colour camera, set it to monochrome mode

     if imgGetAttribute( Session.SessionID, IMG_ATTR_COLOR, ColourSupported ) = 0 then begin
        if ColourSupported <> 0 then begin
           CameraInfo.Add('Colour images supported (luminance display mode selected)') ;
           // Set colour representation mode to luminance
           imgSetAttribute( Session.SessionID, IMG_ATTR_COLOR_IMAGE_REP, IMG_COLOR_REP_LUM8 ) ;
           end ;
        end ;

     // Pixel depth
     if imgGetAttribute( Session.SessionID, IMG_ATTR_PIXDEPTH, PixelDepth ) <> 0 then
        CameraInfo.Add('Unable to determine pixel depth') ;

     // Bytes per pixel
     if imgGetAttribute( Session.SessionID, IMG_ATTR_BYTESPERPIXEL, NumBytesPerPixel ) <> 0 then
        CameraInfo.Add('Unable to determine no. bytes/pixel') ;

     // Image width
     if imgGetAttribute( Session.SessionID, IMG_ATTR_ACQWINDOW_WIDTH, FrameWidthMax ) <> 0 then
        CameraInfo.Add('Unable to determine horizontal pixel resolution') ;

     // Image height
     if imgGetAttribute( Session.SessionID, IMG_ATTR_ACQWINDOW_HEIGHT, FrameHeightMax ) <> 0 then
        CameraInfo.Add('Unable to determine vertical pixel resolution') ;

     CameraInfo.Add(format('Image size: %d x %d pixels (%d bits/pixel)',
                    [FrameWidthMax,FrameHeightMax,PixelDepth])) ;

     // Clear flags
     Session.AcquisitionInProgress := False ;
     Result := True ;

     end ;


procedure IMAQ_CheckROIBoundaries( Session : TIMAQSession ;
                                   var FFrameLeft : Integer ;
                                   var FFrameRight : Integer ;
                                   var FFrameTop : Integer ;
                                   var FFrameBottom : Integer ;
                                   var FFrameWidth : Integer ;
                                   var FFrameHeight : Integer
                                   ) ;
// -------------------------------
// Ensure ROI boundaries are valid
// -------------------------------
var
    FittedFrameLeft : Integer ;
    FittedFrameTop : Integer ;
    FittedFrameWidth : Integer ;
    FittedFrameHeight : Integer ;

begin

     // Calculate valid set of ROI boundaries
     IMAQ_CheckError(imgSessionFitROI( Session.SessionID,
                       IMG_ROI_FIT_SMALLER,
                       FFrameTop,
                       FFrameLeft,
                       FFrameBottom - FFrameTop +1,
                       FFrameRight - FFrameLeft +1,
                       FittedFrameTop,
                       FittedFrameLeft,
                       FittedFrameHeight,
                       FittedFrameWidth )) ;

     // Update
     FFrameLeft := FittedFrameLeft ;
     FFrameTop := FittedFrameTop ;
     FFrameWidth := FittedFrameWidth ;
     FFrameHeight := FittedFrameHeight ;
     FFrameRight := FFrameLeft + FFrameWidth -1 ;
     FFrameBottom := FFrameTop + FFrameHeight -1 ;

     end ;


procedure IMAQ_CloseCamera(
          var Session : TIMAQSession     // Camera session #
          ) ;
// ----------------
// Shut down camera
// ----------------
begin

     if not LibraryLoaded then Exit ;

     // Stop any acquisition which is in progress
     if Session.AcquisitionInProgress then begin
       IMAQ_CheckError(imgSessionStopAcquisition(Session.SessionID)) ;
       Session.AcquisitionInProgress := false ;
       end ;

     if Session.SessionOpen then begin
        IMAQ_CheckError(imgClose( Session.SessionID, 1 )) ;
        Session.SessionOpen := False ;
        end ;

     if Session.InterfaceOpen then begin
        IMAQ_CheckError(imgClose( Session.InterfaceID, 1 )) ;
        Session.InterfaceOpen := False ;
        end ;

    end ;


function IMAQ_StartCapture(
         var Session : TIMAQSession ;          // Camera session #
         var ExposureTime : Double ;      // Frame exposure time
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
var
    i,Err : Integer ;
begin

    // Stop any acquisition which is in progress
    if Session.AcquisitionInProgress then begin
       IMAQ_CheckError(imgSessionStopAcquisition(Session.SessionID)) ;
       Session.AcquisitionInProgress := false ;
       end ;

      // Create buffer list
      for i := 0 to High(Session.BufferList) do begin
          Session.BufferList[i] := Nil ;
          end ;

     // Internal/external triggering of frame capture
     if ExternalTrigger = CamFreeRun then begin
        // Free run mode
        IMAQ_CheckError(imgSessionTriggerConfigure2( Session.SessionID,
                                                     IMG_SIGNAL_EXTERNAL,
                                                     0,
                                                     IMG_TRIG_POLAR_ACTIVEH,
                                                     1000000,
                                                     IMG_TRIG_ACTION_NONE)) ;
        // Output a pulse on trigger line at end of frame
        IMAQ_CheckError(imgSessionTriggerDrive2( Session.SessionID,
                                                 IMG_SIGNAL_EXTERNAL,
                                                 0,
                                                 IMG_TRIG_POLAR_ACTIVEH,
                                                 IMG_TRIG_DRIVE_FRAME_DONE)) ;
        end
     else begin
        // External trigger mode
        // Disable trigger output
        IMAQ_CheckError(imgSessionTriggerDrive2( Session.SessionID,
                                                 IMG_SIGNAL_EXTERNAL,
                                                 0,
                                                 IMG_TRIG_POLAR_ACTIVEH,
                                                 IMG_TRIG_DRIVE_DISABLED)) ;
        // Trigger frame capture
        IMAQ_CheckError(imgSessionTriggerConfigure2( Session.SessionID,
                                                     IMG_SIGNAL_EXTERNAL,
                                                     0,
                                                     IMG_TRIG_POLAR_ACTIVEH,
                                                     100000,
                                                     IMG_TRIG_ACTION_BUFFER)) ;
        end ;


      // Set CCD readout region
      IMAQ_CheckError( imgSessionConfigureROI( Session.SessionID,
                                               FrameTop,
                                               FrameLeft,
                                               FrameHeight,
                                               FrameWidth )) ;

      // Set up ring buffer
      IMAQ_CheckError( imgRingSetup( Session.SessionID,
                                     NumFramesInBuffer,
                                     @Session.BufferList,
                                     0, 0 ));

      Session.NumFrameBuffers := NumFramesInBuffer ;
      Session.FrameBufPointer := PFrameBuffer ;
      Session.NumBytesPerFrame := NumBytesPerFrame ;
      Session.BufferIndex := 0 ;


     // Start acquisition
     IMAQ_CheckError(imgSessionStartAcquisition(Session.SessionID)) ;

     Result := True ;
     Session.AcquisitionInProgress := True ;

     end;


procedure IMAQ_StopCapture(
          var Session : TIMAQSession            // Camera session #
          ) ;
// ------------------
// Stop frame capture
// ------------------
begin

     if not Session.AcquisitionInProgress then Exit ;

     // Stop acquisition
     IMAQ_CheckError(imgSessionStopAcquisition(Session.SessionID)) ;

     Session.AcquisitionInProgress := False ;

     end;


procedure IMAQ_GetImage(
          var Session : TIMAQSession
          ) ;
// -----------------------------------------------------
// Copy images from IMAQ buffer to circular frame buffer
// -----------------------------------------------------
var
    i : Cardinal ;
    Err : Integer ;
    t0 :Integer ;
    Status,LatestIndex :Integer ;
    PFromBuf, PToBuf : PByteArray ;

begin

    if not Session.AcquisitionInProgress then Exit ;

    // Get status
    imgSessionStatus(Session.SessionID,status,LatestIndex);

    // Exit if frame not available
    if (LatestIndex < 0) or
       (LatestIndex >= Session.NumFrameBuffers) or
       (Status = 0) then Exit ;

    // Copy frames from IMAQ to main WinFluor buffer

    while Session.BufferIndex <> LatestIndex do begin
        PFromBuf := Session.BufferList[Session.BufferIndex] ;
        PToBuf := Pointer( (Session.BufferIndex*Session.NumBytesPerFrame)
                         + Cardinal(Session.FrameBufPointer) ) ;
        for i := 0 to Session.NumBytesPerFrame-1 do begin
            PToBuf^[i] := PFromBuf^[i] ;
            end ;
        Inc(Session.BufferIndex) ;
        if Session.BufferIndex >= Session.NumFrameBuffers then
           Session.BufferIndex := 0 ;
           end ;

     //outputdebugString(PChar(format('%d %d ',[status, LatestIndex]))) ;

    end ;


procedure IMAQ_GetCameraGainList( CameraGainList : TStringList ) ;
// --------------------------------------------
// Get list of available camera amplifier gains
// --------------------------------------------
var
    i : Integer ;
begin
    CameraGainList.Clear ;
    for i := 1 to 1 do CameraGainList.Add( format( '%d',[i] )) ;
    end ;


function IMAQ_CheckFrameInterval(
         var Session : TIMAQSession ;
         var FrameInterval : Double
         ) : Integer ;
//
// Check that selected frame interval is valid
// -------------------------------------------
//
begin

     FrameInterval := Max(0.04,FrameInterval) ;

     end ;


procedure IMAQ_CheckError( ErrNum : Integer ) ;
// ------------
// Report error
// ------------
var
    cBuf : Array[0..256] of Char ;
    i : Integer ;
    s : string ;
begin
    if ErrNum <> 0 then begin
       for i := 0 to High(cBuf) do cBuf[i] := #0 ;
       imgShowError ( ErrNum, cBuf ) ;
       s := '' ;
       for i := 0 to High(cBuf) do if cBuf[i] <> #0 then s := s + cBuf[i] ;
       ShowMessage( 'IMAQ: ' + s ) ;
       end ;
    end ;


function IMAQ_CharArrayToString(
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
