unit HamDCAMUnit;
// ---------------------------------------
// Hamamatsu cameras supported by DCAM-API
// ---------------------------------------
// 01/05/08 Support for C4880 added
// 21/01/09 AdditionalReadoutTime added to StartCapture
// 18/3/09  JD FramePointer buffer increased 10,000 frames
// 03/4/09  JD Image-EM (C9100) now uses DCAM_TRIGMODE_SYNCREADOUT
// 07/9/09  JD DCAM V3 Camera Properties can now be set
// 25/8/11  JD ReadoutSpeed now set in StartCapture
// 26/8/11  JD ReadoutSpeed now set using dcamparam_scanmode_speed_slowest as min. speed
// 30/8/11  JD Latest attempt to get scan speed setting correct


interface

uses WinTypes,sysutils, classes, dialogs, mmsystem, messages,
     controls, math, forms, strutils ;

const

	DCAMERR_SUCCESS          = 1;            // P: */
	DCAMERR_NONE             = 0;            // no error             */
	DCAMERR_BUSY             = $80000101;   // busy; cannot process */
	DCAMERR_ABORT            = $80000102;   // abort process        */
	DCAMERR_NOTREADY         = $80000103;   // not ready state      */
	DCAMERR_NOTSTABLE        = $80000104;   // not stable state     */
	DCAMERR_UNSTABLE         = $80000105;   // O: now unstable state */
	DCAMERR_TIMEOUT          = $80000106;   // timeout              */
	DCAMERR_NOTBUSY          = $80000107;   // O: not busy state    */

	DCAMERR_NORESOURCE       = $80000201;   // O: not enough resource except memory */
	DCAMERR_NOMEMORY         = $80000203;   // not enough memory    */
	DCAMERR_NOMODULE         = $80000204;   // no sub module        */
	DCAMERR_NODRIVER         = $80000205;   // P: no driver            */
	DCAMERR_NOCAMERA         = $80000206;   // no camera            */
	DCAMERR_NOGRABBER		 = $80000207;	 // no grabber				*/
//	DCAMERR_NOCOMBINATION    = $80000208;*/ // 2.2: no combination on registry */

	DCAMERR_INVALIDMODULE	 = $80000211;   // 2.2: dcam_init() found invalid module */
	DCAMERR_INVALIDCOMMPORT	 = $80000212;   // invalid serial port */

	DCAMERR_LOSTFRAME        = $80000301;   // frame data is lost   */
	DCAMERR_COOLINGTROUBLE   = $80000302;   // something happens near cooler */

	DCAMERR_INVALIDCAMERA    = $80000806;   // invalid camera		 */
	DCAMERR_INVALIDHANDLE    = $80000807;   // invalid camera handle*/
	DCAMERR_INVALIDPARAM     = $80000808;   // invalid parameter    */

	DCAMERR_INVALIDVALUE	 = $80000821;   // invalid property value  */

// backward compatibility */
	DCAMERR_UNKNOWNMSGID     = $80000801;   // P: unknown message id   */
	DCAMERR_UNKNOWNSTRID     = $80000802;   // unknown string id    */
	DCAMERR_UNKNOWNPARAMID   = $80000803;   // unkown parameter id  */
	DCAMERR_UNKNOWNBITSTYPE  = $80000804;   // O: unknown bitmap bits type */
	DCAMERR_UNKNOWNDATATYPE  = $80000805;   // unknown frame data type  */
	DCAMERR_FAILOPENBUS      = $81001001;   // O:                   */
	DCAMERR_FAILOPENCAMERA   = $82001001;   //                      */

// internal error */
	DCAMERR_UNREACH          = $80000f01;   // internal error       */
	DCAMERR_NOTIMPLEMENT     = $80000f02;   // P: not yet implementation */
	DCAMERR_NOTSUPPORT       = $80000f03;   // function is not supported */
	DCAMERR_UNLOADED         = $80000f04;	 //	calling after process terminated */
	DCAMERR_THRUADAPTER		 = $80000f05;	 //	calling after process terminated */

	DCAMERR_FAILREADCAMERA   = $83001002;   // P: */
	DCAMERR_FAILWRITECAMERA  = $83001003;   // P: */


// ---------------------------------------------------------------- */

  DCAM_DATATYPE_NONE		=	0;
  DCAM_DATATYPE_UINT8		=	$00000001;	// bit 0 */
  DCAM_DATATYPE_UINT16	=	$00000002;	// bit 1 */
  DCAM_DATATYPE_UINT32	=	$00000008;	// bit 2 */
  DCAM_DATATYPE_INT8		=	$00000010;	// bit 4 */
  DCAM_DATATYPE_INT16		=	$00000020;	// bit 5 */
  DCAM_DATATYPE_INT32		=	$00000080;	// bit 7 */
  DCAM_DATATYPE_REAL32	=	$00000100;	//* bit 8 */
  DCAM_DATATYPE_REAL64	=	$00000200;	//-* bit 9 */
  DCAM_DATATYPE_INDEX8	=	$00010000;	//-* bit 16 */
  DCAM_DATATYPE_RGB16		=	$00020000;	//-* bit 17 */
  DCAM_DATATYPE_RGB32		=	$00080000;	//-* bit 19; */

  DCAM_DATATYPE_BGR24		=	$00000400;	// bit 10;  8bit*3; [ b0; g0; r0]; [b1; g1; r1] */
  DCAM_DATATYPE_BGR48		=	$00001000;	// bit 12; 16bit*3; [ b0; g0; r0]; [b1; g1; r1] */
  DCAM_DATATYPE_RGB24		=	$00040000;	// bit 18;  8bit*3; [ r0; g0; b0]; [r1; g1; b1] */
  DCAM_DATATYPE_RGB48		=	$00100000;	// bit 20; 16bit*3; [ r0; g0; b0]; [r1; g1; b1] */

	// just like 1394 format; Y is unsigned; U and V are signed. */
	// about U and V; signal level is from -128 to 128; data value is from $00 to $FF */
  DCAM_DATATYPE_YUV411	=	$01000000;	// 8bit; [ u0; y0; y1; v0; y2; y3 ]; [u4; y4; y5; v4; v6; y7]; */
  DCAM_DATATYPE_YUV422	=	$02000000;	// 8bit; [ u0; y0; v0; y1 ]; [u2; y2; v2; v3 ]; */
  DCAM_DATATYPE_YUV444	=	$04000000; // 8bit; [ u0; y0; v0 ]; [ u1; y1; v1 ]; */

  DCAM_BITSTYPE_NONE		=	$00000000;
  DCAM_BITSTYPE_INDEX8	=	$00000001;
  DCAM_BITSTYPE_RGB16		=	$00000002;
  DCAM_BITSTYPE_RGB24		=	$00000004;	// 8bit; [ b0; g0; r0] */
  DCAM_BITSTYPE_RGB32		=	$00000008;

//** --- camera capability	--- ***/


	DCAM_QUERYCAPABILITY_FUNCTIONS		= 0;
	DCAM_QUERYCAPABILITY_DATATYPE		= 1;
	DCAM_QUERYCAPABILITY_BITSTYPE		= 2;
	DCAM_QUERYCAPABILITY_EVENTS			= 3;

	DCAM_QUERYCAPABILITY_AREA			= 4 ;

	DCAM_CAPABILITY_BINNING2					= $00000002;
	DCAM_CAPABILITY_BINNING4					= $00000004;
	DCAM_CAPABILITY_BINNING8					= $00000008;
	DCAM_CAPABILITY_BINNING16					= $00000010;
	DCAM_CAPABILITY_BINNING32					= $00000020;
	DCAM_CAPABILITY_TRIGGER_EDGE				= $00000100;
	DCAM_CAPABILITY_TRIGGER_LEVEL				= $00000200;
	DCAM_CAPABILITY_TRIGGER_MULTISHOT_SENSITIVE = $00000400;
	DCAM_CAPABILITY_TRIGGER_CYCLE_DELAY			= $00000800;
	DCAM_CAPABILITY_TRIGGER_SOFTWARE			= $00001000;
	DCAM_CAPABILITY_TRIGGER_FASTREPETITION		= $00002000;
	DCAM_CAPABILITY_TRIGGER_TDI					= $00004000;
	DCAM_CAPABILITY_TRIGGER_TDIINTERNAL			= $00008000;
	DCAM_CAPABILITY_TRIGGER_POSI				= $00010000;
	DCAM_CAPABILITY_TRIGGER_NEGA				= $00020000;
	DCAM_CAPABILITY_TRIGGER_START				= $00040000;
									// reserved = $00080000; */
									// reserved = $00400000; */
	DCAM_CAPABILITY_TRIGGER_SYNCREADOUT			= $00800000;

	//** --- from 2.1.2 --- ***/
	DCAM_CAPABILITY_USERMEMORY					= $00100000;
	DCAM_CAPABILITY_RAWDATA						= $00200000;

	DCAM_CAPABILITY_ALL							= $00b7FF3E ;


//** --- status  --- ***/
	DCAM_STATUS_ERROR					= $0000;
	DCAM_STATUS_BUSY					= $0001;
	DCAM_STATUS_READY					= $0002;
	DCAM_STATUS_STABLE					= $0003;
	DCAM_STATUS_UNSTABLE				= $0004 ;

	DCAM_EVENT_FRAMESTART				= $0001;
	DCAM_EVENT_FRAMEEND					= $0002;	// all modules support	*/
	DCAM_EVENT_CYCLEEND					= $0004;	// all modules support	*/
	DCAM_EVENT_VVALIDBEGIN				= $0008 ;

	DCAM_UPDATE_RESOLUTION				= $0001;
	DCAM_UPDATE_AREA					= $0002;
	DCAM_UPDATE_DATATYPE				= $0004;
	DCAM_UPDATE_BITSTYPE				= $0008;
	DCAM_UPDATE_EXPOSURE				= $0010;
	DCAM_UPDATE_TRIGGER					= $0020;
	DCAM_UPDATE_DATARANGE				= $0040;
	DCAM_UPDATE_DATAFRAMEBYTES			= $0080;
	DCAM_UPDATE_PROPERTY				= $0100;
	DCAM_UPDATE_ALL						= $01ff ;

	DCAM_TRIGMODE_INTERNAL				= $0001;
	DCAM_TRIGMODE_EDGE					= $0002;
	DCAM_TRIGMODE_LEVEL					= $0004;
	DCAM_TRIGMODE_MULTISHOT_SENSITIVE	= $0008;
	DCAM_TRIGMODE_CYCLE_DELAY			= $0010;
	DCAM_TRIGMODE_SOFTWARE				= $0020;
	DCAM_TRIGMODE_FASTREPETITION		= $0040;
	DCAM_TRIGMODE_TDI					= $0080;
	DCAM_TRIGMODE_TDIINTERNAL			= $0100;
	DCAM_TRIGMODE_START					= $0200;
	DCAM_TRIGMODE_SYNCREADOUT			= $0400 ;

//** --- trigger polarity --- ***/
	DCAM_TRIGPOL_NEGATIVE				= $0000;
	DCAM_TRIGPOL_POSITIVE				= $0001 ;

//** --- string id --- ***/

   	DCAM_IDSTR_BUS =				$04000101 ;
   	DCAM_IDSTR_CAMERAID =		$04000102 ;
   	DCAM_IDSTR_VENDOR =		$04000103 ;
   	DCAM_IDSTR_MODEL =			$04000104 ;
   	DCAM_IDSTR_CAMERAVERSION =	$04000105 ;
   	DCAM_IDSTR_DRIVERVERSION =	$04000106 ;
   	DCAM_IDSTR_MODULEVERSION =	$04000107 ;
   	DCAM_IDSTR_DCAMAPIVERSION	=$04000108 ;

//*** -- iCmd parameter of dcam_extended = function() -- ***/
  	DCAM_IDMSG_QUERYPARAMCOUNT	= $0200 ;	//*		 DWORD* 		 param,   bytesize = sizeof = function( DWORD );	  */
	  DCAM_IDMSG_SETPARAM 		= $0201 ;	    //* const DCAM_HDR_PARAM* param,   bytesize = sizeof = function( parameters); */
	  DCAM_IDMSG_GETPARAM 		= $0202 ;	    //*		 DCAM_HDR_PARAM* param,   bytesize = sizeof = function( parameters); */
	  DCAM_IDMSG_QUERYPARAMID 	= $0204 ;	  //*		 DWORD			 param[], bytesize = sizeof = function( param);	  */

//*** -- parameter header -- ***/

    dcamparam_feature_featureid = $1 ;
    dcamparam_feature_flags = $2 ;
    dcamparam_feature_featurevalue = $4 ;

    dcamparam_featureinq_featureid = $1 ;
    dcamparam_featureinq_capflags = $2 ;
    dcamparam_featureinq_min = $4;
    dcamparam_featureinq_max = $8 ;
    dcamparam_featureinq_step = $10 ;
    dcamparam_featureinq_defaultvalue = $20 ;
    dcamparam_featureinq_units = $40 ;

//'featureid
    DCAM_IDFEATURE_INITIALIZE = $0 ;
    DCAM_IDFEATURE_BRIGHTNESS = $1 ;
    DCAM_IDFEATURE_GAIN = $2;
    DCAM_IDFEATURE_CONTRAST = $2 ;
    DCAM_IDFEATURE_HUE = $3 ;
    DCAM_IDFEATURE_SATURATION = $4 ;
    DCAM_IDFEATURE_SHARPNESS = $5 ;
    DCAM_IDFEATURE_GAMMA = $6 ;
    DCAM_IDFEATURE_WHITEBALANCE = $7 ;
    DCAM_IDFEATURE_PAN = $8 ;
    DCAM_IDFEATURE_TILT = $9 ;
    DCAM_IDFEATURE_ZOOM = $A ;
    DCAM_IDFEATURE_IRIS = $B ;
    DCAM_IDFEATURE_FOCUS = $C ;
    DCAM_IDFEATURE_AUTOEXPOSURE = $D ;
    DCAM_IDFEATURE_SHUTTER = $E ;
    DCAM_IDFEATURE_EXPOSURETIME = $E ;
    DCAM_IDFEATURE_TEMPERATURE = $F;
    DCAM_IDFEATURE_OPTICALFILTER = $10 ;
    DCAM_IDFEATURE_MECHANICALSHUTTER = $10 ;
    DCAM_IDFEATURE_LIGHTMODE = $11 ;
    DCAM_IDFEATURE_OFFSET = $12 ;
    //DCAM_IDFEATURE_CONTRASTOFFSET   = 0x00000012,
    DCAM_IDFEATURE_CONTRASTGAIN = $13 ;     //'12.03.2003
    DCAM_IDFEATURE_AMPLIFIERGAIN = $14 ;    //'12.03.2003
    DCAM_IDFEATURE_TEMPERATURETARGET = $15 ;//'12.03.2003
    DCAM_IDFEATURE_SENSITIVITY = $16 ;      //'12.03.2003
    DCAM_IDFEATURE_TRIGGERTIMES		= $17  ;  // 4/9/9 JD

//' capflags only
    DCAM_FEATURE_FLAGS_READ_OUT = $10000 ;                   //' Allows the feature values to be read out.
    DCAM_FEATURE_FLAGS_DEFAULT = $20000 ;                    //' Allows DEFAULT function. If supported, when a feature's DEFAULT is turned ON, then
                                                             //   ' the values are ignored and the default setting is used.
    DCAM_FEATURE_FLAGS_STEPPING_INCONSISTENT = $40000 ;      //' step value of DCAM_PARAM_FEATURE_INQ function is not consistent across the
                                                             //   ' entire range of values. For example, if this flag is set, and:
                                                             //   '      min = 0
                                                             //   '      max = 3
                                                             //   '      step = 1
                                                             //   ' Valid values you can set may be 0,1,3 only. 2 is invalid. Therefore,
                                                             //   ' if you implement a scroll bar, Step is the minimum stepping within
                                                             //   ' the range, but a value within the range may be invalid and produce
                                                             //   ' an error. The application should be aware of this case.

//' capflags, flags get, and flags set
   DCAM_FEATURE_FLAGS_AUTO = $1 ;                           //' Auto mode (Controlled automatically by camera).
   DCAM_FEATURE_FLAGS_MANUAL = $2 ;                         //' Manual mode (Controlled by user).
   DCAM_FEATURE_FLAGS_ONE_PUSH = $100000 ;                  //' Capability allows One Push operation. Getting means One Push mode is in progress.
                                                            //    ' Setting One Push flag processes feature values once, then
                                                            //    ' turns off the feature and returns to default settings.

//' flags get and flags set
   DCAM_FEATURE_FLAGS_DEFAULT_OFF = $1000000 ;              //' Enable feature control by turning off DEFAULT. (See DCAM_FEATURE_FLAGS_DEFAULT)
   DCAM_FEATURE_FLAGS_DEFAULT_ON = $2000000 ;               //' Disable feature control and use default. (See DCAM_FEATURE_FLAGS_DEFAULT)

//'From 24.03.2003                                                                ' ** Note: If DEFAULT is ON or you turn DEFAULT ON, you must turn it OFF before
   DCAM_FEATURE_FLAGS_COOLING_ONOFF = $20000 ;                   //' capflags with DCAM_IDFEATURE_TEMPERATURE */
   DCAM_FEATURE_FLAGS_COOLING_ON = $1000000 ;                    //' flags with DCAM_IDFEATURE_TEMPERATURE */
   DCAM_FEATURE_FLAGS_COOLING_OFF = $2000000 ;                   //' flags with DCAM_IDFEATURE_TEMPERATURE */

   DCAM_FEATURE_FLAGS_MECHANICALSHUTTER_OPEN = $2000000 ;        //' flags with DCAM_IDFEATURE_MECHANICALSHUTTER */
   DCAM_FEATURE_FLAGS_MECHANICALSHUTTER_AUTO = $1000001 ;        //' flags with DCAM_IDFEATURE_MECHANICALSHUTTER */
   DCAM_FEATURE_FLAGS_MECHANICALSHUTTER_CLOSE = $1000002 ;       //' flags with DCAM_IDFEATURE_MECHANICALSHUTTER */

   DCAM_FEATURE_FLAGS_OFF = $2000000 ;
   DCAM_FEATURE_FLAGS_ONOFF = $20000 ;
   DCAM_FEATURE_FLAGS_ON = $1000000 ;
                                                                //'          trying to update a new feature value or mode.

// flags set only
   DCAM_FEATURE_FLAGS_IMMEDIATE = $4000000 ;                //' When setting a feature, you request for an immediate change.

   dcamparam_subarray_hpos = $1 ;
   dcamparam_subarray_vpos = $2 ;
   dcamparam_subarray_hsize = $4 ;
   dcamparam_subarray_vsize = $8 ;

   dcamparam_subarrayinq_binning = $1 ;
   dcamparam_subarrayinq_hmax = $2 ;
   dcamparam_subarrayinq_vmax = $4 ;
   dcamparam_subarrayinq_hposunit = $8 ;
   dcamparam_subarrayinq_vposunit = $10 ;
   dcamparam_subarrayinq_hunit = $20 ;
   dcamparam_subarrayinq_vunit = $40 ;

   dcamparam_framereadouttimeinq_framereadouttime = $1 ;

   dcamparam_scanmode_speed	= 1 ;
   dcamparam_scanmode_special	= 2 ;
   dcamparam_scanmode_speed_slowest = $1 ;
   dcamparam_scanmode_speed_fastest = $FF ;         //  ' user specified this value, module may round down

    dcamparam_scanmodeinq_speedmax = $1 ;

    DCAM_IDMSG_SETGETPARAM = $203 ;        //  DCAM_HDR_PARAM* param, bytesize = sizeof( parameters);

    DCAM_IDMSG_SOFTWARE_TRIGGER = $400 ;   //'

//    parameter IDs

    DCAM_IDPARAM_C4742_95 = $C00181E1 ;
    DCAM_IDPARAM_C4742_95_INQ = $800181A1 ;
    DCAM_IDPARAM_C4742_95ER = $C00181E2 ;
    DCAM_IDPARAM_C4742_95ER_INQ = $800181A2 ;
    DCAM_IDPARAM_C7300 = $C00181E3;
    DCAM_IDPARAM_C7300_INQ = $800181A3 ;
    DCAM_IDPARAM_C4880 = $C00181E5 ;
    DCAM_IDPARAM_C4880_INQ = $800181A5 ;
    DCAM_IDPARAM_C8000 = $C00181E6 ;
    DCAM_IDPARAM_C8000_INQ = $800181A6 ;
    DCAM_IDPARAM_C8484 = $C00181E7 ;
    DCAM_IDPARAM_C8484_INQ = $800181A7 ;
    DCAM_IDPARAM_C4742_98BT = $C00181E8 ;
    DCAM_IDPARAM_C4742_98BT_INQ = $800181A8 ;
    DCAM_IDPARAM_C4742_95HR = $C00181E9 ;
    DCAM_IDPARAM_C4742_95HR_INQ = $800181A9 ;
    DCAM_IDPARAM_C7190_2X = $C00181EA ;
    DCAM_IDPARAM_C7190_2X_INQ = $800181AA ;
    DCAM_IDPARAM_C8000_20 = $C00181EB ;
    DCAM_IDPARAM_C8000_20_INQ = $800181AB ;
    DCAM_IDPARAM_C7780 = $C00181EC ;
    DCAM_IDPARAM_C7780_INQ = $800181AC ;
    DCAM_IDPARAM_C4742_98 = $C00281ED ;
    DCAM_IDPARAM_C4742_98_INQ = $800281AD ;
    DCAM_IDPARAM_C4742_98ER = $C00181EE ;
    DCAM_IDPARAM_C4742_98ER_INQ = $800181AE ;
    DCAM_IDPARAM_C7390 = $C00181EF ;
    DCAM_IDPARAM_C7390_INQ = $C00181AF ;
    DCAM_IDPARAM_C8190 = $C00281E1 ;
    DCAM_IDPARAM_C8190_INQ = $C00281A1 ;
    DCAM_IDPARAM_C7190_10 = $C00281E2 ;
    DCAM_IDPARAM_C7190_10_INQ = $800281A2 ;
    DCAM_IDPARAM_C8000_10 = $C00281E3 ;
    DCAM_IDPARAM_C8000_10_INQ = $800281A3 ;
    DCAM_IDPARAM_C4742_95NRK = $C00281E4 ;
    DCAM_IDPARAM_C4742_95NRK_INQ = $800281A4 ;
    DCAM_IDPARAM_C4880_80 = $C00281E5 ;
    DCAM_IDPARAM_C4880_80_INQ = $800281A5 ;
    DCAM_IDPARAM_PCDIG = $C00381E4 ;
    DCAM_IDPARAM_PCDIG_INQ = $800381A4 ;
    DCAM_IDPARAM_ICPCI = $C00381E5 ;
    DCAM_IDPARAM_ICPCI_INQ = $800381A5 ;
    DCAM_IDPARAM_IQV50 = $C00381E6 ;
    DCAM_IDPARAM_IQV50_LUT = $C00381E7 ;
    DCAM_IDPARAM_IQV50_STAT = $800381A8 ;
    DCAM_IDPARAM_MULTI = $C00481E1 ;
    DCAM_IDPARAM_MULTI_INQ = $800481A1 ;
    DCAM_IDPARAM_RGBRATIO = $C00481E2 ;

    DCAM_IDPARAM_FEATURE = $C00001E1 ;
    DCAM_IDPARAM_FEATURE_INQ = $800001A1 ;
    DCAM_IDPARAM_SUBARRAY = $C00001E2 ;
    DCAM_IDPARAM_SUBARRAY_INQ = $800001A2 ;
    DCAM_IDPARAM_FRAME_READOUT_TIME_INQ = $800001A3 ;

    DCAM_IDPARAM_SCANMODE_INQ = $800001A4 ;
    DCAM_IDPARAM_SCANMODE = $C00001E4 ;

     ccDatatype_none = 0 ;
     ccDatatype_uint8 = $1 ;
     ccDatatype_uint16 = $2 ;
     ccDatatype_uint32 = $8 ;
     ccDatatype_int8 = $10 ;
     ccDatatype_int16 = $20 ;
     ccDatatype_int32 = $80 ;
     ccDatatype_real32 = $100 ;
     ccDatatype_real64 = $200 ;
     ccDatatype_rgb8 = $10000 ;
     ccDatatype_rgb16 = $20000 ;
     ccDatatype_rgb24 = $40000 ;       // '? 8bit, [ r0, g0, b0], [r1, g1, b1]
     ccDatatype_rgb32 = $80000 ;
     ccDatatype_rgb48 = $100000 ;

//Bits Type
     ccBitstype_none = $0 ;
     ccBitstype_index8 = $1 ;
     ccBitstype_rgb16 = $2 ;
     ccBitstype_rgb24 = $4 ;               // 8bit, [ b0, g0, r0]
     ccBitstype_rgb32 = $8 ;
     ccBitstype_all = $F ;

//Precapture mode
     ccCapture_Snap = 0 ;
     ccCapture_Sequence = 1 ;

//Error values
     ccErr_none = 0 ;                       // no error
     ccErr_busy = $80000101 ;               // busy, cannot process
     ccErr_abort = $80000102 ;             // abort process
     ccErr_notready = $80000103 ;          // not ready state
     ccErr_notstable = $80000104 ;         // not stable state
     ccErr_timeout = $80000106 ;           // timeout

     ccErr_nomemory = $80000203 ;          // not enough memory

     ccErr_unknownmsgid = $80000801 ;      // unknown message id
     ccErr_unknownstrid = $80000802 ;      // unknown string id
     ccErr_unknownparamid = $80000803 ;    // unkown parameter id
     ccErr_unknownbitstype = $80000804 ;   // unknown transfer type for setbits()
     ccErr_unknowndatatype = $80000805 ;   // unknown transfer type for setdata
     ccErr_invalidhandle = $80000807 ;     // invalid camera handle
     ccErr_invalidparam = $80000808 ;      // invalid parameter

     ccErr_unreach = $80000F01 ;           // reach any point must not to run
     ccErr_notimplement = $80000F02 ;      // not yet implementation
     ccErr_notsupport = $80000F03 ;        // this driver or camera is not support

     ccErr_unstable = $80000105 ;          // now unstable state
     ccErr_noresource = $80000201 ;        // not enough resource without memory and freespace of disk
     ccErr_diskfull = $80000202 ;          // not enough freespace of disk
     ccErr_nomodule = $80000204 ;          // no sub module
     ccErr_nodriver = $80000205 ;          // no driver
     ccErr_nocamera = $80000206 ;          // no camera
     ccErr_unknowncamera = $80000806 ;     // unknown camera
     ccErr_failopen = $80001001 ;
     ccErr_failopenbus = $81001001 ;
     ccErr_failopencamera = $82001001 ;
     ccErr_failreadcamera = $83001002 ;
     ccErr_failwritecamera = $83001003 ;

//   DCAM Properties constants (For DCAM V3 Added by JD 4/9/9)

  	DCAMPROP_OPTION_PRIOR		= $FF000000;	// prior value		*/
	  DCAMPROP_OPTION_NEXT		= $01000000;	// next value or id	*/

	   ///** direction flag for dcam_querypropertyvalue() ***/
	  DCAMPROP_OPTION_NEAREST		= $80000000;	// nearest value	*/	// reserved */

	  ///** option for dcam_getnextpropertyid() ***/
	  DCAMPROP_OPTION_SUPPORT		= $00000000;	// default option */
	  DCAMPROP_OPTION_UPDATED		= $00000001;	// UPDATED and VOLATILE can be used at same time */
	  DCAMPROP_OPTION_VOLATILE	= $00000002;	// UPDATED and VOLATILE can be used at same time */
	  DCAMPROP_OPTION_ARRAYELEMENT= $00000004;	// ARRAYELEMENT */

	  DCAMPROP_OPTION_INFLUENCE	= $00800000;	// INFLUENCE cannot be used with other flag except direction flag */

	  //** for all option parameter ***/
	  DCAMPROP_OPTION_NONE		= $00000000	;//** no option ***/

	// supporting information of DCAM_PROPERTYATTR */
	DCAMPROP_ATTR_HASRANGE		= $80000000;
	DCAMPROP_ATTR_HASSTEP		= $40000000;
	DCAMPROP_ATTR_HASDEFAULT	= $20000000;
	DCAMPROP_ATTR_HASVALUETEXT	= $10000000;

	// property id information */
	DCAMPROP_ATTR_HASCHANNEL	= $08000000;	// value can set the value for each channels */

	// property attribute */
	DCAMPROP_ATTR_AUTOROUNDING	= $00800000;
		// The dcam_setproperty() or dcam_setgetproperty() will failure if this bit exists. */
		// If this flag does not exist; the value will be round up when it is not supported. */
	DCAMPROP_ATTR_STEPPING_INCONSISTENT	= $00400000;
		// The valuestep of DCAM_PROPERTYATTR is not consistent across the entire range of	*/
		// values.																			*/
	DCAMPROP_ATTR_DATASTREAM	= $00200000;	// value is releated to image attribute		*/

	DCAMPROP_ATTR_HASRATIO		= $00100000;	// value has ratio control capability		*/

	DCAMPROP_ATTR_VOLATILE		= $00080000;	// value may be changed by user or automatically */

	DCAMPROP_ATTR_WRITABLE		= $00020000;	// value can be set when state is manual	*/
	DCAMPROP_ATTR_READABLE		= $00010000;	// value is readable when state is manual	*/

	DCAMPROP_ATTR_HASVIEW		= $00008000;	// value can set the value for each views	*/
	DCAMPROP_ATTR__SYSTEM		= $00004000;	// system id								*/	// reserved */

	DCAMPROP_ATTR_ACCESSREADY	= $00002000;	// This value can get or set at READY status */
	DCAMPROP_ATTR_ACCESSBUSY	= $00001000;	// This value can get or set at BUSY status */

	DCAMPROP_ATTR_ADVANCED		= $00000800;	// User has to take care to change this value */// reserved */
	DCAMPROP_ATTR_ACTION		= $00000400;	// writing value takes related effect		*/	// reserved */
	DCAMPROP_ATTR_EFFECTIVE		= $00000200;	// value is effective						*/	// reserved */

	// property value type */
  DCAMPROP_TYPE_NONE			= $00000000;	// undefined 								*/
	DCAMPROP_TYPE_MODE			= $00000001;	// 01:	mode; 32bit integer in case of 32bit OS	*/
	DCAMPROP_TYPE_LONG			= $00000002;	// 02:	32bit integer in case of 32bit OS	*/
	DCAMPROP_TYPE_REAL			= $00000003;	// 03:	64bit float							*/
												//      no 32bit float						*/

  // application has to use double-float type variable even the property is not REAL.	*/

  DCAMPROP_TYPE_MASK			= $0000000F	;// mask for property value type				*/
	// supporting information of DCAM_PROPERTYATTR */
	DCAMPROP_ATTR2_ARRAYBASE	= $08000000;
	DCAMPROP_ATTR2_ARRAYELEMENT	= $04000000;

	DCAMPROP_ATTR2_REAL32		= $02000000 ;

// property information */

	DCAMPROP_UNIT_SECOND		= 1;			// sec */
	DCAMPROP_UNIT_CELSIUS		= 2;			// for sensor temperature */
	DCAMPROP_UNIT_KELVIN		= 3;			// for color temperature */
	DCAMPROP_UNIT_METERPERSECOND= 4;			// for LINESPEED */
	DCAMPROP_UNIT_PERSECOND		= 5;			// for FRAMERATE and LINERATE */
	DCAMPROP_UNIT_NONE			= 0 ;

	// DCAM_IDPROP_SENSORMODE */
	DCAMPROP_SENSORMODE__AREA					= 1;			//	"AREA"					*/
	DCAMPROP_SENSORMODE__SLIT					= 2;			//	"SLIT"					*/	// reserved */
	DCAMPROP_SENSORMODE__LINE					= 3;			//	"LINE"					*/
	DCAMPROP_SENSORMODE__TDI					= 4;			//	"TDI"					*/
	DCAMPROP_SENSORMODE__FRAMING				= 5;			//	"FRAMING"				*/	// reserved */
	DCAMPROP_SENSORMODE__PARTIALAREA			= 6;			//	"PARTIAL AREA"			*/	// reserved */
	DCAMPROP_SENSORMODE__SLITLINE				= 9;			//	"SLIT LINE"				*/

	// DCAM_IDPROP_READOUTSPEED */
	DCAMPROP_READOUTSPEED__SLOWEST				= 1;			//	no text					*/
	DCAMPROP_READOUTSPEED__FASTEST				= $7FFFFFFF;	//	no text;w/o				*/

	// DCAM_IDPROP_READOUT_DIRECTION */
	DCAMPROP_READOUT_DIRECTION__NORMAL			= 1;			//	"NORMAL"				*/
	DCAMPROP_READOUT_DIRECTION__REVERSE			= 2;			//	"REVERSE"				*/

	// DCAM_IDPROP_READOUT_UNIT */
//	DCAMPROP_READOUT_UNIT__LINE					= 1;	*/		//	"LINE"					*/	// reserved */
	DCAMPROP_READOUT_UNIT__FRAME				= 2;			//	"FRAME"					*/
	DCAMPROP_READOUT_UNIT__BUNDLEDLINE			= 3;			//	"BUNDLED LINE"			*/
	DCAMPROP_READOUT_UNIT__BUNDLEDFRAME			= 4;			//	"BUNDLED FRAME"			*/

	// DCAM_IDPROP_CCDMODE */
	DCAMPROP_CCDMODE__NORMALCCD					= 1;			//	"NORMAL CCD"			*/
	DCAMPROP_CCDMODE__EMCCD						= 2;			//	"EM CCD"				*/

	// DCAM_IDPROP_OUTPUT_INTENSITY		 */
	DCAMPROP_OUTPUT_INTENSITY__NORMAL			= 1;			//	"NORMAL"				*/
	DCAMPROP_OUTPUT_INTENSITY__TESTPATTERN		= 2;			//	"TEST PATTERN"			*/

	// DCAM_IDPROP_TESTPATTERN_KIND		 */
	DCAMPROP_TESTPATTERN_KIND__FLAT				= 2;			// "FLAT"					*/
	DCAMPROP_TESTPATTERN_KIND__HORZGRADATION	= 4;			// "HORZGRADATION"			*/
	DCAMPROP_TESTPATTERN_KIND__IHORZGRADATION	= 5;			// "INVERT HORZGRADATION"	*/
	DCAMPROP_TESTPATTERN_KIND__VERTGRADATION	= 6;			// "VERTGRADATION"			*/
	DCAMPROP_TESTPATTERN_KIND__IVERTGRADATION	= 7;			// "INVERT VERTGRADATION"	*/
	DCAMPROP_TESTPATTERN_KIND__LINE				= 8;			// "LINE"					*/
	DCAMPROP_TESTPATTERN_KIND__DIAGONAL			= 10;			// "DIAGONAL"				*/

	// DCAM_IDPROP_DIGITALBINNING_METHOD */
	DCAMPROP_DIGITALBINNING_METHOD__MINIMUM		= 1;			//	"MINIMUM"				*/
	DCAMPROP_DIGITALBINNING_METHOD__MAXIMUM		= 2;			//	"MAXIMUM"				*/
	DCAMPROP_DIGITALBINNING_METHOD__ODD			= 3;			//	"ODD"					*/
	DCAMPROP_DIGITALBINNING_METHOD__EVEN		= 4;			//	"EVEN"					*/
	DCAMPROP_DIGITALBINNING_METHOD__SUM			= 5;			//	"SUM"					*/
	DCAMPROP_DIGITALBINNING_METHOD__AVERAGE		= 6;			//	"AVERAGE"				*/

	// DCAM_IDPROP_TRIGGERSOURCE */
	DCAMPROP_TRIGGERSOURCE__INTERNAL			= 1;			//	"INTERNAL"				*/
	DCAMPROP_TRIGGERSOURCE__EXTERNAL			= 2;			//	"EXTERNAL"				*/
	DCAMPROP_TRIGGERSOURCE__SOFTWARE			= 3;			//	"SOFTWARE"				*/

	// DCAM_IDPROP_TRIGGERACTIVE */
	DCAMPROP_TRIGGERACTIVE__EDGE				= 1;			//	"EDGE"					*/
	DCAMPROP_TRIGGERACTIVE__LEVEL				= 2;			//	"LEVEL"					*/
	DCAMPROP_TRIGGERACTIVE__SYNCREADOUT			= 3;			//	"SYNCREADOUT"			*/
	DCAMPROP_TRIGGERACTIVE__POINT				= 4;			//	"POINT"					*/

	// DCAM_IDPROP_BUS_SPEED */
	DCAMPROP_BUS_SPEED__SLOWEST					= 1;			//	no text					*/
	DCAMPROP_BUS_SPEED__FASTEST					= $7FFFFFFF;	//	no text;w/o				*/

	// DCAM_IDPROP_TRIGGER_MODE */
	DCAMPROP_TRIGGER_MODE__NORMAL				= 1;			//	"NORMAL"				*/
											//	= 2;	*/
	DCAMPROP_TRIGGER_MODE__PIV					= 3;			//	"PIV"					*/
	DCAMPROP_TRIGGER_MODE__START				= 6;			//	"START"					*/

	// DCAM_IDPROP_TRIGGERPOLARITY */
	DCAMPROP_TRIGGERPOLARITY__NEGATIVE			= 1;			//	"NEGATIVE"				*/
	DCAMPROP_TRIGGERPOLARITY__POSITIVE			= 2;			//	"POSITIVE"				*/

	// DCAM_IDPROP_TRIGGER_CONNECTOR */
	DCAMPROP_TRIGGER_CONNECTOR__INTERFACE		= 1;			//	"INTERFACE"				*/
	DCAMPROP_TRIGGER_CONNECTOR__BNC				= 2;			//	"BNC"					*/
	DCAMPROP_TRIGGER_CONNECTOR__MULTI			= 3;			//	"MULTI"					*/

	// DCAM_IDPROP_TRIGGER_MULTICONNECTORTYPE */												// reserved */
//	DCAMPROP_TRIGGER_MULTICONNECTORTYPE__DSUB	= 1;	*/		//	"D-SUB"					*/	// reserved */
//	DCAMPROP_TRIGGER_MULTICONNECTORTYPE__MINI6	= 2;	*/		//	"MINI6"					*/	// reserved */

	// DCAM_IDPROP_TRIGGERENABLE_ACTIVE */
	DCAMPROP_TRIGGERENABLE_ACTIVE__DENY			= 1;			//	"DENY"					*/
	DCAMPROP_TRIGGERENABLE_ACTIVE__ALWAYS		= 2;			//	"ALWAYS"				*/
	DCAMPROP_TRIGGERENABLE_ACTIVE__LEVEL		= 3;			//	"LEVEL"					*/
	DCAMPROP_TRIGGERENABLE_ACTIVE__START		= 4;			//	"START"					*/

	// DCAM_IDPROP_TRIGGERENABLE_POLARITY */
	DCAMPROP_TRIGGERENABLE_POLARITY__NEGATIVE	= 1;			//	"NEGATIVE"				*/
	DCAMPROP_TRIGGERENABLE_POLARITY__POSITIVE	= 2;			//	"POSITIVE"				*/
	DCAMPROP_TRIGGERENABLE_POLARITY__INTERLOCK	= 3;			//	"INTERLOCK"				*/

	// DCAM_IDPROP_OUTPUTTRIGGER_SOURCE */														// reserved */
//	DCAMPROP_OUTPUTTRIGGER_SOURCE__EXPOSURE		= 1;	*/		//	"EXPOSURE"				*/	// reserved */
//	DCAMPROP_OUTPUTTRIGGER_SOURCE__READOUT		= 2;	*/		//	"READOUT"				*/	// reserved */

	// DCAM_IDPROP_OUTPUTTRIGGER_POLARITY */
	DCAMPROP_OUTPUTTRIGGER_POLARITY__NEGATIVE	= 1;			//	"NEGATIVE"				*/
	DCAMPROP_OUTPUTTRIGGER_POLARITY__POSITIVE	= 2;			//	"POSITIVE"				*/

	// DCAM_IDPROP_OUTPUTTRIGGER_ACTIVE */
	DCAMPROP_OUTPUTTRIGGER_ACTIVE__EDGE			= 1;			//	"EDGE"					*/
	DCAMPROP_OUTPUTTRIGGER_ACTIVE__LEVEL		= 2;			//	"LEVEL"					*/
//	DCAMPROP_OUTPUTTRIGGER_ACTIVE__PULSE		= 3;	*/		//	"PULSE"					*/	// reserved */

	// DCAM_IDPROP_TRIGGER_FIRSTEXPOSURE */
	DCAMPROP_TRIGGER_FIRSTEXPOSURE__NEW			= 1;			//  "NEW"					*/
	DCAMPROP_TRIGGER_FIRSTEXPOSURE__CURRENT		= 2;			//  "CURRENT"				*/

	// DCAM_IDPROP_MECHANICALSHUTTER */
	DCAMPROP_MECHANICALSHUTTER__AUTO			= 1;			//	"AUTO"					*/
	DCAMPROP_MECHANICALSHUTTER__CLOSE			= 2;			//	"CLOSE"					*/
	DCAMPROP_MECHANICALSHUTTER__OPEN			= 3;			//	"OPEN"					*/

	// DCAM_IDPROP_MECHANICALSHUTTER_AUTOMODE */												// reserved */
//	DCAMPROP_MECHANICALSHUTTER_AUTOMODE__OPEN_WHEN_EXPOSURE	= 1;*/	// "OPEN WHEN EXPOSURE"	*/	// reserved */
//	DCAMPROP_MECHANICALSHUTTER_AUTOMODE__CLOSE_WHEN_READOUT	= 2;*/	// "CLOSE WHEN READOUT"	*/	// reserved */

	// DCAM_IDPROP_LIGHTMODE */
	DCAMPROP_LIGHTMODE__LOWLIGHT				= 1;			//	"LOW LIGHT"				*/
	DCAMPROP_LIGHTMODE__HIGHLIGHT				= 2;			//	"HIGH LIGHT"			*/

	// DCAM_IDPROP_SENSITIVITYMODE */
	DCAMPROP_SENSITIVITYMODE__OFF				= 1;			//	"OFF"					*/
	DCAMPROP_SENSITIVITYMODE__ON				= 2;			//	"ON"					*/
	DCAMPROP_SENSITIVITY2_MODE__INTERLOCK		= 3;			//	"INTERLOCK"				*/

	// DCAM_IDPROP_EMGAINWARNING_STATUS */														// *EMGAINPROTECT* */
	DCAMPROP_EMGAINWARNING_STATUS__NORMAL		= 1;			//	"NORMAL"				*/	// *EMGAINPROTECT* */
	DCAMPROP_EMGAINWARNING_STATUS__WARNING		= 2;			//	"WARNING"				*/	// *EMGAINPROTECT* */
	DCAMPROP_EMGAINWARNING_STATUS__PROTECTED	= 3;			//	"PROTECTED"				*/	// *EMGAINPROTECT* */

	// DCAM_IDPROP_PHOTONIMAGINGMODE */
	DCAMPROP_PHOTONIMAGINGMODE__0				= 0;			//	"0"						*/
	DCAMPROP_PHOTONIMAGINGMODE__1				= 1;			//	"1"						*/
	DCAMPROP_PHOTONIMAGINGMODE__2				= 2;			//	"2"						*/
	DCAMPROP_PHOTONIMAGINGMODE__3				= 3;			//	"2"						*/

	// DCAM_IDPROP_SENSORCOOLER */
	DCAMPROP_SENSORCOOLER__OFF					= 1;			//	"OFF"					*/
	DCAMPROP_SENSORCOOLER__ON					= 2;			//	"ON"					*/
//	DCAMPROP_SENSORCOOLER__BEST					= 3;	*/		//	"BEST"					*/	// reserved */
	DCAMPROP_SENSORCOOLER__MAX					= 4;			//	"MAX"					*/

	// DCAM_IDPROP_CONTRAST_CONTROL */															// reserved */
//	DCAMPROP_CONTRAST_CONTROL__OFF				= 1;	*/		//	"OFF"					*/	// reserved */
//	DCAMPROP_CONTRAST_CONTROL__ON				= 2;	*/		//	"ON"					*/	// reserved */
//	DCAMPROP_CONTRAST_CONTROL__FRONTPANEL		= 3;	*/		//	"FRONT PANEL"			*/	// reserved */

	// DCAM_IDPROP_WHITEBALANCEMODE */
	DCAMPROP_WHITEBALANCEMODE__OFF				= 1;			//	"OFF"					*/
	DCAMPROP_WHITEBALANCEMODE__AUTO				= 2;			//	"AUTO"					*/
	DCAMPROP_WHITEBALANCEMODE__TEMPERATURE		= 3;			//	"TEMPERATURE"			*/
	DCAMPROP_WHITEBALANCEMODE__USERPRESET		= 4;			//	"USER PRESET"			*/

	// DCAM_IDPROP_SHADINGCALIB_METHOD */
	DCAMPROP_SHADINGCALIB_METHOD__AVERAGE		= 1;			//	"AVERAGE"				*/
	DCAMPROP_SHADINGCALIB_METHOD__MAXIMUM		= 2;			//	"MAXIMUM"				*/
	DCAMPROP_SHADINGCALIB_METHOD__USETARGET		= 3;			//	"USE TARGET"			*/

	// DCAM_IDPROP_CAPTUREMODE */
	DCAMPROP_CAPTUREMODE__NORMAL				= 1;			//	"NORMAL"				*/
	DCAMPROP_CAPTUREMODE__DARKCALIB				= 2;			//	"DARK CALIBRATION"		*/
	DCAMPROP_CAPTUREMODE__SHADINGCALIB			= 3;			//	"SHADING CALIBRATION"	*/
	DCAMPROP_CAPTUREMODE__TAPGAINCALIB			= 4;			//	"TAP GAIN CALIBRATION"	*/

	// DCAM_IDPROP_TAPGAINCALIB_METHOD */
	DCAMPROP_TAPGAINCALIB_METHOD__AVE			= 1;			//	"AVERAGE"				*/
	DCAMPROP_TAPGAINCALIB_METHOD__MAX			= 2;			//	"MAXIMUM"				*/
	DCAMPROP_TAPGAINCALIB_METHOD__MIN			= 3;			//	"MINIMUM"				*/

	// DCAM_IDPROP_RECURSIVEFILTERFRAMES */
	DCAMPROP_RECURSIVEFILTERFRAMES__2			= 2;			//	"2 FRAMES"				*/
	DCAMPROP_RECURSIVEFILTERFRAMES__4			= 4;			//	"4 FRAMES"				*/
	DCAMPROP_RECURSIVEFILTERFRAMES__8			= 8;			//	"8 FRAMES"				*/
	DCAMPROP_RECURSIVEFILTERFRAMES__16			= 16;			//	"16 FRAMES"				*/

	// DCAM_IDPROP_BINNING */
	DCAMPROP_BINNING__1							= 1;			//	"1X1"					*/
	DCAMPROP_BINNING__2							= 2;			//	"2X2"					*/
	DCAMPROP_BINNING__4							= 4;			//	"4X4"					*/
	DCAMPROP_BINNING__8							= 8;			//	"8X8"					*/
	DCAMPROP_BINNING__16						= 16;			//	"16X16"					*/

	// DCAM_IDPROP_COLORTYPE */
	DCAMPROP_COLORTYPE__BW						= $00000001;	//	"BW"					*/
	DCAMPROP_COLORTYPE__RGB						= $00000002;	//	"RGB"					*/
	DCAMPROP_COLORTYPE__BGR						= $00000003;	//	"BGR"					*/
												// other values are resereved */

	// DCAM_IDPROP_BITSPERCHANNEL */
	DCAMPROP_BITSPERCHANNEL__8					= 8;			//	"8BIT"					*/
	DCAMPROP_BITSPERCHANNEL__10					= 10;			//	"10BIT"					*/
	DCAMPROP_BITSPERCHANNEL__12					= 12;			//	"12BIT"					*/
	DCAMPROP_BITSPERCHANNEL__14					= 14;			//	"14BIT"					*/
	DCAMPROP_BITSPERCHANNEL__16					= 16;			//	"16BIT"					*/

	// DCAM_IDPROP_DEFECTCORRECT_METHOD */
	DCAMPROP_DEFECTCORRECT_METHOD__CEILING			= 3;			//	"CEILING"				*/
	DCAMPROP_DEFECTCORRECT_METHOD__PREVIOUS			= 4;			//	"PREVIOUS"				*/

	// DCAM_IDPROP_DEVICEBUFFER_MODE */															// reserved */
	DCAMPROP_DEVICEBUFFER_MODE__THRU			= 1;			//  "THRU"					*/	// reserved */
	DCAMPROP_DEVICEBUFFER_MODE__SNAPSHOT		= 2;			//  "SNAPSHOT"				*/	// reserved */
	DCAMPROP_DEVICEBUFFER_MODE__ROUNDROBIN		= 3;			//  "ROUNDROBIN"			*/	// reserved */

	// DCAM_IDPROP_SYSTEM_ALIVE */
	DCAMPROP_SYSTEM_ALIVE__OFFLINE				= 1;			//	"OFFLINE"				*/
	DCAMPROP_SYSTEM_ALIVE__ONLINE				= 2;			//	"ONLINE"				*/

	// DCAM_IDPROP_TIMESTAMP_MODE */
	DCAMPROP_TIMESTAMP_MODE__NONE				= 1;			//	"NONE"					*/
	DCAMPROP_TIMESTAMP_MODE__LINEBEFORELEFT		= 2;			//	"LINE BEFORE LEFT"		*/
	DCAMPROP_TIMESTAMP_MODE__LINEOVERWRITELEFT	= 3;			//	"LINE OVERWRITE LEFT"	*/
	DCAMPROP_TIMESTAMP_MODE__AREABEFORELEFT		= 4;			//	"AREA BEFORE LEFT"		*/
	DCAMPROP_TIMESTAMP_MODE__AREAOVERWRITELEFT	= 5;			//	"AREA OVERWRITE LEFT"	*/

	// DCAM_IDPROP_PACECONTROL_MODE */
	DCAMPROP_PACECONTROL_MODE__OFF				= 1;			// "OFF"					*/
	DCAMPROP_PACECONTROL_MODE__INTERVAL			= 2;			// "INTERVAL"				*/
	DCAMPROP_PACECONTROL_MODE__THINNING			= 3;			// "THINNING"				*/

	// DCAM_IDPROP_TIMING_EXPOSURE */
	DCAMPROP_TIMING_EXPOSURE__AFTERREADOUT		= 1;			//	"AFTER READOUT"			*/
	DCAMPROP_TIMING_EXPOSURE__OVERLAPREADOUT	= 2;			//	"OVERLAP READOUT"		*/
	DCAMPROP_TIMING_EXPOSURE__ROLLING			= 3;			//	"ROLLING"				*/
	DCAMPROP_TIMING_EXPOSURE__ALWAYS			= 4;			//	"ALWAYS"				*/

	// DCAM_IDPROP_CAMERASTATUS_INTENSITY */
	DCAMPROP_CAMERASTATUS_INTENSITY__GOOD		= 1;			// "GOOD" */
	DCAMPROP_CAMERASTATUS_INTENSITY__TOODARK	= 2;			// "TOO DRAK" */
	DCAMPROP_CAMERASTATUS_INTENSITY__TOOBRIGHT	= 3;			// "TOO BRIGHT" */
	DCAMPROP_CAMERASTATUS_INTENSITY__UNCARE		= 4;			// "UNCARE" */

	// DCAM_IDPROP_CAMERASTATUS_INPUTTRIGGER */
	DCAMPROP_CAMERASTATUS_INPUTTRIGGER__GOOD		= 1;		// "GOOD" */
	DCAMPROP_CAMERASTATUS_INPUTTRIGGER__NONE		= 2;		// "NONE" */
	DCAMPROP_CAMERASTATUS_INPUTTRIGGER__TOOFREQUENT	= 3;		// "TOO FREQUENT" */

	// DCAM_IDPROP_CAMERASTATUS_CALIBRATION */
	DCAMPROP_CAMERASTATUS_CALIBRATION__DONE					= 1;	// "DONE" */
	DCAMPROP_CAMERASTATUS_CALIBRATION__NOTYET				= 2;	// "NOT YET" */
	DCAMPROP_CAMERASTATUS_CALIBRATION__NOTRIGGER			= 3;	// "NO TRIGGER" */
	DCAMPROP_CAMERASTATUS_CALIBRATION__TOOFREQUENTTRIGGER		= 4;	// "TOO FREQUENT TRIGGER" */
	DCAMPROP_CAMERASTATUS_CALIBRATION__OUTOFADJUSTABLERANGE	= 5;	// "OUT OF ADJUSTABLE RANGE" */
	DCAMPROP_CAMERASTATUS_CALIBRATION__UNSUITABLETABLE		= 6;	// "UNSUITABLE TABLE" */

	//-- for general purpose --*/
	DCAMPROP_MODE__OFF							= 1;			//	"OFF"					*/
	DCAMPROP_MODE__ON							= 2;			//	"ON"					*/

	//-- for backward compativilities --*/

	DCAMPROP_SCAN_MODE__NORMAL			= DCAMPROP_SENSORMODE__AREA;
	DCAMPROP_SCAN_MODE__SLIT			= DCAMPROP_SENSORMODE__SLIT;

	DCAMPROP_SWITCHMODE_OFF				= DCAMPROP_MODE__OFF;	//	"OFF"					*/
	DCAMPROP_SWITCHMODE_ON				= DCAMPROP_MODE__ON;	//	"ON"					*/

	DCAMPROP_TRIGGERACTIVE__PULSE		= DCAMPROP_TRIGGERACTIVE__SYNCREADOUT;		//	was "PULSE"	*/

	//-- miss spelling --*/
	DCAMPROP_TRIGGERSOURCE__EXERNAL		= DCAMPROP_TRIGGERSOURCE__EXTERNAL ;

// **************************************************************** *
//	property ids


  //	  $00000000 - $00100000; reserved						*/

// Group: TIMING */
	DCAM_IDPROP_TRIGGERSOURCE					= $00100110;	// R/W; mode;	"TRIGGER SOURCE"		*/
	DCAM_IDPROP_TRIGGERACTIVE					= $00100120;	// R/W; mode;	"TRIGGER ACTIVE"		*/
	DCAM_IDPROP_TRIGGER_MODE					= $00100210;	// R/W; mode;	"TRIGGER MODE"			*/
	DCAM_IDPROP_TRIGGERPOLARITY					= $00100220;	// R/W; mode;	"TRIGGER POLARITY"		*/
	DCAM_IDPROP_TRIGGER_CONNECTOR				= $00100230;	// R/W; mode;	"TRIGGER CONNECTOR"		*/
	DCAM_IDPROP_TRIGGERTIMES					= $00100240;	// R/W; long;	"TRIGGER TIMES"			*/
          											//	  $00100250 is reserved */
	DCAM_IDPROP_TRIGGERDELAY					= $00100260;	// R/W; sec;	"TRIGGER DELAY"			*/

	DCAM_IDPROP_TRIGGERENABLE_ACTIVE			= $00100410;	// R/W; mode;	"TRIGGER ENABLE ACTIVE"	*/
	DCAM_IDPROP_TRIGGERENABLE_POLARITY			= $00100420;	// R/W; mode;	"TRIGGER ENABLE POLARITY" */

	DCAM_IDPROP_GATING_MODE						= $00101110;	// R/W; mode;	"GATING MODE"			*/	// reserved */

	DCAM_IDPROP_BUS_SPEED						= $00180110;	// R/W; long;	"BUS SPEED"				*/

//	DCAM_IDPROP_OUTPUTTRIGGER_SOURCE			= $001C0110;*/	// R/W; mode;	"OUTPUT TRIGGER SOURCE"	*/	// reserved */
	DCAM_IDPROP_OUTPUTTRIGGER_POLARITY			= $001C0120;	// R/W; mode;	"OUTPUT TRIGGER POLARITY" */
	DCAM_IDPROP_OUTPUTTRIGGER_ACTIVE			= $001C0130;	// R/W; mode;	"OUTPUT TRIGGER ACTIVE"	*/
	DCAM_IDPROP_OUTPUTTRIGGER_DELAY				= $001C0140;	// R/W; sec;	"OUTPUT TRIGGER DELAY"	*/
	DCAM_IDPROP_OUTPUTTRIGGER_PERIOD			= $001C0150;	// R/W; sec;	"OUTPUT TRIGGER PERIOD"	*/

// Group: FEATURE */
	// exposure period */
	DCAM_IDPROP_EXPOSURETIME					= $001F0110;	// R/W; sec;	"EXPOSURE TIME"			*/
	DCAM_IDPROP_TRIGGER_FIRSTEXPOSURE			= $001F0200;	// R/W; mode;	"TRIGGER FIRST EXPOSURE" */

	// anti-blooming */
	DCAM_IDPROP_LIGHTMODE						= $00200110;	// R/W; mode;	"LIGHT MODE"			*/
											//	  $00200120 is reserved */

	// sensitivity */
	DCAM_IDPROP_SENSITIVITYMODE					= $00200210;	// R/W; mode;	"SENSITIVITY MODE"		*/
	DCAM_IDPROP_SENSITIVITY						= $00200220;	// R/W; long;	"SENSITIVITY"			*/
	DCAM_IDPROP_SENSITIVITY2_MODE				= $00200230;	// R/W; mode;	"SENSITIVITY2 MODE"		*/	// reserved */
	DCAM_IDPROP_SENSITIVITY2					= $00200240;	// R/W; long;	"SENSITIVITY2"			*/

	DCAM_IDPROP_DIRECTEMGAIN_MODE				= $00200250;	// R/W; mode;	"DIRECT EM GAIN MODE"	*/	// *DIRECTEMGAIN* */
	DCAM_IDPROP_EMGAINWARNING_STATUS			= $00200260;	// R/O; mode;	"EM GAIN WARNING STATUS"*/	// *EMGAINPROTECT* */
	DCAM_IDPROP_EMGAINWARNING_LEVEL				= $00200270;	// R/W; long;	"EM GAIN WARNING LEVEL"	*/	// *EMGAINPROTECT* */
	DCAM_IDPROP_EMGAINWARNING_ALARM				= $00200280;	// R/W; mode;	"EM GAIN WARNING ALARM"	*/	// *EMGAINPROTECT* */
	DCAM_IDPROP_EMGAINPROTECT_MODE				= $00200290;	// R/W; mode;	"EM GAIN PROTECT MODE"	*/	// *EMGAINPROTECT* */
	DCAM_IDPROP_EMGAINPROTECT_AFTERFRAMES		= $002002A0;	// R/W; long;	"EM GAIN PROTECT AFTER FRAMES"	*/	// *EMGAINPROTECT* */

	DCAM_IDPROP_PHOTONIMAGINGMODE				= $002002F0;	// R/W; mode;	"PHOTON IMAGING MODE"	*/

	// sensor cooler */
	DCAM_IDPROP_SENSORTEMPERATURE				= $00200310;	// R/O; celsius;"SENSOR TEMPERATURE"	*/
	DCAM_IDPROP_SENSORCOOLER					= $00200320;	// R/W; mode;	"SENSOR COOLER"			*/
	DCAM_IDPROP_SENSORTEMPERATURETARGET			= $00200330;	// R/W; celsius;"SENSOR TEMPERATURE TARGET"	*/
	DCAM_IDPROP_SENSORCOOLERFAN					= $00200350;	// R/W; mode;	"SENSOR COOLER FAN"		*/

	// mechanical shutter */
	DCAM_IDPROP_MECHANICALSHUTTER				= $00200410;	// R/W; mode;	"MECHANICAL SHUTTER"	*/
//	DCAM_IDPROP_MECHANICALSHUTTER_AUTOMODE		= $00200420;*/	// R/W; mode;	"MECHANICAL SHUTTER AUTOMODE"	*/	// reserved */

	// contrast enhance */
//	DCAM_IDPROP_CONTRAST_CONTROL				= $00300110;*/	// R/W; mode;	"CONTRAST CONTROL"		*/	// reserved */
	DCAM_IDPROP_CONTRASTGAIN					= $00300120;	// R/W; long;	"CONTRAST GAIN"			*/
	DCAM_IDPROP_CONTRASTOFFSET					= $00300130;	// R/W; long;	"CONTRAST OFFSET"		*/
											//	  $00300140 is reserved */
	DCAM_IDPROP_HIGHDYNAMICRANGE_MODE			= $00300150;	// R/W; mode;	"HIGH DYNAMIC RANGE MODE"	*/

	// color features */
	DCAM_IDPROP_WHITEBALANCEMODE				= $00300210;	// R/W; mode;	"WHITEBALANCE MODE"		*/
	DCAM_IDPROP_WHITEBALANCETEMPERATURE			= $00300220;	// R/W; color-temp.; "WHITEBALANCE TEMPERATURE"	*/
	DCAM_IDPROP_WHITEBALANCEUSERPRESET			= $00300230;	// R/W; long;	"WHITEBALANCE USER PRESET"		*/
											//	  $00300310 is reserved */

// Group: ALU */
	// ALU */
	DCAM_IDPROP_RECURSIVEFILTER					= $00380110;	// R/W; mode;	"RECURSIVE FILTER"		*/
	DCAM_IDPROP_RECURSIVEFILTERFRAMES			= $00380120;	// R/W; long;	"RECURSIVE FILTER FRAMES"*/
	DCAM_IDPROP_SPOTNOISEREDUCER				= $00380130;	// R/W; mode;	"SPOT NOISE REDUCER"	*/
	DCAM_IDPROP_SUBTRACT						= $00380210;	// R/W; mode;	"SUBTRACT"				*/
	DCAM_IDPROP_SUBTRACTIMAGEMEMORY				= $00380220;	// R/W; mode;	"SUBTRACT IMAGE MEMORY"	*/
	DCAM_IDPROP_STORESUBTRACTIMAGETOMEMORY		= $00380230;	// W/O; mode;	"STORE SUBTRACT IMAGE TO MEMORY"	*/
	DCAM_IDPROP_SUBTRACTOFFSET					= $00380240;	// R/W; long	"SUBTRACT OFFSET"		*/
	DCAM_IDPROP_DARKCALIB_MAXIMUMINTENSITY		= $00380250;	// R/W; long;	"DARKCALIB MAXIMUMINTENSITY"	*/
	DCAM_IDPROP_SHADINGCORRECTION				= $00380310;	// R/W; mode;	"SHADING CORRECTION"	*/
	DCAM_IDPROP_SHADINGCALIBDATAMEMORY			= $00380320;	// R/W; mode;	"SHADING CALIB DATA MEMORY"		*/
	DCAM_IDPROP_STORESHADINGCALIBDATATOMEMORY	= $00380330;	// W/O; mode;	"STORE SHADING DATA TO MEMORY"	*/
	DCAM_IDPROP_SHADINGCALIB_METHOD				= $00380340;	// R/W; mode;	"SHADING CALIB METHOD"	*/
	DCAM_IDPROP_SHADINGCALIB_TARGET				= $00380350;	// R/W; long;	"SHADING CALIB TARGET"	*/
	DCAM_IDPROP_SHADINGCALIB_MINIMUMINTENSITY	= $00380360;	// R/W; long;	"SHADING CALIB MINIMUM INTENSITY"	*/
	DCAM_IDPROP_SHADINGCALIB_AVERAGEFRAMECOUNT	= $00380370;	// R/W; long;	"SHADING CALIB AVERAGE FRAME COUNT"	*/
	DCAM_IDPROP_SHADINGCALIB_STABLEFRAMECOUNT	= $00380380;	// R/W; long;	"SHADING CALIB STABLE FRAME COUNT"	*/
	DCAM_IDPROP_SHADINGCALIB_INTENSITYMAXIMUMERRORPERCENTAGE=$00380390;	// R/W; long;	"SHADING CALIB INTENSITY MAXIMUM ERROR RATE"	*/
	DCAM_IDPROP_FRAMEAVERAGINGMODE				= $003803A0;	// R/W; mode;	"FRAME AVERAGING MODE"		*/
	DCAM_IDPROP_FRAMEAVERAGINGFRAMES			= $003803B0;	// R/W; long;	"FRAME AVERAGING FRAMES"*/
	DCAM_IDPROP_CAPTUREMODE						= $00380410;	// R/W; mode;	"CAPTURE MODE"			*/

	// TAP CALIBRATION */
	DCAM_IDPROP_TAPGAINCALIB_METHOD				= $00380F10;	// R/W; mode;	"TAP GAIN CALIB METHOD"	*/
	DCAM_IDPROP_TAPCALIB_BASEDATAMEMORY			= $00380F20;	// R/W; mode;	"TAP CALIB BASE DATA MEMORY" */
	DCAM_IDPROP_STORETAPCALIBDATATOMEMORY		= $00380F30;	// W/O; mode;	"STORE TAP CALIB DATA TO MEMORY" */
	DCAM_IDPROP_TAPCALIBDATAMEMORY				= $00380F40;	// W/O; mode;	"TAP CALIB DATA MEMORY"	*/
	DCAM_IDPROP_NUMBEROF_TAPCALIB				= $00380FF0;	// R/W; long;	"NUMBER OF TAP CALIB"	*/
	DCAM_IDPROP_TAPCALIB_GAIN					= $00381000;	// R/W; mode;	"TAP CALIB GAIN"		*/
	DCAM_IDPROP__TAPCALIB						= $00000010;	// the offset of ID for Nth TAPCALIB	*/

// Group: READOUT */
	// readout speed */
	DCAM_IDPROP_READOUTSPEED					= $00400110;	// R/W; long;	"READOUT SPEED" 		*/
											//	  $00400120 is reserved */
	DCAM_IDPROP_READOUT_DIRECTION				= $00400130;	// R/W; mode;	"READOUT DIRECTION"		*/
	DCAM_IDPROP_READOUT_UNIT					= $00400140;	// R/O; mode;	"READOUT UNIT"			*/

	// sensor mode */
	DCAM_IDPROP_SENSORMODE						= $00400210;	// R/W; mode;	"SENSOR MODE"			*/
	DCAM_IDPROP_SENSORMODE_SLITHEIGHT			= $00400220;	// R/W; long;	"SENSOR MODE SLIT HEIGHT"		*/	// reserved */
	DCAM_IDPROP_SENSORMODE_LINEBUNDLEHEIGHT		= $00400250;	// R/W; long;	"SENSOR MODE LINE BUNDLEHEIGHT"	*/
	DCAM_IDPROP_SENSORMODE_FRAMINGHEIGHT		= $00400260;	// R/W; long;	"SENSOR MODE FRAMING HEIGHT"	*/	// reserved */

	// other readout mode */
	DCAM_IDPROP_CCDMODE							= $00400310;	// R/W; mode;	"CCD MODE"				*/
	DCAM_IDPROP_EMCCD_CALIBRATIONMODE			= $00400320;	// R/W; mode;	"EM CCD CALIBRATION MODE"	*/

	// output mode */
	DCAM_IDPROP_OUTPUT_INTENSITY				= $00400410;	// R/W; mode;	"OUTPUT INTENSITY"		*/

	DCAM_IDPROP_TESTPATTERN_KIND				= $00400510;	// R/W; mode;	"TEST PATTERN KIND"		*/
	DCAM_IDPROP_TESTPATTERN_OPTION				= $00400520;	// R/W; long;	"TEST PATTERN OPTION"	*/

// Group: ROI */
	// binning and subarray */
	DCAM_IDPROP_BINNING							= $00401110;	// R/W; mode;	"BINNING"				*/
	DCAM_IDPROP_BINNING_INDEPENDENT				= $00401120;	// R/W; mode;	"BINNING INDEPENDENT"	*/
	DCAM_IDPROP_BINNING_HORZ					= $00401130;	// R/W; long;	"BINNING HORZ"			*/
	DCAM_IDPROP_BINNING_VERT					= $00401140;	// R/W; long;	"BINNING VERT"			*/
	DCAM_IDPROP_SUBARRAYHPOS					= $00402110;	// R/W; long;	"SUBARRAY HPOS"			*/
	DCAM_IDPROP_SUBARRAYHSIZE					= $00402120;	// R/W; long;	"SUBARRAY HSIZE"		*/
	DCAM_IDPROP_SUBARRAYVPOS					= $00402130;	// R/W; long;	"SUBARRAY VPOS"			*/
	DCAM_IDPROP_SUBARRAYVSIZE					= $00402140;	// R/W; long;	"SUBARRAY VSIZE"		*/
	DCAM_IDPROP_SUBARRAYMODE					= $00402150;	// R/W; mode;	"SUBARRAY MODE"			*/
	DCAM_IDPROP_DIGITALBINNING_METHOD			= $00402160;	// R/W; mode;	"DIGITALBINNING METHOD"	*/
	DCAM_IDPROP_DIGITALBINNING_HORZ				= $00402170;	// R/W; long;	"DIGITALBINNING HORZ"	*/

// Group: TIMING */
	// synchronous timing */
	DCAM_IDPROP_TIMING_READOUTTIME				= $00403010;	// R/O; sec;	"TIMING READOUT TIME"	*/
	DCAM_IDPROP_TIMING_CYCLICTRIGGERPERIOD		= $00403020;	// R/O; sec;	"TIMING CYCLIC TRIGGER PERIOD"	*/
	DCAM_IDPROP_TIMING_MINTRIGGERBLANKING		= $00403030;	// R/O; sec;	"TIMING MINIMUM TRIGGER BLANKING"	*/
											//	  $00403040 is reserved */
	DCAM_IDPROP_TIMING_MINTRIGGERINTERVAL		= $00403050;	// R/O; sec;	"TIMING MINIMUM TRIGGER INTERVAL"	*/
	DCAM_IDPROP_TIMING_EXPOSURE					= $00403060;	// R/O; mode;	"TIMING EXPOSURE"		*/
	DCAM_IDPROP_TIMING_INVALIDEXPOSUREPERIOD		= $00403070;	// R/O; sec;	"INVALID EXPOSURE PERIOD"	*/

	DCAM_IDPROP_INTERNALFRAMERATE				= $00403810;	// R/W; 1/sec;	"INTERNAL FRAME RATE"	*/
	DCAM_IDPROP_INTERNAL_FRAMEINTERVAL			= $00403820;	// R/W; sec;	"INTERNAL FRAME INTERVAL"	*/
	DCAM_IDPROP_INTERNALLINERATE				= $00403830;	// R/W; 1/sec;	"INTERNAL LINE RATE"	*/
	DCAM_IDPROP_INTERNALLINESPEED				= $00403840;	// R/W; m/sec;	"INTERNAL LINE SPEEED"	*/
//	DCAM_IDPROP_INTERNAL_LINEINTERVAL			= $00403850;	// R/W; sec;	"INTERNAL LINE INTERVAL"	*/	// future */

// Group: READOUT */
	// image information */
											//	  $00420110 is reserved */
	DCAM_IDPROP_COLORTYPE						= $00420120;	// R/W; mode;	"COLORTYPE"				*/
	DCAM_IDPROP_BITSPERCHANNEL					= $00420130;	// R/W; long;	"BIT PER CHANNEL"		*/
											//	  $00420140 is reserved */
											//	  $00420150 is reserved */

	DCAM_IDPROP_NUMBEROF_CHANNEL				= $00420180;	// R/O; long;	"NUMBER OF CHANNEL"		*/
	DCAM_IDPROP_ACTIVE_CHANNELINDEXES			= $00420190;	// R/W; mode;	"ACTIVE CHANNEL INDEXES" */
	DCAM_IDPROP_NUMBEROF_VIEW					= $004201C0;	// R/O; long;	"NUMBER OF VIEW"		*/
	DCAM_IDPROP_ACTIVE_VIEWINDEXES				= $004201D0;	// R/W; mode;	"ACTIVE VIEW INDEXES"	*/

	DCAM_IDPROP_IMAGE_WIDTH						= $00420210;	// R/O; long;	"IMAGE WIDTH"			*/
	DCAM_IDPROP_IMAGE_HEIGHT					= $00420220;	// R/O; long;	"IMAGE HEIGHT"			*/
	DCAM_IDPROP_IMAGE_ROWBYTES					= $00420230;	// R/O; long;	"IMAGE ROWBYTES"		*/
	DCAM_IDPROP_IMAGE_FRAMEBYTES				= $00420240;	// R/O; long;	"IMAGE FRAMEBYTES"		*/

	// frame bundle */
	DCAM_IDPROP_FRAMEBUNDLE_MODE				= $00421010;	// R/W; mode;	"FRAMEBUNDLE MODE"		*/
	DCAM_IDPROP_FRAMEBUNDLE_NUMBER				= $00421020;	// R/W; long;	"FRAMEBUNDLE NUMBER"	*/
	DCAM_IDPROP_FRAMEBUNDLE_ROWBYTES			= $00421030;	// R/O;	long;	"FRAMEBUNDLE ROWBYTES"	*/
	DCAM_IDPROP_FRAMEBUNDLE_FRAMESTEPBYTES		= $00421040;	// R/O; long;	"FRAMEBUNDLE FRAME STEP BYTES"	*/

	// partial area */
	DCAM_IDPROP_NUMBEROF_PARTIALAREA			= $00430010;	// R/W; long;	"NUMBER OF PARTIAL AREA" */
	DCAM_IDPROP_PARTIALAREA_HPOS				= $00431000;	// R/W; long;	"PARTIAL AREA HPOS"		*/
	DCAM_IDPROP_PARTIALAREA_HSIZE				= $00432000;	// R/W; long;	"PARTIAL AREA HSIZE"	*/
	DCAM_IDPROP_PARTIALAREA_VPOS				= $00433000;	// R/W; long;	"PARTIAL AREA VPOS"		*/
	DCAM_IDPROP_PARTIALAREA_VSIZE				= $00434000;	// R/W; long;	"PARTIAL AREA VSIZE"	*/
	DCAM_IDPROP__PARTIALAREA					= $00000010;	// the offset of ID for Nth PARTIAL AREA */

	// multi line */
	DCAM_IDPROP_NUMBEROF_MULTILINE				= $0044F010;	// R/W; long;	"NUMBER OF MULTI LINE" */
	DCAM_IDPROP_MULTILINE_VPOS					= $00450000;	// R/W; long;	"MULTI LINE VPOS"		*/
	DCAM_IDPROP_MULTILINE_VSIZE					= $00460000;	// R/W; long;	"MULTI LINE VSIZE"		*/
											//				 - $0046FFFF for 4096 MULTI LINEs			*/		// reserved */
	DCAM_IDPROP__MULTILINE						= $00000010;	// the offset of ID for Nth MULTI LINE */

	// defect */
	DCAM_IDPROP_DEFECTCORRECT_MODE				= $00470010;	// R/W; mode;	"DEFECT CORRECT MODE"	*/
	DCAM_IDPROP_NUMBEROF_DEFECTCORRECT			= $00470020;	// R/W; long;	"NUMBER OF DEFECT CORRECT"	*/
	DCAM_IDPROP_DEFECTCORRECT_HPOS				= $00471000;	// R/W; long;	"DEFECT CORRECT HPOS"		*/
	DCAM_IDPROP_DEFECTCORRECT_METHOD			= $00473000;	// R/W; mode;	"DEFECT CORRECT METHOD"		*/
											//				 - $0047FFFF for 256 DEFECT */
	DCAM_IDPROP__DEFECTCORRECT					= $00000010;	// the offset of ID for Nth DEFECT */

// Group: REGION */																												// reserved */
	DCAM_IDPROP_REGION_MODE						= $00402310;	// R/W; mode;	"REGION MODE"			*/						// reserved */
	DCAM_IDPROP_NUMBEROF_REGION					= $00402320;	// R/W; long;	"NUMBER OF REGION"		*/						// reserved */
	DCAM_IDPROP_REGION_HPOS						= $00480000;	// R/W; long;	"REGION HPOS"			*/						// reserved */
	DCAM_IDPROP_REGION_HSIZE					= $00481000;	// R/W; long;	"REGION HSIZE"			*/						// reserved */
	DCAM_IDPROP_REGION_VPOS						= $00482000;	// R/W; long;	"REGION VPOS"			*/						// reserved */
	DCAM_IDPROP_REGION_VSIZE					= $00483000;	// R/W; long;	"REGION VSIZE"			*/						// reserved */
											//				 - $0048FFFF for 256 REGIONs at least		*/						// reserved */
	DCAM_IDPROP__REGION							= $00000010;	// the offset of ID for Nth REGION		*/						// reserved */

// Group: buffer countrol? */																					// reserved */
	DCAM_IDPROP_DEVICEBUFFER_MODE				= $00490000;	// R/W; mode;	"DEVICE BUFFER MODE"	*/		// reserved */
	DCAM_IDPROP_DEVICEBUFFER_COUNT				= $00490010;	// R/W; long;	"DEVICE BUFFER COUNT"	*/		// reserved */

// Group: PACE CONTROL */
	DCAM_IDPROP_PACECONTROL_MODE				= $004A0110;	// R/W; mode;	"PACE CONTROL MODE"		*/
	DCAM_IDPROP_NUMBEROF_PACECONTROL			= $004A0120;	// R/W; long;	"NUMBER OF PACE CONTROL"*/
	DCAM_IDPROP_PACECONTROL_COUNT				= $004A1000;	// R/W; long;	"PACE CONTROL COUNT"	*/
	DCAM_IDPROP_PACECONTROL_INTERVAL			= $004A2000;	// R/W; real;	"PACE CONTROL INTERVAL"	*/
											//				 - $004AFFFF for 256 DEFECT; reserved		*/
	DCAM_IDPROP__PACECONTROL					= $00000010;	// the offset of ID for Nth PACECONTROL	*/

// Group: CALIBREGION */
	DCAM_IDPROP_CALIBREGION_MODE				= $00402410;	// R/W; mode;	"CALIBRATE REGION MODE"			*/
	DCAM_IDPROP_NUMBEROF_CALIBREGION			= $00402420;	// R/W; long;	"NUMBER OF CALIBRATE REGION"		*/
	DCAM_IDPROP_CALIBREGION_HPOS				= $004B0000;	// R/W; long;	"CALIBRATE REGION HPOS"			*/
	DCAM_IDPROP_CALIBREGION_HSIZE				= $004B1000;	// R/W; long;	"CALIBRATE REGION HSIZE"			*/
											//				 - $0048FFFF for 256 REGIONs at least		*/
	DCAM_IDPROP__CALIBREGION					= $00000010;	// the offset of ID for Nth REGION		*/

// Group: MASKREGION */
	DCAM_IDPROP_MASKREGION_MODE					= $00402510;	// R/W; mode;	"MASK REGION MODE"			*/
	DCAM_IDPROP_NUMBEROF_MASKREGION				= $00402520;	// R/W; long;	"NUMBER OF MASK REGION"		*/
	DCAM_IDPROP_MASKREGION_HPOS					= $004C0000;	// R/W; long;	"MASK REGION HPOS"			*/
	DCAM_IDPROP_MASKREGION_HSIZE				= $004C1000;	// R/W; long;	"MASK REGION HSIZE"			*/
											//				 - $0048FFFF for 256 REGIONs at least		*/
	DCAM_IDPROP__MASKREGION						= $00000010;	// the offset of ID for Nth REGION		*/

											//	  $00C00000 - $00EFFFFF; reserved						*/

// Group: Camera Status */
	DCAM_IDPROP_CAMERASTATUS_INTENSITY			= $004D1110;	// R/O; mode;	"CAMERASTATUS INTENSITY" */
	DCAM_IDPROP_CAMERASTATUS_INPUTTRIGGER		= $004D1120;	// R/O; mode;	"CAMERASTATUS INPUT TRIGGER" */
	DCAM_IDPROP_CAMERASTATUS_CALIBRATION		= $004D1130;	// R/O; mode;	"CAMERASTATUS CALIBRATION" */

// Group: SYSTEM */
	// system property */

	DCAM_IDPROP_SYSTEM_ALIVE					= $00FF0010;	// R/O; mode;	"SYSTEM ALIVE"			*/
	DCAM_IDPROP_TIMESTAMP_MODE					= $00FF0060;	// r/w; mode;	"TIME STAMP MODE"		*/

	// option */
	DCAM_IDPROP__RATIO				= $80000000;
	DCAM_IDPROP_EXPOSURETIME_RATIO	= DCAM_IDPROP__RATIO or DCAM_IDPROP_EXPOSURETIME;						// reserved */
													// R/W; real;	"EXPOSURE TIME RATIO"	*/				// reserved */
	DCAM_IDPROP_CONTRASTGAIN_RATIO	= DCAM_IDPROP__RATIO or DCAM_IDPROP_CONTRASTGAIN;						// reserved */
													// R/W; real;	"CONTRAST GAIN RATIO"	*/				// reserved */

	DCAM_IDPROP__CHANNEL			= $00000001;
	DCAM_IDPROP__VIEW				= $01000000;

	DCAM_IDPROP__MASK_CHANNEL		= $0000000F;
	DCAM_IDPROP__MASK_VIEW			= $0F000000;
	DCAM_IDPROP__MASK_BODY			= $00FFFFF0;

	//-- for backward compativilities --*/
	DCAMPROP_ATTR_REMOTE_VALUE		= DCAMPROP_ATTR_VOLATILE;

	DCAMPROP_PHOTONIMAGING_MODE__0	= DCAMPROP_PHOTONIMAGINGMODE__0;
	DCAMPROP_PHOTONIMAGING_MODE__1	= DCAMPROP_PHOTONIMAGINGMODE__1;
	DCAMPROP_PHOTONIMAGING_MODE__2	= DCAMPROP_PHOTONIMAGINGMODE__2;

	DCAM_IDPROP_SCAN_MODE			= DCAM_IDPROP_SENSORMODE;
	DCAM_IDPROP_SLITSCAN_HEIGHT		= DCAM_IDPROP_SENSORMODE_SLITHEIGHT;

	DCAM_IDPROP_FRAME_BUNDLEMODE	= DCAM_IDPROP_FRAMEBUNDLE_MODE;
	DCAM_IDPROP_FRAME_BUNDLENUMBER	= DCAM_IDPROP_FRAMEBUNDLE_NUMBER;
	DCAM_IDPROP_FRAME_BUNDLEROWBYTES= DCAM_IDPROP_FRAMEBUNDLE_ROWBYTES;

	DCAM_IDPROP_ACTIVE_VIEW			= DCAM_IDPROP_ACTIVE_VIEWINDEXES;
//	DCAM_IDPROP_SYNC_FRAMEREADOUTTIME=DCAM_IDPROP_TIMING_READOUTTIME;				*/	// reserved */
//	DCAM_IDPROP_SYNC_CYCLICTRIGGERPERIOD = DCAM_IDPROP_TIMING_CYCLICTRIGGERPERIOD;	*/	// reserved */
	DCAM_IDPROP_SYNC_MINTRIGGERBLANKING	= DCAM_IDPROP_TIMING_MINTRIGGERBLANKING;
	DCAM_IDPROP_SYNC_FRAMEINTERVAL	= DCAM_IDPROP_INTERNAL_FRAMEINTERVAL;
	DCAM_IDPROP_LOWLIGHTSENSITIVITY	= DCAM_IDPROP_PHOTONIMAGINGMODE;




//* **************************************************************** *
//	functions
// * **************************************************************** */

//*** --- error function --- ***/
type

TDCAMAPISession = record
     CamHandle : Integer ;
     NumCameras : Integer ;
     CameraModel : String ;
     NumBytesPerFrame : Integer ;     // No. of bytes in image
     NumPixelsPerFrame : Integer ;    // No. of pixels in image
     FramePointers : Array[0..9999] of Pointer ;
     NumFrames : Integer ;            // No. of images in circular transfer buffer
     FrameNum : Integer ;             // Current frame no.
     PFrameBuffer : Pointer ;         // Frame buffer pointer
     ImageBufferSize : Integer ;           // No. images in Andor image buffer
     PImageBuffer : PIntegerArray ;        // Local Andor image buffer
     NumFramesAcquired : Integer ;
     NumFramesCopied : Integer ;
     GetImageInUse : Boolean ;       // GetImage procedure running
     CapturingImages : Boolean ;     // Image capture in progress
     CameraOpen : Boolean ;          // Camera open for use
     TimeStart : single ;
     Temperature : Integer ;
     FrameTransferTime : Single ;    // Frame transfer time (s)
     NumFeatures : Cardinal ;
     FeatureID : Array[0..31] of Cardinal ;
     BinFactors : Array[0..9] of Integer ;
     NumBinFactors : Integer ;
     Gains : Array[0..999] of Single ;
     NumGains : Integer ;
     GainID : Integer ;

     // Current settings
     ReadoutSpeed : Integer ;         // Readout rate (index no.)
     ReadoutSpeedMax : Integer ;      // Max. readout rate (index no.)
     FrameLeft : Integer ;            // Left pixel in CCD readout area
     FrameRight : Integer ;           // Right pixel in CCD eadout area
     FrameTop : Integer ;             // Top of CCD readout area
     FrameBottom : Integer ;          // Bottom of CCD readout area
     BinFactor : Integer ;           // Pixel binning factor (In)
     FrameWidth : Integer ;          // Image width
     FrameHeight : Integer ;         // Image height
     FrameInterval : Double ;        // Time interval between frames (s)
     ReadoutTime : Double  ;        // Frame readout time (s)

     end ;


TDCAM_HDR_PARAM = packed record
	Size : DWord ;						//* size of whole structure */
	id : DWord ;							//* specify the kind of this structure */
	iFlag : DWord ;						//* specify the member to be set or requested by application */
	oFlag : DWord ;						//* specify the member to be set or gotten by module */
  end ;

TDCAM_PARAM_FEATURE = packed record
    HDR : TDCAM_HDR_PARAM ;
    featureid : Integer ;   //' [in]
    Flags : Integer ;       //' [in/out]
    featurevalue : Single ; //     ' [in/out]
    LastElement : Integer ; //  'For size measurement purposes
    end ;

TDCAM_PARAM_FEATURE_INQ = packed record
    HDR : TDCAM_HDR_PARAM ;        //        ' id == DCAM_IDPARAM_FEATURE_INQ */
    featureid : Integer ;//' [in]
    capflags : Integer ; //' [out]    /
    min : Single ;       //       ' [out]
    max : Single ;       //       ' [out]
    step : Single ;      //       ' [out]
    defaultvalue : Single ; //    ' [out]
    units : Array[0..15] of char ; //' [out]
    LastElement : Integer ;  //'For size measurement purposes
    end ;

TDCAM_PARAM_SUBARRAY = packed record
    HDR : TDCAM_HDR_PARAM ;      // id == DCAM_IDPARAM_SUBARRAY */
    hpos : Integer ;             // ' [in/out]
    vpos : Integer ;             //  ' [in/out]
    hsize : Integer ;            //  ' [in/out]
    vsize : Integer ;            //  ' [in/out]
    LastElement : Integer ;      //'For size measurement purposes
    end ;

TDCAM_PARAM_SUBARRAY_INQ = packed record
    HDR : TDCAM_HDR_PARAM ;  //              ' id == DCAM_IDPARAM_SUBARRAY_INQ */
    binning : Integer ; //            ' [in]
    hmax : Integer ; //               ' [out]
    vmax : Integer ; //               ' [out]
    hposunit : Integer ; //           ' [out]
    vposunit : Integer ; //           ' [out]
    hunit : Integer ; //             ' [out]
    vunit : Integer ; //              ' [out]
    LastElement : Integer ; // 'For size measurement purposes
    end ;

TDCAM_PARAM_FRAME_READOUT_TIME_INQ = packed record
    HDR : TDCAM_HDR_PARAM ;  //                ' id == DCAM_IDPARAM_FRAME_READOUT_TIME_INQ */
    framereadouttime : Double ; //  ' [out]
    LastElement : Integer ; // 'For size measurement purposes
    end ;

TDCAM_PARAM_SCANMODE = packed record
    HDR : TDCAM_HDR_PARAM ;  //               ' id == DCAM_IDPARAM_SCANMODE */
    speed : Integer ; //            ' [in/out]
    Special : Integer ; 
    end ;

TDCAM_PARAM_SCANMODE_INQ = packed record
    HDR : TDCAM_HDR_PARAM ;  //                ' id == DCAM_IDPARAM_SCANMODE_INQ */
    speedmax : Integer ; //           ' [out]
    LastElement : Integer ; //  'For size measurement purposes
    end ;

TDCAM_PARAM_PROPERTYATTR = packed record
	// input parameters */
	cbSize : Integer ;			//	size of this structure	*/
	iProp : Integer ;			//	DCAMIDPROPERTY			*/
	option : Integer ;			//	DCAMPROPOPTION			*/
	iReserved1 : Integer ;		//	must be 0				*/

	// output parameters */
	attribute : Integer ;		//	DCAMPROPATTRIBUTE		*/
	iGroup : Integer ;			//	0 reserved; DCAMIDGROUP	*/
	iUnit : Integer ;			//	DCAMPROPUNIT			*/
	attribute2 : Integer ;		//	DCAMPROPATTRIBUTE2		*/

	valuemin : Double ;		//	minimum value			*/
	valuemax : Double ;		//	maximum value			*/
	valuestep : Double ;		//	minimum stepping between a value and the next	*/
	valuedefault : Double ;	//	default value			*/

	// available from DCAM-API 3.0 */
	nMaxChannel : Integer ;	//	max channel if supports	*/
	iReserved3 : Integer ;		//	reserved to 0			*/
	nMaxView : Integer ;		//	max view if supports	*/

	// available from DCAM-API 3.03 */
	iProp_NumberOfElement : Integer ;	//	number of elements for array	*/
	iProp_ArrayBase : Integer ;		//	base id of array if element		*/
	iPropStep_Element : Integer ;		//	step for iProp to next element	*/

  end ;

TDCAM_PARAM_PROPERTYVALUETEXT = packed record
	cbSize : Integer ;			//	size of this structure	*/
	iProp : Integer ;			//	DCAMIDPROP				*/
	value : Double ;
	text : PChar ;
	textbytes : Integer ;
  end ;


Tdcam_getlasterror = function(
                     HDCAM : THandle ;
                     Buf : PChar ;
                     bytesize : Integer
                     ) : Integer ; stdcall ;

//*** --- initialize and finalize --- ***/

Tdcam_init = function(
             hInst : Integer ;
             var Count : Integer ;
             Reserved : Pointer
             ) : Integer ; stdcall ;

Tdcam_uninit = function(
               hInst : Integer ;
               Reserved : Pointer
               ) : Integer ; stdcall ;

Tdcam_getmodelinfo = function(
                     Index : Integer ;
                     StringID : Integer ;
                     Buf : PChar ;
                     bytesize : Integer
                     ) : Integer ; stdcall ;

Tdcam_open = function(
             HDCam : Pointer ;
             Index : Integer ;
             Reserved : Pointer
               ) : Integer ; stdcall ;

Tdcam_close	= function(
              HDCam : THandle
              ) : Integer ; stdcall ;

//*** --- camera infomation --- ***/

Tdcam_getstring	= function(
                  HDCam : THandle ;
                  StringID : PChar ;
                  Buf : PChar ;
                  ByteSize : Integer
                  ) : Integer ; stdcall ;

Tdcam_getcapability	= function(
                      HDCam : THandle ;
                      var Capability : Cardinal ;
                      CapTypeID : Cardinal
                      ) : Integer ; stdcall ;

Tdcam_getdatatype	= function(
                    HDCam : THandle ;
                    var Datatype : DWord
                    ) : Integer ; stdcall ;

Tdcam_getbitstype = function(
                    HDCam : THandle ;
                    var Bitstype : Cardinal
                    ) : Integer ; stdcall ;

Tdcam_setdatatype = function(
                    HDCam : THandle ;
                    Datatype : Cardinal
                    ) : Integer ; stdcall ;

Tdcam_setbitstype = function(
                    HDCam : THandle ;
                    Bitstype : Cardinal
                    ) : Integer ; stdcall ;

Tdcam_getdatasize = function(
                    HDCam : THandle ;
                    pBuf : Pointer
                    ) : Integer ; stdcall ;

Tdcam_getbitssize = function(
                    HDCam : THandle ;
                    var Size : Cardinal
                    ) : Integer ; stdcall ;

//*** --- parameters --- ***/

Tdcam_queryupdate = function(
                    HDCam : THandle ;
                    var Flag : Cardinal ;
                    Reserved  : Cardinal
                    ) : Integer ; stdcall ;

Tdcam_getbinning = function(
                   HDCam : THandle ;
                   var Binning : Cardinal
                   ) : Integer ; stdcall ;

Tdcam_getexposuretime	= function(
                        HDCam : THandle ;
                        var Sec : Double
                        ) : Integer ; stdcall ;

Tdcam_gettriggermode = function(
                       HDCam : THandle ;
                       var Mode : Cardinal
                       ) : Integer ; stdcall ;

Tdcam_gettriggerpolarity = function(
                           HDCam : THandle ;
                           var Polarity : Cardinal
                           ) : Integer ; stdcall ;

Tdcam_setbinning = function(
                   HDCam : THandle ;
                   binning : Cardinal
                   ) : Integer ; stdcall ;

Tdcam_setexposuretime	= function(
                        HDCam : THandle ;
                        Sec : Double
                        ) : Integer ; stdcall ;

Tdcam_settriggermode = function(
                       HDCam : THandle ;
                       Mode : Cardinal
                       ) : Integer ; stdcall ;

Tdcam_settriggerpolarity = function(
                           HDCam : THandle ;
                           Polarity  : Cardinal
                           ) : Integer ; stdcall ;

//*** --- capturing --- ***/

Tdcam_precapture = function(
                   HDCam : THandle ;
                   CaptureMode : Cardinal
                   ) : Integer ; stdcall ;

Tdcam_getdatarange = function(
                     HDCam : THandle ;
                     var Max : Integer ;
                     var Min : Integer
                     ) : Integer ; stdcall ;

Tdcam_getdataframebytes	= function(
                          HDCam : THandle ;
                          var Size: Cardinal
                          ) : Integer ; stdcall ;

Tdcam_allocframe = function(
                   HDCam : THandle ;
                   Frame : Cardinal
                   ) : Integer ; stdcall ;

Tdcam_getframecount = function(
                      HDCam : THandle ;
                      var Frame  : Cardinal
                      ) : Integer ; stdcall ;

Tdcam_capture	 = function(
                 HDCam : THandle
                 ) : Integer ; stdcall ;

Tdcam_idle = function(
             HDCam : THandle
             ) : Integer ; stdcall ;

Tdcam_wait = function(
             HDCam : THandle ;
             var Code : Cardinal ;
             timeout : Cardinal ;
             Event : THandle
             ) : Integer ; stdcall ;

Tdcam_getstatus	= function(
                  HDCam : THandle ;
                  var Status : Integer
                  ) : Integer ; stdcall ;

Tdcam_gettransferinfo	= function(
                        HDCam : THandle ;
                        var NewestFrameIndex : Cardinal ;
                        var FrameCount : Cardinal
                        ) : Integer ; stdcall ;

Tdcam_freeframe	 = function(
                   HDCam : THandle
                   ) : Integer ; stdcall ;

//*** --- user memory support --- ***/

Tdcam_attachbuffer = function(
                     HDCam : THandle ;
                     pTop : Pointer ;
                     size : Cardinal
                     ) : Integer ; stdcall ;

Tdcam_releasebuffer = function(
                      HDCam : THandle
                      ) : Integer ; stdcall ;

//*** --- data transfer --- ***/

Tdcam_lockdata = function(
                 HDCam : THandle ;
                 pTop : Pointer ;
                 var Rowbytes : Cardinal ;
                 frame : Cardinal
                 ) : Integer ; stdcall ;

Tdcam_lockbits = function(
                 HDCam : THandle ;
                 Top : Pointer ;
                 var Rowbytes : Cardinal ;
                 frame : Cardinal
                 ) : Integer ; stdcall ;

Tdcam_unlockdata = function(
                   HDCam : THandle
                   ) : Integer ; stdcall ;

Tdcam_unlockbits = function(
                   HDCam : THandle
                   ) : Integer ; stdcall ;

//*** --- LUT --- ***/

Tdcam_setbitsinputlutrange = function(
                             HDCam : THandle ;
                             inMax : Cardinal ;
                             inMin : Cardinal
                             ) : Integer ; stdcall ;

Tdcam_setbitsoutputlutrange	= function(
                              HDCam : THandle ;
                              outMax : Byte ;
                              outMin : Byte
                              ) : Integer ; stdcall ;

//*** --- Control Panel --- ***/

Tdcam_showpanel	 = function(
                   HDCam : THandle ;
                   hWnd : THandle ;
                   reserved : Cardinal
                   ) : Integer ; stdcall ;

//*** --- extended --- ***/

Tdcam_extended	 = function(
                   HDCam : THandle ;
                   iCmd : Cardinal ;
                   param : Pointer ;
                   size : Cardinal
                   ) : Integer ; stdcall ;

//*** --- software trigger --- ***/
Tdcam_firetrigger = function(
                    HDCam : THandle
                    ) : Integer ; stdcall ;

Tdcam_getpropertyattr	= function(
                        HDCam : THandle ;
                        var PropertyAttribute : TDCAM_PARAM_PROPERTYATTR
                        ) : Integer ; stdcall ;

Tdcam_getpropertyvalue = function(
                         HDCam : THandle ;
                         iProp : Integer ;
                         var pValue : Double
                         ) : Integer ; stdcall ;

Tdcam_setpropertyvalue = function(
                         HDCam : THandle ;
                         iProp : Integer ;
                         var pValue : Double
                         ) : Integer ; stdcall ;

Tdcam_setgetpropertyvalue = function(HDCam : THandle ;
                            iProp : Integer ;
                            var pValue : Double ;
                            option : Integer
                            ) : Integer ; stdcall ;

Tdcam_querypropertyvalue = function(
                           HDCam : THandle ;
                           iProp : Integer ;
                           var pValue : Double ;
                           option : Integer
                           ) : Integer ; stdcall ;

Tdcam_getnextpropertyid	 = function(
                           HDCam : THandle ;
                           var iProp : Integer ;
                           option : Integer
                           ) : Integer ; stdcall ;

Tdcam_getpropertyname	 = function(
                         HDCam : THandle ;
                         iProp : Integer ;
                         PropName : PChar ;
                         MaxBytes : Integer ) : Integer ; stdcall ;

Tdcam_getpropertyvaluetext = function(
                             HDCam : THandle ;
                             var PropertyValue : Integer
                             ) : Integer ; stdcall ;


// Public procedures

function DCAMAPI_LoadLibrary : Boolean ;

function DCAMAPI_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;

function DCAMAPI_OpenCamera(
          var Session : TDCAMAPISession ;   // Camera session record
          var FrameWidthMax : Integer ;      // Returns camera frame width
          var FrameHeightMax : Integer ;     // Returns camera frame width
          var NumBytesPerPixel : Integer ;   // Returns bytes/pixel
          var PixelDepth : Integer ;         // Returns no. bits/pixel
          var PixelWidth : Single ;          // Returns pixel size (um)
          var BinFactorMax : Integer ;        // Max. bin factor
          CameraInfo : TStringList         // Returns Camera details
          ) : Boolean ;

procedure DCAMAPI_CloseCamera(
          var Session : TDCAMAPISession // Session record
          ) ;

procedure DCAMAPI_GetCameraGainList(
          var Session : TDCAMAPISession ;
          CameraGainList : TStringList
          ) ;

procedure DCAMAPI_GetCameraReadoutSpeedList(
          var Session : TDCAMAPISession ;
          CameraReadoutSpeedList : TStringList
          ) ;

function DCAMAPI_StartCapture(
         var Session : TDCAMAPISession ;   // Camera session record
         var InterFrameTimeInterval : Double ;      // Frame exposure time
         var AdditionalReadoutTime : Double ;
         AmpGain : Integer ;              // Camera amplifier gain index
         ReadoutSpeed : Integer ;         // Camera Read speed index number
         ExternalTrigger : Integer ;      // Trigger mode
         FrameLeft : Integer ;            // Left pixel in CCD readout area
         FrameRight : Integer ;           // Right pixel in CCD readout area
         FrameTop : Integer ;             // Top pixel in CCD eadout area
         FrameBottom : Integer ;          // Bottom pixel in CCD readout area
         BinFactor : Integer ;             // Binning factor (1,2,4,8,16)
         PFrameBuffer : Pointer ;         // Pointer to start of ring buffer
         NumFramesInBuffer : Integer ;    // No. of frames in ring buffer
         NumBytesPerFrame : Integer ;      // No. of bytes/frame
         DisableEMCCD : Boolean           // TRue = Disable EMCCD function
         ) : Boolean ;

function DCAMAPI_CheckFrameInterval(
          var Session : TDCAMAPISession ;   // Camera session record
          FrameLeft : Integer ;   // Left edge of capture region (In)
          FrameRight : Integer ;  // Right edge of capture region( In)
          FrameTop : Integer ;    // Top edge of capture region( In)
          FrameBottom : Integer ; // Bottom edge of capture region (In)
          BinFactor : Integer ;   // Pixel binning factor (In)
          Var FrameInterval : Double ;
          Var ReadoutTime : Double) : Boolean ;


procedure DCAMAPI_Wait( Delay : Single ) ;


procedure DCAMAPI_GetImage(
          var Session : TDCAMAPISession  // Camera session record
          ) ;

procedure DCAMAPI_StopCapture(
          var Session : TDCAMAPISession   // Camera session record
          ) ;

procedure DCAMAPI_CheckError(
          FuncName : String ;   // Name of function called
          ErrNum : Integer      // Error # returned by function
          ) ;

procedure DCAMAPI_CheckROIBoundaries(
          var Session : TDCAMAPISession ;   // Camera session record
         var ReadoutSpeed : Integer ;         // Readout rate (index no.)
         var FrameLeft : Integer ;            // Left pixel in CCD readout area
         var FrameRight : Integer ;           // Right pixel in CCD eadout area
         var FrameTop : Integer ;             // Top of CCD readout area
         var FrameBottom : Integer ;          // Bottom of CCD readout area
         var BinFactor : Integer ;           // Pixel binning factor (In)
         var FrameWidth : Integer ;          // Image width
         var FrameHeight : Integer ;         // Image height
         var FrameInterval : Double ;        // Time interval between frames (s)
         var ReadoutTime : Double ) ;        // Frame readout time (s)

function DCAMAPI_CheckStepSize( Value : Integer ;
                                StepSize : Integer ) : Integer ;

procedure DCAMAPI_SetProperty(
          var Session : TDCAMAPISession ;   // Camera session record
          iProperty : Integer ;
          Value : Double                    // Property value
          ) ;

implementation

uses SESCam ;

var

   dcam_getlasterror : Tdcam_getlasterror ;
   dcam_init : Tdcam_init ;
   dcam_uninit : Tdcam_uninit ;
   dcam_getmodelinfo : Tdcam_getmodelinfo ;
   dcam_open : Tdcam_open ;
   dcam_close : Tdcam_close ;
   dcam_getstring : Tdcam_getstring ;
   dcam_getcapability : Tdcam_getcapability ;
   dcam_getdatatype : Tdcam_getdatatype ;
   dcam_getbitstype : Tdcam_getbitstype ;
   dcam_setdatatype : Tdcam_setdatatype ;
   dcam_setbitstype : Tdcam_setbitstype ;
   dcam_getdatasize : Tdcam_getdatasize ;
   dcam_getbitssize : Tdcam_getbitssize ;
   dcam_queryupdate : Tdcam_queryupdate ;
   dcam_getbinning : Tdcam_getbinning ;
   dcam_getexposuretime : Tdcam_getexposuretime ;
   dcam_gettriggermode : Tdcam_gettriggermode ;
   dcam_gettriggerpolarity : Tdcam_gettriggerpolarity ;
   dcam_setbinning : Tdcam_setbinning ;
   dcam_setexposuretime : Tdcam_setexposuretime ;
   dcam_settriggermode : Tdcam_settriggermode ;
   dcam_settriggerpolarity : Tdcam_settriggerpolarity ;
   dcam_precapture : Tdcam_precapture ;
   dcam_getdatarange : Tdcam_getdatarange ;
   dcam_getdataframebytes	: Tdcam_getdataframebytes	;
   dcam_allocframe : Tdcam_allocframe ;
   dcam_getframecount : Tdcam_getframecount ;
   dcam_capture : Tdcam_capture ;
   dcam_idle : Tdcam_idle ;
   dcam_wait : Tdcam_wait ;
   dcam_getstatus : Tdcam_getstatus ;
   dcam_gettransferinfo : Tdcam_gettransferinfo ;
   dcam_freeframe : Tdcam_freeframe ;
   dcam_attachbuffer : Tdcam_attachbuffer ;
   dcam_releasebuffer  : Tdcam_releasebuffer ;
   dcam_lockdata : Tdcam_lockdata ;
   dcam_lockbits : Tdcam_lockbits ;
   dcam_unlockdata : Tdcam_unlockdata ;
   dcam_unlockbits : Tdcam_unlockbits ;
   dcam_setbitsinputlutrange : Tdcam_setbitsinputlutrange ;
   dcam_setbitsoutputlutrange  : Tdcam_setbitsoutputlutrange ;
   dcam_showpanel : Tdcam_showpanel ;
   dcam_firetrigger : Tdcam_firetrigger ;
   dcam_extended : Tdcam_extended ;
   // Property functions (added for DCAM V3 4/9/9 JD)
   dcam_getpropertyattr	:Tdcam_getpropertyattr ;
   dcam_getpropertyvalue : Tdcam_getpropertyvalue ;
   dcam_setpropertyvalue : Tdcam_setpropertyvalue ;
   dcam_setgetpropertyvalue : Tdcam_setgetpropertyvalue ;
   dcam_querypropertyvalue : Tdcam_querypropertyvalue ;
   dcam_getnextpropertyid	: Tdcam_getnextpropertyid ;
   dcam_getpropertyname	: Tdcam_getpropertyname ;
   dcam_getpropertyvaluetext :Tdcam_getpropertyvaluetext ;

   LibraryLoaded : Boolean ;
   LibraryHnd : THandle ;

function DCAMAPI_LoadLibrary  : Boolean ;
{ ---------------------------------------------
  Load camera interface DLL library into memory
  ---------------------------------------------}
var
    LibFileName : string ;
begin


     Result := LibraryLoaded ;

     if LibraryLoaded then Exit ;


     { Load DLL camera interface library }
     LibFileName := 'dcamapi.dll' ;
     LibraryHnd := LoadLibrary( PChar(LibFileName));
     if LibraryHnd <= 0 then begin
        ShowMessage( 'DCAMAPI: ' + LibFileName + ' not found!' ) ;
        Exit ;
        end ;

     @dcam_firetrigger := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_firetrigger') ;
     @dcam_showpanel := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_showpanel') ;
     @dcam_setbitsoutputlutrange := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_setbitsoutputlutrange') ;
     @dcam_setbitsinputlutrange := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_setbitsinputlutrange') ;
     @dcam_unlockbits := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_unlockbits') ;
     @dcam_unlockdata := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_unlockdata') ;
     @dcam_lockbits := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_lockbits') ;
     @dcam_lockdata := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_lockdata') ;
     @dcam_releasebuffer := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_releasebuffer') ;
     @dcam_attachbuffer := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_attachbuffer') ;
     @dcam_freeframe := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_freeframe') ;
     @dcam_gettransferinfo := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_gettransferinfo') ;
     @dcam_getstatus := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getstatus') ;
     @dcam_wait := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_wait') ;
     @dcam_idle := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_idle') ;
     @dcam_capture := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_capture') ;
     @dcam_getframecount := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getframecount') ;
     @dcam_allocframe := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_allocframe') ;
     @dcam_getdataframebytes := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getdataframebytes') ;
     @dcam_getdatarange := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getdatarange') ;
     @dcam_precapture := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_precapture') ;
     @dcam_settriggerpolarity := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_settriggerpolarity') ;
     @dcam_settriggermode := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_settriggermode') ;
     @dcam_setexposuretime := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_setexposuretime') ;
     @dcam_setbinning := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_setbinning') ;
     @dcam_gettriggerpolarity := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_gettriggerpolarity') ;
     @dcam_gettriggermode := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_gettriggermode') ;
     @dcam_getexposuretime := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getexposuretime') ;
     @dcam_getbinning := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getbinning') ;
     @dcam_queryupdate := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_queryupdate') ;
     @dcam_getbitssize := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getbitssize') ;
     @dcam_getdatasize := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getdatasize') ;
     @dcam_setbitstype := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_setbitstype') ;
     @dcam_setdatatype := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_setdatatype') ;
     @dcam_getbitstype := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getbitstype') ;
     @dcam_getdatatype := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getdatatype') ;
     @dcam_getcapability := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getcapability') ;
     @dcam_getstring := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getstring') ;
     @dcam_close := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_close') ;
     @dcam_open := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_open') ;
     @dcam_getmodelinfo := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getmodelinfo') ;
     @dcam_uninit := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_uninit') ;
     @dcam_init := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_init') ;
     @dcam_getlasterror := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getlasterror') ;
     @dcam_extended := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_extended') ;

     @dcam_getpropertyattr := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getpropertyattr') ;
     @dcam_getpropertyvalue := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getpropertyvalue') ;
     @dcam_setpropertyvalue := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_setpropertyvalue') ;
     @dcam_querypropertyvalue := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_querypropertyvalue') ;
     @dcam_getnextpropertyid := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getnextpropertyid') ;
     @dcam_getpropertyname := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getpropertyname') ;
     @dcam_getpropertyvaluetext := DCAMAPI_GetDLLAddress(LibraryHnd,'dcam_getpropertyvaluetext') ;

     LibraryLoaded := True ;
     Result := LibraryLoaded ;

     end ;


function DCAMAPI_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;
// -----------------------------------------
// Get address of procedure within DLL
// -----------------------------------------
begin
    Result := GetProcAddress(Handle,PChar(ProcName)) ;
    if Result = Nil then ShowMessage('dcamapi.dll: ' + ProcName + ' not found') ;
    end ;


function DCAMAPI_OpenCamera(
         var Session : TDCAMAPISession ;   // Camera session record
         var FrameWidthMax : Integer ;      // Returns camera frame width
         var FrameHeightMax : Integer ;     // Returns camera frame width
         var NumBytesPerPixel : Integer ;   // Returns bytes/pixel
         var PixelDepth : Integer ;         // Returns no. bits/pixel
         var PixelWidth : Single ;          // Returns pixel size (um)
         var BinFactorMax : Integer ;        // Max. bin factor
         CameraInfo : TStringList         // Returns Camera details
         ) : Boolean ;
// -------------------
// Open camera for use
// -------------------
const
    BufSize = 200 ;
var
    cBuf : Array[0..BufSize] of Char ;
    iBuf : Array[0..BufSize] of Integer ;
    iValue,iMax,iMin : Integer ;
    dwValue : DWord ;
    s : String ;
    InqParam : TDCAM_PARAM_FEATURE_INQ ;
    CameraAttrib : TDCAM_PARAM_PROPERTYATTR ;
    iProp : Integer ;
    Done : Boolean ;
    Err,iErr : Integer ;
begin

     // Load DLL camera control library
     if not DCAMAPI_LoadLibrary then Exit ;

 //    if dcam_init( {Application.Handle}0,Session.NumCameras,Nil ) then begin
 //       ShowMessage('DCAM: Unable to initialise DCAM Manager!') ;
//        Exit ;
//       end ;

        Err := dcam_init( 0,Session.NumCameras,Nil ) ;


     if Session.NumCameras <= 0 then begin
        ShowMessage(format('DCAM: No cameras available! %d',[Err])) ;
        Exit ;
        end ;

 //    if dcam_open( @Session.CamHandle, 0, nil ) then begin
 //       ShowMessage('DCAM: Unable to open camera!') ;
 //       Exit ;
 //       end ;
     dcam_open( @Session.CamHandle, 0, nil ) ;

     // Get camera information
     dcam_getmodelinfo( 0, DCAM_IDSTR_MODEL, cBuf, BufSize ) ;
     Session.CameraModel := cBuf ;
     s := format( ' Camera: %s',[cBuf] ) ;
     dcam_getmodelinfo(0, DCAM_IDSTR_CAMERAVERSION, cBuf, BufSize) ;
     s := s + format( ' V %s',[cBuf] ) ;
     dcam_getmodelinfo(0, DCAM_IDSTR_CAMERAID, cBuf, BufSize) ;
     s := s + format( ' (%s)',[cBuf] ) ;
     CameraInfo.Add( s ) ;

     // Get interface bus type
     dcam_getmodelinfo(0, DCAM_IDSTR_BUS, cBuf, BufSize) ;
     CameraInfo.Add(format( 'Interface type: (%s)',[cBuf] )) ;

     // Get driver information
     dcam_getmodelinfo(0, DCAM_IDSTR_DRIVERVERSION, cBuf, BufSize) ;
     CameraInfo.Add(format( 'Driver: %s',[cBuf] )) ;

     // Get module information
     dcam_getmodelinfo(0, DCAM_IDSTR_MODULEVERSION, cBuf, BufSize) ;
     CameraInfo.Add(format( 'Module: %s',[cBuf] )) ;

     // Get max. size of camera image
     dcam_getdatasize( Session.CamHandle, @iBuf ) ;
     FrameWidthMax := iBuf[0] ;
     FrameHeightMax := iBuf[1] ;

     // Get number of bits per pixel
     dcam_getdatarange( Session.CamHandle, iMax, iMin ) ;
     PixelDepth := 0 ;
     iMax := iMax + 1 ;
     while iMax > 1 do begin
        Inc(PixelDepth) ; ;
        iMax := iMax div 2 ;
        end ;

     dcam_getmodelinfo( 0, DCAM_IDSTR_MODEL, cBuf, BufSize ) ;
     if Pos('1024',cBuf) > 0 then PixelWidth := 13
     else if Pos('512',cBuf) > 0 then PixelWidth := 24
     else PixelWidth := 6.45 ;

     CameraInfo.Add( format('CCD: %d x %d x %.3gum pixels (%d bits/pixel)',
                     [FrameWidthMax,FrameHeightMax,PixelWidth,PixelDepth] )) ;

     // Get numbers of bytes / pixel
     dcam_getdatatype( Session.CamHandle, dwValue ) ;
     case dwValue of
        DCAM_DATATYPE_UINT8,DCAM_DATATYPE_INT8 : NumBytesPerPixel := 1 ;
        DCAM_DATATYPE_UINT16,DCAM_DATATYPE_INT16 : NumBytesPerPixel := 2 ;
        else NumBytesPerPixel := 4 ;
        end ;

     // Get pixel binning capabilities
     Session.NumBinFactors := 0 ;
     Session.BinFactors[Session.NumBinFactors] := 1 ;
     Inc(Session.NumBinFactors) ;

     dcam_getcapability( Session.CamHandle, dwValue, DCAM_QUERYCAPABILITY_FUNCTIONS ) ;
     s := 'Pixel Binning: ' ;
     if (dwValue AND DCAM_CAPABILITY_BINNING2) > 0 then begin
         s := s + '2x2, ';
         Session.BinFactors[Session.NumBinFactors] := 2 ;
         Inc(Session.NumBinFactors) ;
         end ;
     if (dwValue AND DCAM_CAPABILITY_BINNING4) > 0 then begin
        s := s + '4x4, ';
         Session.BinFactors[Session.NumBinFactors] := 4 ;
         Inc(Session.NumBinFactors) ;
         end ;
     if (dwValue AND DCAM_CAPABILITY_BINNING8) > 0 then begin
        s := s + '8x8 ';
         Session.BinFactors[Session.NumBinFactors] := 8 ;
         Inc(Session.NumBinFactors) ;
         end ;

     CameraInfo.Add( s ) ;

     BinFactorMax := Session.BinFactors[Session.NumBinFactors-1] ;

     if (dwValue AND DCAM_CAPABILITY_USERMEMORY) > 0 then
        CameraInfo.Add('Direct capture to user memory supported') ;

     // Get number of camera special features
    dcam_extended( Session.CamHandle,
                   DCAM_IDMSG_QUERYPARAMCOUNT,
                   @Session.NumFeatures,
                   SizeOf(Session.NumFeatures)) ;

     Session.FeatureID[0] := 0 ;
     // Get list of camera special feature IDs
     dcam_extended( Session.CamHandle,
                    DCAM_IDMSG_QUERYPARAMID,
                    @Session.FeatureID,
                    SizeOf(Session.FeatureID)) ;

     // Enumerate Camera properties
{     if @dcam_getnextpropertyid <> Nil then begin
        iProp := 0 ;
        Done := False ;
        While not Done do begin
           dcam_getnextpropertyid( Session.CamHandle, iProp, DCAMPROP_OPTION_SUPPORT ) ;
           if iProp <> 0 then begin
              CameraAttrib.cbSize := SizeOf(CameraAttrib) ;
              CameraAttrib.iProp := iProp ;
              dcam_getpropertyattr( Session.CamHandle, CameraAttrib ) ;
              dcam_getpropertyname( Session.CamHandle, iProp, cBuf, sizeof(cBuf) );
              CameraInfo.Add( cBuf ) ;
              end
           else Done := True ;
           end ;
        end ;}

     Session.CameraOpen := True ;
     Session.CapturingImages := False ;
     Result := Session.CameraOpen ;

     end ;


procedure DCAMAPI_CloseCamera(
          var Session : TDCAMAPISession // Session record
          ) ;
// ------------
// Close camera
// ------------
begin

    if not Session.CameraOpen then Exit ;

    // Stop capture if in progress
    if Session.CapturingImages then DCAMAPI_StopCapture( Session ) ;

    // Close camera
    dcam_close( Session.CamHandle ) ;

    // Close DCAM-API
    dcam_uninit( 0, Nil ) ;

    Session.CameraOpen := False ;

    end ;


procedure DCAMAPI_GetCameraGainList(
          var Session : TDCAMAPISession ;
          CameraGainList : TStringList
          ) ;
// --------------------
// Get camera gain list
// --------------------
var
    Param : TDCAM_PARAM_FEATURE_INQ ;
    Gain : Single ;
    Err : Integer ;
begin

    // Get gain information
    Param.HDR.Size := Sizeof(Param) ;
    Param.HDR.id := DCAM_IDPARAM_FEATURE_INQ ;
    Param.HDR.iFlag := dcamparam_featureinq_featureid or
                       dcamparam_featureinq_capflags or
                       dcamparam_featureinq_min or
                       dcamparam_featureinq_max or
                       dcamparam_featureinq_step or
                       dcamparam_featureinq_defaultvalue or
                       dcamparam_featureinq_units ;
    Param.HDR.oFlag := 0 ;

    Param.min := -1 ; // Set these to -1 as flags to indicate feature exists
    Param.max := -1 ;

    // Use sensitivity feature to set gain
    Session.GainID := DCAM_IDFEATURE_SENSITIVITY ;
    Param.featureid := Session.GainID ;
    dcam_extended( Session.CamHandle,
                   DCAM_IDMSG_GETPARAM,
                   @Param,
                   SizeOf(Param)) ;

   if (Param.min = -1) and (Param.max = -1) then begin
      // Use standard gain
      Session.GainID := DCAM_IDFEATURE_GAIN ;
      Param.featureid := Session.GainID ;
      Param.min := -1 ;
      Param.max := -1 ;
      dcam_extended( Session.CamHandle,
                     DCAM_IDMSG_GETPARAM,
                     @Param,
                     SizeOf(Param)) ;
      end ;

    outputdebugString(PChar(format('Err=%d',[Err])));
    // Set to gains available from list
    Session.NumGains := 0 ;
    CameraGainList.Clear ;
    Gain := Param.Min ;
    while (Gain <= Param.Max) and (Session.NumGains <= High(Session.Gains)) do begin
       Session.Gains[Session.NumGains] := Gain ;
       CameraGainList.Add( format( 'X%.1f',[Session.Gains[Session.NumGains]+1]));
       Inc( Session.NumGains ) ;
       Gain := Gain + Param.Step ;
       end ;

    end ;


procedure DCAMAPI_GetCameraReadoutSpeedList(
          var Session : TDCAMAPISession ;
          CameraReadoutSpeedList : TStringList
          ) ;
var
    Param : TDCAM_PARAM_SCANMODE_INQ ;
    i : Integer ;
    s : String ;
begin

    // Get maximum scan mode
    Param.HDR.Size := Sizeof(Param) ;
    Param.HDR.id := DCAM_IDPARAM_SCANMODE_INQ ;
    Param.HDR.iFlag := dcamparam_feature_featureid or
                       dcamparam_feature_flags or
                       dcamparam_feature_featurevalue ;
    Param.HDR.oFlag := 0 ;
    dcam_extended( Session.CamHandle,
                   DCAM_IDMSG_GETPARAM,
                   @Param,
                   SizeOf(Param)) ;

    Session.ReadoutSpeedMax := Max(Param.SpeedMax-dcamparam_scanmode_speed_slowest,0) ;

    CameraReadoutSpeedList.Clear ;
    for i := 1 to Param.SpeedMax do begin
       s := format( '%d',[i]) ;
       if i = 1 then s := s + ' (slow)' ;
       if i = Param.SpeedMax then s := s + ' (fast)' ;
       CameraReadoutSpeedList.Add( s );
       end ;


    end ;



function DCAMAPI_StartCapture(
         var Session : TDCAMAPISession ;   // Camera session record
         var InterFrameTimeInterval : Double ;      // Frame exposure time
         var AdditionalReadoutTime : Double ;
         AmpGain : Integer ;              // Camera amplifier gain index
         ReadoutSpeed : Integer ;         // Camera Read speed index number
         ExternalTrigger : Integer ;      // Trigger mode
         FrameLeft : Integer ;            // Left pixel in CCD readout area
         FrameRight : Integer ;           // Right pixel in CCD readout area
         FrameTop : Integer ;             // Top pixel in CCD eadout area
         FrameBottom : Integer ;          // Bottom pixel in CCD readout area
         BinFactor : Integer ;             // Binning factor (1,2,4,8,16)
         PFrameBuffer : Pointer ;         // Pointer to start of ring buffer
         NumFramesInBuffer : Integer ;    // No. of frames in ring buffer
         NumBytesPerFrame : Integer ;      // No. of bytes/frame
         DisableEMCCD : Boolean         // TRue = Disable EMCCD function
         ) : Boolean ;
var
    i,Err : Integer ;
    BufPointers : Array[0..999] of Pointer ;
    FrameWidth,FrameHeight : Integer ;
    ReadoutTime : Double ;
    Param : TDCAM_PARAM_FEATURE ;
    ExposureTime : Double ;
begin

    if not Session.CameraOpen then Exit ;

    // Enable/disable EMCDD function (if camera supports it)
    if DisableEMCCD then begin
       DCAMAPI_SetProperty( Session,
                            DCAM_IDPROP_CCDMODE,
                            DCAMPROP_CCDMODE__NORMALCCD )
       end
    else begin
       DCAMAPI_SetProperty( Session,
                            DCAM_IDPROP_CCDMODE,
                            DCAMPROP_CCDMODE__EMCCD )
       end ;    

    // Set CCD readout region
    DCAMAPI_CheckROIBoundaries( Session,
                                ReadoutSpeed,
                                FrameLeft,
                                FrameRight,
                                FrameTop,
                                FrameBottom,
                                BinFactor,
                                FrameWidth,
                                FrameHeight,
                                InterFrameTimeInterval,
                                ReadoutTime) ;

    // Set exposure trigger mode
    if ExternalTrigger = camExtTrigger then begin
       if ANSIContainsText(Session.CameraModel, 'C9100') then begin
          dcam_settriggermode( Session.CamHandle, DCAM_TRIGMODE_SYNCREADOUT ) ;
          end
       else dcam_settriggermode( Session.CamHandle, DCAM_TRIGMODE_EDGE ) ;
       dcam_settriggerpolarity( Session.CamHandle, DCAM_TRIGPOL_POSITIVE ) ;
       end
    else begin
       dcam_settriggermode( Session.CamHandle, DCAM_TRIGMODE_INTERNAL ) ;
       end ;

    // Pre-capture camera initialisations
    dcam_precapture( Session.CamHandle, ccCapture_Sequence ) ;

   // Set camera gain

    Param.HDR.Size := Sizeof(Param) ;
    Param.HDR.id := DCAM_IDPARAM_FEATURE ;
    Param.HDR.iFlag := dcamparam_feature_featureid or
                       dcamparam_feature_flags or
                       dcamparam_feature_featurevalue ;
    Param.HDR.oFlag := 0 ;
    Param.FeatureID := Session.GainID ;
    Param.Flags := DCAM_FEATURE_FLAGS_MANUAL ;
    Param.featurevalue := Session.Gains[AmpGain] ;

    dcam_extended( Session.CamHandle,
                   DCAM_IDMSG_SETPARAM,
                   @Param,
                   SizeOf(Param)) ;

    // Set pointers to frames within image capture buffer
    for i := 0 to NumFramesInBuffer-1 do
        Session.FramePointers[i] := Pointer(Cardinal(PFrameBuffer) + i*NumBytesPerFrame) ;

    // Attach image capture buffer
    Err := dcam_attachbuffer( Session.CamHandle, @Session.FramePointers,
                              NumFramesInBuffer*4) ;
 //   outputdebugString(PChar(format('dcam_attachbuffer Err=%d',[Err])));


    // Set exposure time
    if ExternalTrigger = camExtTrigger then begin
       if ANSIContainsText(Session.CameraModel, 'C9100') then begin
          dcam_settriggermode( Session.CamHandle, DCAM_TRIGMODE_SYNCREADOUT ) ;
          end
       else dcam_settriggermode( Session.CamHandle, DCAM_TRIGMODE_EDGE ) ;
       dcam_settriggerpolarity( Session.CamHandle, DCAM_TRIGPOL_POSITIVE ) ;
       // Subtract readout time for C4880 cameras, since these
       // camera can only have exposure times as multiples of readout time
       if ANSIContainsText(Session.CameraModel, 'C4880') then begin
          ExposureTime := ExposureTime - (Session.ReadoutTime+0.001) - AdditionalReadoutTime ;
          end
       else begin
           // Make exposure time 90% of frame interval
           ExposureTime := (InterFrameTimeInterval*0.9) - AdditionalReadoutTime ;
           end ;
       dcam_setexposuretime( Session.CAMHandle, ExposureTime ) ;
       end
    else begin
       dcam_settriggermode( Session.CamHandle, DCAM_TRIGMODE_INTERNAL ) ;
       dcam_setexposuretime( Session.CAMHandle, InterFrameTimeInterval ) ;
       dcam_getexposuretime( Session.CAMHandle, InterFrameTimeInterval ) ;
       end ;

    // Start capture
    Err := dcam_capture( Session.CamHandle ) ;
//    outputdebugString(PChar(format('dcam_capture Err=%d',[Err])));
    Session.CapturingImages := True ;
    Result := True ;

    end ;


procedure DCAMAPI_CheckROIBoundaries(
         var Session : TDCAMAPISession ;   // Camera session record
         var ReadoutSpeed : Integer ;         // Readout rate (index no.)
         var FrameLeft : Integer ;            // Left pixel in CCD readout area
         var FrameRight : Integer ;           // Right pixel in CCD eadout area
         var FrameTop : Integer ;             // Top of CCD readout area
         var FrameBottom : Integer ;          // Bottom of CCD readout area
         var BinFactor : Integer ;           // Pixel binning factor (In)
         var FrameWidth : Integer ;          // Image width
         var FrameHeight : Integer ;         // Image height
         var FrameInterval : Double ;        // Time interval between frames (s)
         var ReadoutTime : Double ) ;        // Frame readout time (s)
// ----------------------------------------------------------
// Check and set CCD ROI boundaries and return valid settings
// (Also calculates minimum readout time)
// -----------------------------------------------------------
var
    i,Err : Integer ;
    ParamSubArrayInq : TDCAM_PARAM_SUBARRAY_INQ ;
    ParamSubArray : TDCAM_PARAM_SUBARRAY ;
    ParamFrameReadoutTime : TDCAM_PARAM_FRAME_READOUT_TIME_INQ ;
    ReadoutSpeedParam : TDCAM_PARAM_SCANMODE ;
    NumBytes : cardinal ;
    Changed : Boolean ;
    MultipleofReadoutTime : Single ;
begin

    if not Session.CameraOpen then Exit ;

     // Save current settings
    Changed := False ;
    if Session.ReadoutSpeed <> ReadoutSpeed then Changed := True ;
    if Session.FrameLeft <> FrameLeft  then Changed := True ;
    if Session.FrameRight <> FrameRight  then Changed := True ;
    if Session.FrameTop <> FrameTop  then Changed := True ;
    if Session.FrameBottom <> FrameBottom  then Changed := True ;
    if Session.BinFactor <> BinFactor  then Changed := True ;
    if Session.FrameInterval <> FrameInterval then Changed := True ;
    if not Changed then begin
       FrameInterval := Session.FrameInterval ;
       ReadoutTime := Session.ReadoutTime ;
       FrameWidth := Session.FrameWidth ;
       FrameHeight := Session.FrameHeight ;
       Exit ;
       end ;

    // Set binning factor
    i := 0 ;
    while (BinFactor > Session.BinFactors[i]) and
           (i < Session.NumBinFactors) do Inc(i) ;
    BinFactor := Max( Session.BinFactors[i],1) ;
    dcam_setbinning( Session.CAMHandle, BinFactor ) ;

    // Get sub-array limits
    ParamSubArrayInq.HDR.Size := Sizeof(ParamSubArrayInq) ;
    ParamSubArrayInq.HDR.id := DCAM_IDPARAM_SUBARRAY_INQ ;
    ParamSubArrayInq.HDR.iFlag := dcamparam_subarrayinq_binning or
                                  dcamparam_subarrayinq_hmax or
                                  dcamparam_subarrayinq_vmax or
                                  dcamparam_subarrayinq_hposunit or
                                  dcamparam_subarrayinq_vposunit or
                                  dcamparam_subarrayinq_hunit or
                                  dcamparam_subarrayinq_vunit ;
    ParamSubArrayInq.HDR.oFlag := 0 ;
    ParamSubArrayInq.hposunit := 1 ;  // These values present in case
    ParamSubArrayInq.vposunit := 1 ;  // values in case not returned by DCAM
    ParamSubArrayInq.hunit := 1 ;
    ParamSubArrayInq.vunit := 1 ;
    ParamSubArrayInq.Binning := BinFactor ;
    dcam_extended( Session.CamHandle,
                   DCAM_IDMSG_GETPARAM,
                   @ParamSubArrayInq,
                   SizeOf(ParamSubArrayInq)) ;

    // Ensure sub-array limits are valid

    ParamSubArray.hpos := DCAMAPI_CheckStepSize(
                          FrameLeft div BinFactor,
                          ParamSubArrayInq.hposunit ) ;

    ParamSubArray.hsize := DCAMAPI_CheckStepSize(
                           (FrameRight - FrameLeft + 1) div BinFactor,
                           ParamSubArrayInq.hunit ) ;

    ParamSubArray.hsize := Max( ParamSubArray.hsize, ParamSubArrayInq.hunit ) ;
    ParamSubArray.vpos := DCAMAPI_CheckStepSize(
                          FrameTop div BinFactor,
                          ParamSubArrayInq.vposunit ) ;

    ParamSubArray.vsize := DCAMAPI_CheckStepSize(
                           (FrameBottom - FrameTop + 1) div BinFactor,
                           ParamSubArrayInq.vunit ) ;
    ParamSubArray.vsize := Max( ParamSubArray.vsize, ParamSubArrayInq.vunit ) ;

    // Set CCD sub-array limits
    ParamSubArray.HDR.Size := Sizeof(ParamSubArray) ;
    ParamSubArray.HDR.id := DCAM_IDPARAM_SUBARRAY ;
    ParamSubArray.HDR.iFlag := dcamparam_subarray_hpos or
                               dcamparam_subarray_vpos or
                               dcamparam_subarray_hsize or
                               dcamparam_subarray_vsize ;
    ParamSubArray.HDR.oFlag := 0 ;
    dcam_extended( Session.CamHandle,
                   DCAM_IDMSG_SETGETPARAM,
                   @ParamSubArray,
                   SizeOf(ParamSubArray)) ;

    // Update limits
    FrameLeft := ParamSubArray.hpos*BinFactor ;
    FrameTop := ParamSubArray.vpos*BinFactor ;
    FrameRight := ParamSubArray.hsize*BinFactor + FrameLeft - 1 ;
    FrameBottom := ParamSubArray.vsize*BinFactor + FrameTop - 1 ;
    FrameWidth := ParamSubArray.hsize ;
    FrameHeight := ParamSubArray.vsize ;

    // Set camera readout speed
    ReadoutSpeedParam.hdr.Size := Sizeof(ReadoutSpeedParam) ;
    ReadoutSpeedParam.hdr.id := DCAM_IDPARAM_SCANMODE ;
    ReadoutSpeedParam.hdr.iFlag := dcamparam_scanmode_speed ;
    ReadoutSpeedParam.hdr.oFlag := 0 ;
    ReadoutSpeedParam.Speed := Max(Min(ReadoutSpeed,Session.ReadoutSpeedMax),0)
                               + dcamparam_scanmode_speed_slowest ;
    dcam_extended( Session.CamHandle,
                   DCAM_IDMSG_SETPARAM,
                   @ReadoutSpeedParam,
                   SizeOf(ReadoutSpeedParam)) ;

    // Get frame readout time
    ParamFrameReadoutTime.HDR.Size := Sizeof(ParamFrameReadoutTime) ;
    ParamFrameReadoutTime.HDR.id := DCAM_IDPARAM_FRAME_READOUT_TIME_INQ ;
    ParamFrameReadoutTime.HDR.iFlag := dcamparam_framereadouttimeinq_framereadouttime ;
    ParamFrameReadoutTime.HDR.oFlag := 0 ;
    dcam_extended( Session.CamHandle,
                   DCAM_IDMSG_GETPARAM,
                   @ParamFrameReadoutTime,
                   SizeOf(ParamFrameReadoutTime)) ;

    ReadoutTime := ParamFrameReadoutTime.framereadouttime ;
    if ANSIContainsText(Session.CameraModel, 'C4880') then begin
       MultipleofReadoutTime := Max(Round(FrameInterval/(ReadoutTime*2)),1)*(ReadoutTime*2) ;
       if MultipleofReadoutTime < (FrameInterval*0.99) then
          MultipleofReadoutTime := MultipleofReadoutTime + ReadOutTime*2 ;
       FrameInterval := MultipleofReadoutTime ;
       end
    else FrameInterval := Max( FrameInterval, ReadoutTime ) ;

     // Save current settings
     Session.ReadoutSpeed := ReadoutSpeed ;
     Session.FrameLeft := FrameLeft ;
     Session.FrameRight := FrameRight ;
     Session.FrameTop := FrameTop ;
     Session.FrameBottom := FrameBottom ;
     Session.BinFactor := BinFactor ;
     Session.FrameWidth := FrameWidth ;
     Session.FrameHeight := FrameHeight ;
     Session.FrameInterval := FrameInterval ;
     Session.ReadoutTime := ReadoutTime  ;

     end ;

function DCAMAPI_CheckStepSize( Value : Integer ;
                                StepSize : Integer ) : Integer ;
begin
    Result := (Value div StepSize) * StepSize ;
    end ;


function DCAMAPI_CheckFrameInterval(
          var Session : TDCAMAPISession ;   // Camera session record
          FrameLeft : Integer ;   // Left edge of capture region (In)
          FrameRight : Integer ;  // Right edge of capture region( In)
          FrameTop : Integer ;    // Top edge of capture region( In)
          FrameBottom : Integer ; // Bottom edge of capture region (In)
          BinFactor : Integer ;   // Pixel binning factor (In)
          Var FrameInterval : Double ;
          Var ReadoutTime : Double) : Boolean ;
begin
    end ;




procedure DCAMAPI_Wait( Delay : Single ) ;
begin
    end ;



procedure DCAMAPI_GetImage(
          var Session : TDCAMAPISession  // Camera session record
          ) ;
begin
    end ;

procedure DCAMAPI_StopCapture(
          var Session : TDCAMAPISession   // Camera session record
          ) ;
// ------------------
// Stop image capture
// ------------------
begin

    if not Session.CapturingImages then exit ;

    // Stop capture
    dcam_idle( Session.CamHandle ) ;

    // Release image transfer buffers
    dcam_releasebuffer( Session.CamHandle ) ;

    Session.CapturingImages := False ;

    end ;

procedure DCAMAPI_CheckError(
          FuncName : String ;   // Name of function called
          ErrNum : Integer      // Error # returned by function
          ) ;
begin
    end ;


procedure DCAMAPI_SetProperty(
          var Session : TDCAMAPISession ;   // Camera session record
          iProperty : Integer ;
          Value : Double                    // Property value
          ) ;
// -------------------
// Set camera property
// -------------------
var
   iProp,Err : Integer ;
   Done : Boolean ;
begin

     Exit ;

     if @dcam_getnextpropertyid = Nil then Exit ;

     // If is property supported, update it

     iProp := 0 ;
     Done := False ;
     While not Done do begin
         dcam_getnextpropertyid( Session.CamHandle, iProp, DCAMPROP_OPTION_SUPPORT ) ;
         if iProp = iProperty then begin
            dcam_setpropertyvalue( Session.CamHandle, iProperty, Value ) ;
            Done := True ;
            end
         else if iProp = 0 then Done := True ;
         end ;


    end ;

end.
