unit QCAMUnit;
// ----------------
// QImaging cameras
// ----------------
// 1/4/2006
// 21/01/09 AdditionalReadoutTime added to StartCapture
// 12/01/11 Updated to run using V1.9 and later libraries
// 10/02/11 QCam_SetStreaming now called after QCAM_ABort
//          in StopCapture to avoid camera busy error with Rolera
// 18/07/12 Now works with Rolera XR (QCAM_ReadDefaultSettings was required when camera opened)
//          Error checks added. Checked with QCAM library v2.0.12
// 19/07/12 Exposure time in triggered frame capture mode reduced to 90% of frame interval
//          to avoid missed triggered when acquiring at high speed.
// 25.07.12 5ms added to ReadoutTime reported by QCAMAPI_CheckROIBoundaries when camera in
//          external trigger mode (to avoid speeds where triggers are missed)
interface

uses WinTypes,sysutils, classes, dialogs, mmsystem, messages, controls, math ;

const

    QCAMMaxFrames = 64 ;

        qcCameraUnknown         = 0;
        qcCameraMi2             = 1;        // MicroImager II and Retiga 1300
        qcCameraPmi             = 2;
        qcCameraRet1350         = 3;        // Retiga EX
        qcCameraQICam           = 4;

        // Current hardware
        qcCameraRet1300B        = 5;
        qcCameraRet1350B        = 6;        // Retiga EXi
        qcCameraQICamB          = 7;        // QICam
        qcCameraMicroPub        = 8;        // Micropublisher
        // (returns this for both legacy
        // and current models)
        qcCameraRetIT           = 9;
        qcCameraQICamIR         = 10;       // QICam IR
        qcCameraRochester       = 11;

        qcCameraRet4000R        = 12;       // Retiga 4000R

        qcCameraRet2000R        = 13;       // Retiga 2000R

        qcCameraRoleraXR        = 14;       // Rolera XR

        qcCameraRetigaSRV       = 15;       // Retiga SRV


        qcCameraOem3            = 16;

        qcCameraRoleraMGi       = 17;       // Rolera MGi

        qcCameraRet4000RV       = 18;       // Retiga 4000RV

        qcCameraRet2000RV       = 19;       // Retiga 2000RV

        qcCameraOem4            = 20;

        qcCameraGo1             = 21;       // USB CMOS camera

        qcCameraGo3             = 22;       // USB CMOS camera

        qcCameraGo5             = 23;       // USB CMOS camera

        qcCameraGo21            = 24;       // USB CMOS camera

        qcCameraRoleraEMC2      = 25;

        qcCameraRetigaEXL       = 26;

        qcCameraRoleraXRL       = 27;

        qcCameraRetigaSRVL      = 28;

        qcCameraRetiga4000DC    = 29;

        qcCameraRetiga2000DC    = 30;

        qcCameraEXiBlue         = 31;

        qcCameraEXiAqua         = 32;

        qcCameraRetigaIndigo    = 33;

        qcCameraGoBolt          = 34 ;

        // Reserved numbers
        qcCameraX               = 1000;
        qcCameraOem1            = 1001;
        qcCameraOem2            = 1002;


  qcCCDPixelWidths : Array[0..16] of Single = (
  1.0, {'Unknown',}
  1.0, {'Mi2',}
  9.0, {'Pmi',}
  6.45,{'Retiga 1350'}
  4.65, {'QICam',}
  6.7, {'Retiga 1300B'}
  6.7, {'Retiga 1350B'}
  4.65,{'QICam B',}
  3.4, {'Micropublisher',}
  6.45,{'Retiga Intensified}
  13.7, {'QCAM IR',}
  1.0, {'Rochester',}
  7.4, {'Retiga 4000R',}
  7.4, {''Retiga 2000R',}
  13.7, {Rolera XR}
  6.45, {Retiga SRV}
  1.0 {'Unknown'}
  ) ;

//Public Enum QCam_qcCcdType
    qcCcdMonochrome = 0 ;
    qcCcdColorBayer = 1 ;

// Public Enum QCam_qcCcd
        qcCcdKAF1400        = 0;
        qcCcdKAF1600        = 1;
        qcCcdKAF1600L       = 2;
        qcCcdKAF4200        = 3;
        qcCcdICX085AL       = 4;
        qcCcdICX085AK       = 5;
        qcCcdICX285AL       = 6;
        qcCcdICX285AK       = 7;
        qcCcdICX205AL       = 8;
        qcCcdICX205AK       = 9;
        qcCcdICX252AQ       = 10;
        qcCcdS70311006      = 11;
        qcCcdICX282AQ       = 12;
        qcCcdICX407AL       = 13;
        qcCcdS70310908      = 14;
        qcCcdVQE3618L       = 15;
        qcCcdKAI2001gQ      = 16;
        qcCcdKAI2001gN      = 17;
        qcCcdKAI2001MgAR    = 18;
        qcCcdKAI2001CMgAR   = 19;
        qcCcdKAI4020gN      = 20;
        qcCcdKAI4020MgAR    = 21;
        qcCcdKAI4020MgN     = 22;
        qcCcdKAI4020CMgAR   = 23;
        qcCcdKAI1020gN      = 24;
        qcCcdKAI1020MgAR    = 25;
        qcCcdKAI1020MgC     = 26;
        qcCcdKAI1020CMgAR   = 27;
        qcCcdKAI2001MgC     = 28;
        qcCcdKAI2001gAR     = 29;
        qcCcdKAI2001gC      = 30;
        qcCcdKAI2001MgN     = 31;
        qcCcdKAI2001CMgC    = 32;
        qcCcdKAI2001CMgN    = 33;
        qcCcdKAI4020MgC     = 34;
        qcCcdKAI4020gAR     = 35;
        qcCcdKAI4020gQ      = 36;
        qcCcdKAI4020gC      = 37;
        qcCcdKAI4020CMgC    = 38;
        qcCcdKAI4020CMgN    = 39;
        qcCcdKAI1020gAR     = 40;
        qcCcdKAI1020gQ      = 41;
        qcCcdKAI1020gC      = 42;
        qcCcdKAI1020MgN     = 43;
        qcCcdKAI1020CMgC    = 44;
        qcCcdKAI1020CMgN    = 45;

        qcCcdKAI2020MgAR    = 46;
        qcCcdKAI2020MgC     = 47;
        qcCcdKAI2020gAR     = 48;
        qcCcdKAI2020gQ      = 49;
        qcCcdKAI2020gC      = 50;
        qcCcdKAI2020MgN     = 51;
        qcCcdKAI2020gN      = 52;
        qcCcdKAI2020CMgAR   = 53;
        qcCcdKAI2020CMgC    = 54;
        qcCcdKAI2020CMgN    = 55;

        qcCcdKAI2021MgC     = 56;
        qcCcdKAI2021CMgC    = 57;
        qcCcdKAI2021MgAR    = 58;
        qcCcdKAI2021CMgAR   = 59;
        qcCcdKAI2021gAR     = 60;
        qcCcdKAI2021gQ      = 61;
        qcCcdKAI2021gC      = 62;
        qcCcdKAI2021gN      = 63;
        qcCcdKAI2021MgN     = 64;
        qcCcdKAI2021CMgN    = 65;

        qcCcdKAI4021MgC     = 66;
        qcCcdKAI4021CMgC    = 67;
        qcCcdKAI4021MgAR    = 68;
        qcCcdKAI4021CMgAR   = 69;
        qcCcdKAI4021gAR     = 70;
        qcCcdKAI4021gQ      = 71;
        qcCcdKAI4021gC      = 72;
        qcCcdKAI4021gN      = 73;
        qcCcdKAI4021MgN     = 74;
        qcCcdKAI4021CMgN    = 75;
        qcCcdKAF3200M       = 76;
        qcCcdKAF3200ME      = 77;
        qcCcdE2v97B         = 78;
        qcCMOS              = 79;
        qcCcdTX285          = 80;

        qcCcdKAI04022MgC    = 81;
        qcCcdKAI04022CMgC   = 82;
        qcCcdKAI04022MgAR   = 83;
        qcCcdKAI04022CMgAR  = 83;
        qcCcdKAI04022gAR    = 85;
        qcCcdKAI04022gQ     = 86;
        qcCcdKAI04022gC     = 87;
        qcCcdKAI04022gN     = 88;
        qcCcdKAI04022MgN    = 89;
        qcCcdKAI04022CMgN   = 90;

        qcCcd_last          = 91;
        qcCcdX              = 255;   // Reserved

// Intensifier Model
        qcItVsStdGenIIIA    = 0;
        qcItVsEbGenIIIA     = 1;
        qcIt_last           = 2;

//Public Enum QCam_qcBayerPattern
        qcBayerRGGB         = 0;
        qcBayerGRBG         = 1;
        qcBayerGBRG         = 2;
        qcBayerBGGR         = 3;
        qcBayer_last        = 4;


//Public Enum QCam_qcTriggerType
    qcTriggerFreerun = 0 ;
    qcTriggerNone = 0 ;
    qcTriggerEdgeHi = 1 ;
    qcTriggerEdgeLow = 2 ;
    qcTriggerPulseHi = 3 ;
    qcTriggerPulseLow = 4 ;
  	qcTriggerSoftware	= 5 ;
   	qcTriggerStrobeHi	= 6 ;		// Integrate over pulse without masking
	  qcTriggerStrobeLow = 7 ;
    qcTrigger_last      = 8;

//Public Enum QCam_qcWheelColor
    qcWheelRed = 0 ;
    qcWheelGreen = 1 ;
    qcWheelBlack = 2 ;
    qcWheelBlue = 3 ;
    qcWheel_last = 4 ;

//Public Enum QCam_qcReadoutSpeed
    qcReadout20M        = 0;
    qcReadout10M        = 1;
    qcReadout5M         = 2;
    qcReadout2M5        = 3;
    qcReadout1M         = 4;
    qcReadout24M        = 5;
    qcReadout48M        = 6;
    qcReadout40M        = 7;
    qcReadout30M        = 8;
    qcReadout_last      = 9;

    qcReadoutSpeeds : array[0..qcReadout_last-1] of Single
    = ( 20.0, 10.0, 5.0, 2.5, 1.0, 24.0, 48.0, 40.0, 30.0 ) ;

// Readout port
        qcPortNormal        = 0;
        qcPortEM            = 1;
        qcReadoutPort_last  = 2;

//Public Enum QCam_qcShutterControl
    qcShutterAuto = 0 ;
    qcShutterClose = 1 ;
    qcShutterOpen = 2 ;
    qcShutter_last = 3 ;

	qcCallbackDone			= 1 ;	// Callback when QueueFrame (or QueueSettings) is done
	qcCallbackExposeDone	= 2 ;		// Callback when exposure done (readout starts);

// RTV Mode
        qmdStandard             = 0;    // Default camera mode
        qmdRealTimeViewing      = 1;    // Real Time Viewing (RTV) mode, for MicroPublisher only
        qmdOverSample           = 2;    // A mode where you may snap Oversampled images from supported cameras
        qmd_last                = 3;
        _qmd_force32            = $FFFFFFFF;

// CCD Clearing Mode
        qcPreFrameClearing      = 0;    // Default mode, clear CCD before next exposure starts
        qcNonClearing           = 1;    // Do not clear CCD before next exposure starts


// Fan Control Speed
        qcFanSpeedLow           = 1;
        qcFanSpeedMedium        = 2;
        qcFanSpeedHigh          = 3;
        qcFanSpeedFull          = 4;

//Public Enum QCam_Err
        qerrSuccess             = 0;
        qerrNotSupported        = 1;    // Function is not supported for this device
        qerrInvalidValue        = 2;    // A parameter used was invalid
        qerrBadSettings         = 3;    // The QCam_Settings structure is corrupted
        qerrNoUserDriver        = 4;
        qerrNoFirewireDriver    = 5;    // Firewire device driver is missing
        qerrDriverConnection    = 6;
        qerrDriverAlreadyLoaded = 7;    // The driver has already been loaded
        qerrDriverNotLoaded     = 8;    // The driver has not been loaded.
        qerrInvalidHandle       = 9;    // The QCam_Handle has been corrupted
        qerrUnknownCamera       = 10;   // Camera model is unknown to this version of QCam
        qerrInvalidCameraId     = 11;   // Camera id used in QCam_OpenCamera is invalid
        qerrNoMoreConnections   = 12;   // Deprecated
        qerrHardwareFault       = 13;
        qerrFirewireFault       = 14;
        qerrCameraFault         = 15;
        qerrDriverFault         = 16;
        qerrInvalidFrameIndex   = 17;
        qerrBufferTooSmall      = 18;   // Frame buffer (pBuffer) is too small for image
        qerrOutOfMemory         = 19;
        qerrOutOfSharedMemory   = 20;
        qerrBusy                = 21;   // The function used cannot be processed at this time
        qerrQueueFull           = 22;   // The queue for frame and settings changes is full
        qerrCancelled           = 23;
        qerrNotStreaming        = 24;   // The function used requires that streaming be on
        qerrLostSync            = 25;   // The host and the computer are out of sync; the frame returned is invalid
        qerrBlackFill           = 26;   // Data is missing in the frame returned
        qerrFirewireOverflow    = 27;   // The host has more data than it can process; restart streaming.
        qerrUnplugged           = 28;   // The camera has been unplugged or turned off
        qerrAccessDenied        = 29;   // The camera is already open
        qerrStreamFault         = 30;   // Stream allocation failed; there may not be enough bandwidth
        qerrQCamUpdateNeeded    = 31;   // QCam needs to be updated
        qerrRoiTooSmall         = 32;   // The ROI used is too small
        qerr_last               = 33;
        _qerr_force32           = $FFFFFFFF;

// Image Format
//
// The name of the RGB format indicates how to interpret the data.
// Example: Xrgb32 means the following:
// Byte 1: Alpha (filled to be opaque, since it's not used)
// Byte 2: Red
// Byte 3: Green
// Byte 4: Blue
// The 32 corresponds to 32 bits (4 bytes)
//
// Note: The endianess of the data will be consistent with
// the processor used.
// x86/x64 = Little Endian
// PowerPC = Big Endian
// More information can be found at http://en.wikipedia.org/wiki/Endianness
//
// Note: - On color CCDs, 1x1 binning requires a bayer format (ex: qfmtBayer8)
//       - On color CCDs, binning higher than 1x1 requires a mono format (ex: qfmtMono8)
//       - Choosing a color format on a mono CCD will return a 3-shot RGB filter image
//
        qfmtRaw8                = 0;    // Raw CCD output (this format is not supported)
        qfmtRaw16               = 1;    // Raw CCD output (this format is not supported)
        qfmtMono8               = 2;    // Data is bytes
        qfmtMono16              = 3;    // Data is shorts; LSB aligned
        qfmtBayer8              = 4;    // Bayer mosaic; data is bytes
        qfmtBayer16             = 5;    // Bayer mosaic; data is shorts; LSB aligned
        qfmtRgbPlane8           = 6;    // Separate color planes
        qfmtRgbPlane16          = 7;    // Separate color planes
        qfmtBgr24               = 8;    // Common Windows format
        qfmtXrgb32              = 9;    // Format of Mac pixelmap
        qfmtRgb48               = 10;
        qfmtBgrx32              = 11;   // Common Windows format
        qfmtRgb24               = 12;   // RGB with no alpha
        qfmt_last               = 13;
    qcImageFormats : Array[0..qfmt_last-1] of String = (
                     'Raw (8 bit)',
                     'Raw (16 bit)',
                     'Monochrome (8 bit)',
                     'Monochrome (16 bit)',
                     'Bayer (8 bit)',
                     'Bayer (16 bit)',
                     'RGB plane (8 bit)',
                     'RGB plane (16 bit)',
                     'BGR (24 bit)',
                     'XRGB (32 bit)',
                     'RGB (48 bit)',
                     'BGRX32',
                     'RGB24' ) ;

//Public Enum QCam_Param

        qprmGain                        = 0;    // Deprecated
        qprmOffset                      = 1;    // Deprecated
        qprmExposure                    = 2;    // Exposure in microseconds
        qprmBinning                     = 3;    // Symmetrical binning	(ex: 1x1 or 4x4)
        qprmHorizontalBinning           = 4;    // Horizonal binning	(ex: 2x1)
        qprmVerticalBinning             = 5;    // Vertical binning		(ex: 1x4)
        qprmReadoutSpeed                = 6;    // Readout speed (see QCam_qcReadoutSpeed)
        qprmTriggerType                 = 7;    // Trigger type (see QCam_qcTriggerType)
        qprmColorWheel                  = 8;    // Manual control of current RGB filter wheel color
        qprmCoolerActive                = 9;    // 1 turns cooler on; 0 turns off
        qprmExposureRed                 = 10;   // For RGB filter mode; exposure (us) of red shot
        qprmExposureBlue                = 11;   // For RGB filter mode; exposure (us) of blue shot
        qprmImageFormat                 = 12;   // Image format (see QCam_ImageFormat)
        qprmRoiX                        = 13;   // Upper left X coordinate of the ROI
        qprmRoiY                        = 14;   // Upper left Y coordinate of the ROI
        qprmRoiWidth                    = 15;   // Width of ROI; in pixels
        qprmRoiHeight                   = 16;   // Height of ROI; in pixels
        qprmReserved1                   = 17;
        qprmShutterState                = 18;   // Shutter position
        qprmReserved2                   = 19;
        qprmSyncb                       = 20;   // Output type for SyncB port (see QCam_qcSyncb)
        qprmReserved3                   = 21;
        qprmIntensifierGain             = 22;   // Deprecated
        qprmTriggerDelay                = 23;   // Trigger delay in nanoseconds
        qprmCameraMode                  = 24;   // Camera mode (see QCam_Mode)
        qprmNormalizedGain              = 25;   // Normalized camera gain (micro units)
        qprmNormIntensGaindB            = 26;   // Normalized intensifier gain dB (micro units)
        qprmDoPostProcessing            = 27;   // Turns post processing on and off; 1 = On 0 = Off
        qprmPostProcessGainRed          = 28;   // Post processing red gain
        qprmPostProcessGainGreen        = 29;   // Post processing green gain
        qprmPostProcessGainBlue         = 30;   // Post processing blue gain
        qprmPostProcessBayerAlgorithm   = 31;   // Post processing bayer algorithm to use (see QCam_qcBayerInterp in QCamImgfnc.h)
        qprmPostProcessImageFormat      = 32;   // Post processing image format
        qprmFan                         = 33;   // Fan speed (see QCam_qcFanSpeed)
        qprmBlackoutMode                = 34;   // Blackout mode; 1 turns all lights off; 0 turns them back on
        qprmHighSensitivityMode         = 35;   // High sensitivity mode; 1 turns high sensitivity mode on; 0 turns it off
        qprmReadoutPort                 = 36;   // The readout port (see QCam_qcReadoutPort)
        qprmEMGain                      = 37;   // EM (Electron Multiplication) Gain
        qprmOpenDelay                   = 38;   // Open delay for the shutter.  Range is 0-419.43ms.  Must be smaller than expose time - 10us.  (micro units)
        qprmCloseDelay                  = 39;   // Close delay for the shutter.  Range is 0-419.43ms.  Must be smaller than expose time - 10us.  (micro units)
        qprmCCDClearingMode             = 40;   // CCD clearing mode (see QCam_qcCCDClearingModes)
        qprmOverSample                  = 41;   // set the oversample mode; only available on qcCameraGo21
        qprmReserved5                   = 42;
        qprmReserved6                   = 43;
        qprmReserved7                   = 44;
        qprmReserved4                   = 45;   // QImaging OEM reserved parameter
        qprmReserved8                   = 46;   // QImaging OEM reserved parameter
        qprmEasyEmMode                  = 47;
        qprmLockedGainMode              = 48;
        qprmEasyEmGainValue10           = 49;
        qprmEasyEmGainValue20           = 50;
        qprmEasyEmGainValue40           = 51;
        qprm_last                       = 52;
        _qprm_force32                   = $FFFFFFFF;


// Camera Parameters - Signed 32 bit
//
// For use with QCam_GetParamS32,
//				QCam_GetParamS32Min
//				QCam_GetParamS32Max
//				QCam_SetParamS32
//				QCam_GetParamSparseTableS32
//				QCam_IsSparseTableS32
//				QCam_IsRangeTableS32
//				QCam_IsParamS32Supported
//
        qprmS32NormalizedGaindB     = 0;    // Normalized camera gain in dB (micro units)
        qprmS32AbsoluteOffset       = 1;    // Absolute camera offset
        qprmS32RegulatedCoolingTemp = 2;    // Regulated cooling temperature (C)
        qprmS32_last                = 3;
        _qprmS32_force32            = $FFFFFFFF;

// Camera Parameters - Unsigned 64 bit
//
// For use with QCam_GetParam64,
//				QCam_GetParam64Min
//				QCam_GetParam64Max
//				QCam_SetParam64
//				QCam_GetParamSparseTable64
//				QCam_IsSparseTable64
//				QCam_IsRangeTable64
//				QCam_IsParam64Supported
//
        qprm64Exposure          = 0;    // Exposure in nanoseconds
        qprm64ExposureRed       = 1;    // For RGB filter mode, exposure (nanoseconds) of red shot
        qprm64ExposureBlue      = 2;    // For RGB filter mode, exposure (nanoseconds) of blue shot
        qprm64NormIntensGain    = 3;    // Normalized intensifier gain (micro units)
        qprm64_last             = 4;
        _qprm64_force32         = $FFFFFFFF;


//Public Enum QCam_Info
        qinfCameraType              = 0;    // Camera model (see QCam_qcCameraType)
        qinfSerialNumber            = 1;    // Deprecated
        qinfHardwareVersion         = 2;    // Hardware version
        qinfFirmwareVersion         = 3;    // Firmware version
        qinfCcd                     = 4;    // CCD model (see QCam_qcCcd)
        qinfBitDepth                = 5;    // Maximum bit depth
        qinfCooled                  = 6;    // Returns 1 if cooler is available; 0 if not
        qinfReserved1               = 7;    // Reserved
        qinfImageWidth              = 8;    // Width of the ROI (in pixels)
        qinfImageHeight             = 9;    // Height of the ROI (in pixels)
        qinfImageSize               = 10;   // Size of returned image (in bytes)
        qinfCcdType                 = 11;   // CDD type (see QCam_qcCcdType)
        qinfCcdWidth                = 12;   // CCD maximum width
        qinfCcdHeight               = 13;   // CCD maximum height
        qinfFirmwareBuild           = 14;   // Build number of the firmware
        qinfUniqueId                = 15;   // Same as uniqueId in QCam_CamListItem
        qinfIsModelB                = 16;   // Cameras manufactured after March 1; 2004 return 1; otherwise 0
        qinfIntensifierModel        = 17;   // Intensifier tube model (see QCam_qcIntensifierModel)
        qinfExposureRes             = 18;   // Exposure time resolution (nanoseconds)
        qinfTriggerDelayRes         = 19;   // Trigger delay Resolution (nanoseconds)
        qinfStreamVersion           = 20;   // Streaming version
        qinfNormGainSigFigs         = 21;   // Normalized Gain Significant Figures resolution
        qinfNormGaindBRes           = 22;   // Normalized Gain dB resolution (in micro units)
        qinfNormITGainSigFigs       = 23;   // Normalized Intensifier Gain Significant Figures
        qinfNormITGaindBRes         = 24;   // Normalized Intensifier Gain dB resolution (micro units)
        qinfRegulatedCooling        = 25;   // 1 if camera has regulated cooling
        qinfRegulatedCoolingLock    = 26;   // 1 if camera is at regulated temperature; 0 otherwise
        qinfFanControl              = 29;   // 1 if camera can control fan speed
        qinfHighSensitivityMode     = 30;   // 1 if camera has high sensitivity mode available
        qinfBlackoutMode            = 31;   // 1 if camera has blackout mode available
        qinfPostProcessImageSize    = 32;   // Returns the size (in bytes) of the post-processed image
        qinfAsymmetricalBinning     = 33;   // 1 if camera has asymmetrical binning (ex: 2x4)
        qinfEMGain                  = 34;   // 1 if EM gain is supported; 0 if not
        qinfOpenDelay               = 35;   // 1 if shutter open delay controls are available; 0 if not
        qinfCloseDelay              = 36;   // 1 if shutter close delay controls are available; 0 if not
        qinfColorWheelSupported     = 37;   // 1 if color wheel is supported; 0 if not
        qinfReserved2               = 38;
        qinfReserved3               = 39;
        qinfReserved4               = 40;
        qinfReserved5               = 41;
        qinfEasyEmModeSupported     = 42;   // 1 if camera supports Easy EM mode
        qinfLockedGainModeSupported = 43;
        qinf_last                   = 44;
        _qinf_force32               = $FFFFFFFF ;



type

  TQCam_SettingsOld = packed record
    size : Integer ;
    private_data : Array[0..63] of Integer ;
    end ;

{TQCam_Settings = packed record
     size : Integer ;
     p1 : Pointer ;
     p2 : Pointer ;
     end ;}

  TQCam_Settings = packed record
        size : Integer ;                   // Filled by the initialization routine
        f1 : Integer ;
    		f2 : SmallInt ;
     		f3 : SmallInt ;
		    f4 : Array[0..7] of char ;
        private_data : Pointer ;			// Pointer to a camera settings array
        padding : array[0..63] of Integer ;
        end ;

   TQCam_Frame = packed record
     pBuffer : Pointer ;
     bufferSize : Integer ;
     format : Integer ;
     width : Integer ;
     height : Integer ;
     size : Integer ;
     bits : SmallInt ;
     FrameNumber : SmallInt ;
     bayerPattern : Integer ;
     ErrorCode : Integer ;
     TimeStamp : Integer ;
     reserved : Array[0..7] of Integer ;
     end ;

  TQCAMSession = record
     CamHandle : Integer ;
     CameraType : Integer ;
     NumBytesPerFrame : Integer ;     // No. of bytes in image
     NumPixelsPerFrame : Integer ;    // No. of pixels in image
     NumFrames : Integer ;            // No. of images in circular transfer buffer
     FrameNum : Integer ;             // Current frame no.
     PFrameBuffer : Pointer ;         // Frame buffer pointer
     NumFramesAcquired : Integer ;
     NumFramesCopied : Integer ;
     CapturingImages : Boolean ;     // Image capture in progress
     CameraOpen : Boolean ;          // Camera open for use
     TimeStart : single ;
     Temperature : Integer ;
     FrameTransferTime : Single ;    // Frame transfer time (s)
     QCamSettings : TQCam_Settings ;
     FrameList : Array[0..QCAMMaxFrames-1] of TQCam_Frame ;
     Counter : Integer ;
     Gains : Array[0..99] of Double ;
     NumGains : Integer ;
     BinFactors : Array[0..99] of Integer ;
     NumBinFactors : Integer ;
     ReadoutSpeeds : Array[0..99] of Integer ;
     NumReadoutSpeeds : Integer ;
     end ;


   TQCam_CamListItem = packed record
      cameraId : Integer ;
      cameraType : Integer ;
      uniqueId : Integer ;
      isOpen : LongBool ;
      reserved : Array[0..9] of Integer ;
      end ;

TQCam_Abort = function(
              handle: Integer
              )  : Integer ; stdcall ;

TQCam_LoadDriver = function : Integer ; stdcall ;

TQCam_ReleaseDriver = procedure; stdcall ;

TQCam_LibVersion = function(
                    var verMajor : Word ;
                    var verMinor : Word ;
                    var BuildNum : Word
                    ) : Integer ; stdcall ;

TQCam_ListCameras = function(
                    pList : Pointer ;
                    pnumberInList : Pointer
                    )  : Integer ; stdcall ;

TQCam_OpenCamera = function(
                   cameraId: Integer ;
                   var handle: Integer
                   ) : Integer ; stdcall ;

TQCam_CloseCamera = function(
                    handle: Integer
                    )  : Integer ; stdcall ;

TQCam_GetInfo = function(
                handle: Integer ;
                infoKey : Integer ;
                var value: Integer
                )  : Integer ; stdcall ;

TQCam_CreateCameraSettingsStruct = function(
       var settings : TQCam_Settings
       )  : Integer ; stdcall ;

TQCam_InitializeCameraSettings = function(
       Handle: Integer ;
       var settings : TQCam_Settings
       )  : Integer ; stdcall ;

TQCam_ReleaseCameraSettingsStruct = function(
       var settings : TQCam_Settings
       )  : Integer ; stdcall ;

TQCam_ReadDefaultSettings = function(
      Handle: Integer ;
      var settings : TQCam_Settings
      )  : Integer ; stdcall ;

TQCam_ReadSettingsFromCam = function(
      handle: Integer ;
      var settings : TQCam_Settings
      )  : Integer ; stdcall ;

TQCam_SendSettingsToCam = function(
      handle: Integer ;
      var settings : TQCam_Settings
      ) : Integer ; stdcall ;

TQCam_TranslateSettings = function(
      handle: Integer ;
      var settings : TQCam_Settings
      )  : Integer ; stdcall ;

TQCam_PreflightSettings = function(
      handle: Integer ;
      settings : Pointer
      )  : Integer ; stdcall ;

TQCam_GetParam = function(
      var settings : TQCam_Settings ;
      paramKey  : Integer ;
      var value: Integer
      ) : Integer ; stdcall ;

TQCam_SetParam = function(
      var settings : TQCam_Settings ;
      paramKey  : Integer ;
      value: Integer
      )  : Integer ; stdcall ;

TQCam_SetParamS32 = function(
      var settings : TQCam_Settings ;
      paramKey  : Integer ;
      value: Integer
      )  : Integer ; stdcall ;

TQCam_SetParam64 = function(
      var settings : TQCam_Settings ;
      paramKey  : Integer ;
      value: Int64
      )  : Integer ; stdcall ;


TQCam_GetParamMin = function(
                   var settings : TQCam_Settings ;
                   paramKey  : Integer ;
                   var Value: Integer
                   )  : Integer ; stdcall ;

TQCam_GetParamMax = function(
                    var settings : TQCam_Settings ;
                    paramKey  : Integer ;
                    var value: Integer
                    )  : Integer ; stdcall ;

TQCam_GetParam64Min = function(
                   var settings : TQCam_Settings ;
                   paramKey  : Integer ;
                   var Value: Int64
                   )  : Integer ; stdcall ;

TQCam_GetParam64Max = function(
                    var settings : TQCam_Settings ;
                    paramKey  : Integer ;
                    var value: Int64
                    )  : Integer ; stdcall ;

TQCam_GetParamSparseTable = function(
                            var settings : TQCam_Settings ;
                            paramKey  : Integer ;
                            pTable : Pointer ;
                            var NumItems : Integer
                            )  : Integer ; stdcall ;

TQCam_IsRangeTable64 = function(
                    var settings : TQCam_Settings ;
                    paramKey  : Integer
                    )  : Integer ; stdcall ;

TQCam_GrabFrame = function(
                  handle: Integer ;
                  var frame : TQCam_Frame
                  ) : Integer ; stdcall ;

TQCam_SetFrameBuffers = function(
                        handle: Integer ;
                        var frames : Array of TQCam_Frame ;
                        number: Integer
                        )  : Integer ; stdcall ;

TQCam_SetStreaming = function(
                     handle: Integer ;
                     enable: Integer
                     )  : Integer ; stdcall ;

TQCam_GrabFrameNow = function(
                    handle: Integer ;
                    frameIndex : Integer
                    )  : Integer ; stdcall ;

TQCam_GrabRawNow = function(
                   handle: Integer ;
                   frameIndex: Integer
                   )  : Integer ; stdcall ;

TQCam_ProcessRaw = function(
                   handle: Integer ;
                   frameIndex: Integer
                   )  : Integer ; stdcall ;

TQCam_QueueFrame = function(
                   handle: Integer ;      // IN: handle to camera
                   FramePtr : Pointer ;   // IN: frame
                   CallBackPtr : Pointer ;  // IN: completion callback; can be NULL
                   cbFlags : Cardinal ;     // IN: qcCallbackFlags
                   UserPtr : Pointer ;      // IN: user specified value for callback
                   UserData : Cardinal      // IN: user specified value for callback
                   )  : Integer ; stdcall ;

TQCam_QueueSettings = function(
                   handle: Integer ;      // IN: handle to camera
                   FramePtr : Pointer ;   // IN: frame
                   CallBackPtr : Pointer ;  // IN: completion callback; can be NULL
                   cbFlags : Cardinal ;     // IN: qcCallbackFlags
                   UserPtr : Pointer ;      // IN: user specified value for callback
                   UserData : Cardinal      // IN: user specified value for callback
                   )  : Integer ; stdcall ;

TQCam_IsParamSupported = function(
                         handle: Integer ;      // IN: handle to camera
                         paramKey  : Integer
                         )  : Integer ; stdcall ;

TQCam_IsSparseTable = function(
                         var settings : TQCam_Settings ;
                         paramKey  : Integer
                         )  : Integer ; stdcall ;

TQCam_IsRangeTable = function(
                         var settings : TQCam_Settings ;
                         paramKey  : Integer
                         ) : Integer ; stdcall ;

function QCAMAPI_LoadLibrary : Boolean ;
function QCAMAPI_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;

function QCAMAPI_OpenCamera(
          var Session : TQCAMSession ;   // Camera session record
          var FrameWidthMax : Integer ;      // Returns camera frame width
          var FrameHeightMax : Integer ;     // Returns camera frame width
          var NumBytesPerPixel : Integer ;   // Returns bytes/pixel
          var PixelDepth : Integer ;         // Returns no. bits/pixel
          var PixelWidth : Single ;          // Returns pixel size (um)
          CameraInfo : TStringList         // Returns Camera details
          ) : Boolean ;

procedure QCAMAPI_CloseCamera(
          var Session : TQCAMSession // Session record
          ) ;

procedure QCAMAPI_GetCameraGainList(
          var Session : TQCAMSession ;   // Camera session record
          CameraGainList : TStringList
          ) ;

procedure QCAMAPI_GetCameraReadoutSpeedList(
          var Session : TQCAMSession ;   // Camera session record
          CameraReadoutSpeedList : TStringList
          ) ;

function QCAMAPI_StartCapture(
         var Session : TQCAMSession ;   // Camera session record
         var InterFrameTimeInterval : Double ;      // Frame exposure time
         AdditionalReadoutTime : Double ; // Additional readout time (s)
         AmpGain : Integer ;              // Camera amplifier gain index
         ReadoutSpeed : Integer ;         // Camera Read speed index number
         ExternalTrigger : Integer ;      // Trigger mode
         FrameLeft : Integer ;            // Left pixel in CCD readout area
         FrameRight : Integer ;           // Right pixel in CCD eadout area
         FrameTop : Integer ;             // Top of CCD readout area
         FrameBottom : Integer ;          // Bottom of CCD readout area
         BinFactor : Integer ;             // Binning factor (1,2,4,8,16)
         PFrameBuffer : Pointer ;         // Pointer to start of ring buffer
         NumFramesInBuffer : Integer ;    // No. of frames in ring buffer
         NumBytesPerFrame : Integer ;      // No. of bytes/frame
         CCDClearPreExposure : Boolean
         ) : Boolean ;

procedure QCAMAPI_CheckROIBoundaries(
          var Session : TQCAMSession ;   // Camera session record
          var ReadoutSpeed : Integer ;
         var FrameLeft : Integer ;            // Left pixel in CCD readout area
         var FrameRight : Integer ;           // Right pixel in CCD eadout area
         var FrameTop : Integer ;             // Top of CCD readout area
         var FrameBottom : Integer ;          // Bottom of CCD readout area
         var  BinFactor : Integer ;   // Pixel binning factor (In)
         var FrameWidth : Integer ;
         var FrameHeight : Integer ;
         ExternalTrigger : Integer ;         // True = camera in External trigger mode
         var FrameInterval : Double ;
         var ReadoutTime : Double ) ;

procedure QCAMAPI_Wait( Delay : Single ) ;


procedure QCAMAPI_GetImage(
          var Session : TQCAMSession  // Camera session record
          ) ;

procedure QCAMAPI_StopCapture(
          var Session : TQCAMSession   // Camera session record
          ) ;

procedure QCAMAPI_CheckError(
          FuncName : String ;   // Name of function called
          ErrNum : Integer      // Error # returned by function
          ) ;

procedure FrameDoneCallBack(
         UsrPtr : Pointer ;
         UserData : Cardinal ;
         ErrCode : Integer ;
         Flags : Cardinal ) ; stdcall ;

procedure QCAMAPI_SetCooling(
          var Session : TQCAMSession ; // Session record
          CoolingOn : Boolean  // True = Cooling is on
          ) ;

procedure QCAMAPI_SetTemperature(
          var Session : TQCAMSession ; // Session record
          var TemperatureSetPoint : Single  // Required temperature
          ) ;


implementation

uses sescam ;

var

  QCam_Abort : TQCam_Abort ;
  QCam_LoadDriver : TQCam_LoadDriver ;
  QCam_ReleaseDriver : TQCam_ReleaseDriver ;
  QCam_LibVersion : TQCam_LibVersion ;
  QCam_ListCameras : TQCam_ListCameras ;
  QCam_OpenCamera : TQCam_OpenCamera ;
  QCam_CloseCamera : TQCam_CloseCamera ;
  QCam_GetInfo : TQCam_GetInfo ;
  QCam_CreateCameraSettingsStruct : TQCam_CreateCameraSettingsStruct ;
  QCam_InitializeCameraSettings : TQCam_InitializeCameraSettings ;
  QCam_ReleaseCameraSettingsStruct : TQCam_ReleaseCameraSettingsStruct ;
  QCam_ReadDefaultSettings : TQCam_ReadDefaultSettings ;
  QCam_ReadSettingsFromCam : TQCam_ReadSettingsFromCam ;
  QCam_SendSettingsToCam : TQCam_SendSettingsToCam ;
  QCam_TranslateSettings : TQCam_TranslateSettings ;
  QCam_PreflightSettings : TQCam_PreflightSettings ;
  QCam_GetParam : TQCam_GetParam ;
  QCam_SetParam : TQCam_SetParam ;
  QCam_SetParamS32 : TQCam_SetParamS32 ;
  QCam_SetParam64 : TQCam_SetParam64 ;
  QCam_GetParamMin : TQCam_GetParamMin ;
  QCam_GetParamMax : TQCam_GetParamMax ;
  QCam_GetParam64Min : TQCam_GetParam64Min ;
  QCam_GetParam64Max : TQCam_GetParam64Max ;
  QCam_GetParamSparseTable : TQCam_GetParamSparseTable ;
  QCam_IsRangeTable64 : TQCam_IsRangeTable64 ;
  QCam_GrabFrame : TQCam_GrabFrame ;
  QCam_SetFrameBuffers : TQCam_SetFrameBuffers ;
  QCam_SetStreaming : TQCam_SetStreaming ;
  QCam_GrabFrameNow : TQCam_GrabFrameNow ;
  QCam_GrabRawNow : TQCam_GrabRawNow ;
  QCam_ProcessRaw : TQCam_ProcessRaw ;
  QCam_QueueFrame : TQCam_QueueFrame ;
  QCam_QueueSettings : TQCam_QueueSettings ;
  QCam_IsParamSupported : TQCam_IsParamSupported ;
  QCam_IsSparseTable : TQCam_IsSparseTable ;
  QCam_IsRangeTable : TQCam_IsRangeTable ;  


   LibraryLoaded : Boolean ;
   LibraryHnd : THandle ;
   LibraryChildHnd : THandle ;

function QCAMAPI_LoadLibrary  : Boolean ;
{ ---------------------------------------------
  Load camera interface DLL library into memory
  ---------------------------------------------}
var
    LibFileName : string ;
begin

     Result := LibraryLoaded ;

     if LibraryLoaded then Exit ;

     { Load DLL camera interface library }
     LibFileName := 'QCamDriver.dll' ;
     LibraryHnd := LoadLibrary( PChar(LibFileName));
     if LibraryHnd > 0 then LibraryLoaded := True ;

     if not LibraryLoaded then begin
        ShowMessage( 'QCAM: ' + LibFileName + ' not found!' ) ;
        Result := LibraryLoaded ;
        Exit ;
        end ;

     LibraryChildHnd := LoadLibrary( PChar('QCamChildDriver.dll'));

     @QCam_ProcessRaw := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_ProcessRaw') ;
     @QCam_GrabRawNow := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_GrabRawNow') ;
     @QCam_GrabFrameNow := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_GrabFrameNow') ;
     @QCam_SetStreaming := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_SetStreaming') ;
     @QCam_SetFrameBuffers := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_SetFrameBuffers') ;
     @QCam_GrabFrame := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_GrabFrame') ;
     @QCam_GetParamMax := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_GetParamMax') ;
     @QCam_GetParamMin := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_GetParamMin') ;
     @QCam_GetParam64Max := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_GetParam64Max') ;
     @QCam_GetParam64Min := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_GetParam64Min') ;
     @QCam_GetParamSparseTable := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_GetParamSparseTable') ;
     @QCam_IsRangeTable64 := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_IsRangeTable64') ;
     @QCam_SetParam := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_SetParam') ;
     @QCam_SetParamS32 := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_SetParamS32') ;
     @QCam_GetParam := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_GetParam') ;
     @QCam_SetParam64 := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_SetParam64') ;
     @QCam_TranslateSettings := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_TranslateSettings') ;
     @QCam_PreflightSettings := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_PreflightSettings') ;
     @QCam_SendSettingsToCam := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_SendSettingsToCam') ;
     @QCam_ReadSettingsFromCam := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_ReadSettingsFromCam') ;

     @QCam_CreateCameraSettingsStruct := GetProcAddress(LibraryHnd,PChar('QCam_CreateCameraSettingsStruct')) ;
     @QCam_InitializeCameraSettings := GetProcAddress(LibraryHnd,PChar('QCam_InitializeCameraSettings')) ;
     @QCam_ReleaseCameraSettingsStruct := GetProcAddress(LibraryHnd,PChar('QCam_ReleaseCameraSettingsStruct')) ;

     @QCam_ReadDefaultSettings := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_ReadDefaultSettings') ;

     @QCam_GetInfo := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_GetInfo') ;
     @QCam_CloseCamera:= QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_CloseCamera') ;
     @QCam_OpenCamera := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_OpenCamera') ;
     @QCam_ListCameras := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_ListCameras') ;
     @QCam_LibVersion := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_LibVersion') ;
     @QCam_ReleaseDriver := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_ReleaseDriver') ;
     @QCam_LoadDriver := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_LoadDriver') ;
     @QCam_Abort := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_Abort') ;
     @QCam_QueueFrame := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_QueueFrame') ;
     @QCam_QueueSettings := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_QueueSettings');
     @QCam_IsParamSupported := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_IsParamSupported');
     @QCam_IsSparseTable := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_IsSparseTable');
     @QCam_IsRangeTable := QCAMAPI_GetDLLAddress(LibraryHnd,'QCam_IsRangeTable');     

     Result := LibraryLoaded ;

     end ;


function QCAMAPI_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;
// -----------------------------------------
// Get address of procedure within DLL
// -----------------------------------------
begin

    Result := GetProcAddress(Handle,PChar(ProcName)) ;
    if Result = Nil then begin
       ShowMessage('Qcamdriver.dll: ' + ProcName + ' not found') ;
       end ;
    end ;


function QCAMAPI_OpenCamera(
         var Session : TQCAMSession ;   // Camera session record
         var FrameWidthMax : Integer ;      // Returns camera frame width
         var FrameHeightMax : Integer ;     // Returns camera frame width
         var NumBytesPerPixel : Integer ;   // Returns bytes/pixel
         var PixelDepth : Integer ;         // Returns no. bits/pixel
         var PixelWidth : Single ;          // Returns pixel size (um)
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
    Err,i,iValue,iMin,iMax : Integer ;
    iMin64,iMax64 : Int64 ;
    s : String ;
    CameraList : Array[0..9] of TQCam_CamListItem ;
    NumCameras : Integer ;
    VersionMajor, VersionMinor, BuildNum : Word ;
    NumItems : Integer ;
    iTable : Array[0..99] of Integer ;
    Mono16Available : Boolean ;
    Mono8Available : Boolean ;
    CameraType : String ;
begin

     // Load DLL camera control library
     if not QCAMAPI_LoadLibrary then Exit ;

     if QCAM_LoadDriver <> 0 then begin
        ShowMessage('QCAM: Unable to initialise driver!') ;
        Exit ;
        End ;
    

     QCam_LibVersion( VersionMajor, VersionMinor, BuildNum ) ;
     CameraInfo.Add( format( 'QCAM Library V%d.%d (%d)',[VersionMajor, VersionMinor,BuildNum] )) ;
     NumCameras := High(CameraList) ;
     QCAM_ListCameras( @CameraList, @NumCameras ) ;
     if NumCameras <= 0 then begin
        ShowMessage('QCAM: No cameras detected!') ;
        QCAM_ReleaseDriver ;
        Exit ;
        End ;

     if not CameraList[0].IsOpen then begin
        // Open first camera in list
        QCAMAPI_CheckError( 'QCAM_OpenCamera',
           QCAM_OpenCamera( CameraList[0].CameraID, Session.CamHandle )) ;
        end
     else ShowMessage('QCAM: Camera already open!') ;

     // Create structure
     if @QCam_CreateCameraSettingsStruct <> Nil then begin
        QCAMAPI_CheckError( 'QCam_CreateCameraSettingsStruct',
                            QCam_CreateCameraSettingsStruct( Session.QCAMSettings )) ;
        QCAMAPI_CheckError( 'QCam_InitializeCameraSettings',
                            QCam_InitializeCameraSettings( Session.CamHandle, Session.QCAMSettings )) ;
        QCAMAPI_CheckError( 'QCAM_ReadDefaultSettings',
                            QCAM_ReadDefaultSettings( Session.CamHandle,
                            Session.QCAMSettings ) ) ;
        end
     else begin
        // Pre V1.9 driver
        Session.QCAMSettings.size := 65*4 ;
        QCAMAPI_CheckError( 'QCAM_ReadDefaultSettings',
                            QCAM_ReadDefaultSettings( Session.CamHandle,
                            Session.QCAMSettings ) ) ;
        end ;

     // Read settings from camera
     //Session.QCAMSettings.size := Sizeof(Session.QCAMSettings) ;

     QCAMAPI_CheckError( 'QCAM_GetInfo (qinfCameraType)',
                         QCAM_GetInfo( Session.CamHandle, qinfCameraType, Session.CameraType )) ;
     case Session.CameraType of
        qcCameraUnknown : CameraType := 'Unknown' ;
        qcCameraMi2 : begin
            CameraType := 'MicroImager II/Retiga 1300' ;
            PixelWidth := 1.0 ;
            end ;
        qcCameraPmi : begin
            CameraType := 'PMi' ;
            PixelWidth := 9.0 ;
            end ;
        qcCameraRet1350 : begin
            CameraType := 'Retiga EX' ;
            PixelWidth := 6.45 ;
            end ;
        qcCameraQICam : begin
            CameraType := 'QICam' ;
            PixelWidth := 4.65 ;
            end ;
        qcCameraRet1300B : begin
            CameraType := 'Retiga 1300B' ;
            PixelWidth := 6.7 ;
            end ;
        qcCameraRet1350B : begin
            CameraType := 'Retiga EXi';
            PixelWidth := 6.7 ;
            end ;
        qcCameraQICamB : begin
            CameraType := 'QICam' ;
            PixelWidth := 4.65 ;
            end ;
        qcCameraMicroPub : begin
            CameraType := 'Micropublisher' ;
            PixelWidth := 3.4 ;
            end ;
        qcCameraRetIT : begin
            CameraType := 'Retiga IT' ;
            PixelWidth := 6.45 ;
            end ;
        qcCameraQICamIR : begin
            CameraType := 'QICam IR';
            PixelWidth := 13.7 ;
            end ;
        qcCameraRochester : begin
            CameraType := 'Rochester' ;
            end ;
        qcCameraRet4000R : begin
            CameraType := 'Retiga 4000R';
            PixelWidth := 7.4 ;
            end ;
        qcCameraRet2000R : begin
            CameraType := 'Retiga 2000R';
            PixelWidth := 7.4 ;
            end ;
        qcCameraRoleraXR : begin
            CameraType := 'Rolera XR' ;
            PixelWidth := 13.7 ;
            end ;
        qcCameraRetigaSRV : begin
            CameraType := 'Retiga SRV';
            PixelWidth := 6.45 ;
            end ;
        qcCameraOem3 : begin
            CameraType := 'OEM3' ;
            end ;
        qcCameraRoleraMGi : begin
            CameraType := 'Rolera MGi';
            PixelWidth := 16.0 ;
            end ;
        qcCameraRet4000RV : begin
            CameraType := 'Retiga 4000RV';
            PixelWidth := 7.4 ;
            end ;
        qcCameraRet2000RV : begin
            CameraType := 'Retiga 2000RV';
            PixelWidth := 7.4 ;
            end ;
        qcCameraOem4 : begin
            CameraType := 'OEM4';
            end ;
        qcCameraGo1 : begin
            CameraType := 'Go1 USB CMOS camera';
            end ;
        qcCameraGo3 : begin
            CameraType := 'Go3 USB CMOS camera';
            end ;
        qcCameraGo5 : begin
            CameraType := 'Go5 USB CMOS camera';
            end ;
        qcCameraGo21 : begin
            CameraType := 'Go21 USB CMOS camera';
            end ;
        qcCameraRoleraEMC2 : begin
            CameraType := 'Rolera EMC2';
            PixelWidth := 8.0 ;
            end ;
        qcCameraRetigaEXL : begin
            CameraType := 'Retiga EXL';
            PixelWidth := 6.45 ;
            end ;
        qcCameraRoleraXRL : begin
            CameraType := 'Rolera XRL';
            PixelWidth := 12.9 ;
            end ;
        qcCameraRetigaSRVL : begin
            CameraType := 'Retiga SRVL';
            PixelWidth := 6.45 ;
            end ;
        qcCameraRetiga4000DC : begin
            CameraType := 'Retiga 4000DC';
            PixelWidth := 7.4 ;
            end ;
        qcCameraRetiga2000DC : begin
            CameraType := 'Retiga 2000DC';
            PixelWidth := 7.4 ;
            end ;
        qcCameraEXiBlue : begin
            CameraType := 'EXi Blue' ;
            PixelWidth := 6.45 ;
            end ;
        qcCameraEXiAqua : begin
            CameraType := 'EXi Aqua';
            PixelWidth := 6.45 ;
            end ;
        qcCameraRetigaIndigo : begin
            CameraType := 'Retiga Indigo';
            PixelWidth := 6.45 ;
            end ;
        qcCameraX : begin
            CameraType := 'X' ;
            end ;
        qcCameraOem1 : begin
            CameraType := 'OEM1';
            end ;
        qcCameraOem2 : begin
            CameraType := 'OEM2';
            end ;
        qcCameraGoBolt : begin
            CameraType := 'Rolera Bolt';
            PixelWidth := 3.65 ;
            end ;
        else begin
           CameraType := 'Camera type unlisted' ;
           PixelWidth := 1.0 ;
           end ;
        end ;

     CameraInfo.Add( 'Camera: ' + CameraType );

     // Get max. size of camera image
     QCAMAPI_CheckError( 'QCAM_GetInfo (qinfCCDWidth)',
                         QCAM_GetInfo( Session.CamHandle, qinfCCDWidth, FrameWidthMax )) ;
     QCAMAPI_CheckError( 'QCAM_GetInfo (qinfCCDHeight)',
                         QCAM_GetInfo( Session.CamHandle, qinfCCDHeight, FrameHeightMax )) ;

     // Get size of CCD pixel
     //PixelWidth := qcCCDPixelWidths[Min(Max(Session.CameraType,0),High(qcCCDPixelWidths))] ;

     // Get type of CCD
     QCAMAPI_CheckError( 'QCAM_GetInfo (qinfCCDType)',
                          QCAM_GetInfo( Session.CamHandle, qinfCCDType, iValue )) ;

     // Report CCD properties
     CameraInfo.Add( format('CCD: Type%d (%d x %d pixels) %.2f um pixels',
                     [iValue,
                      FrameWidthMax,
                      FrameHeightMax,
                      PixelWidth])) ;

     // Get number of bits per pixel
     QCAMAPI_CheckError( 'QCAM_GetInfo (qinfBitDepth)',
                         QCAM_GetInfo( Session.CamHandle, qinfBitDepth, PixelDepth )) ;
     OutputDebugString(pchar(format('%d',[err])));
     CameraInfo.Add(format( 'Pixel depth: %d bits',[PixelDepth] )) ;

{    qinfCameraType = 0 ;
    qinfSerialNumber = 1 ;
    qinfHardwareVersion = 2 ;
    qinfFirmwareVersion = 3 ;
    qinfCcd = 4 ;
    qinfBitDepth = 5 ;
   qinfCooled = 6 ;
}
     // Cooling availab;e
     QCAM_GetInfo( Session.CamHandle, qinfRegulatedCooling, iValue ) ;
     if iValue <> 0 then CameraInfo.Add( 'Regulated CCD cooling is available' )
     else begin
        QCAM_GetInfo( Session.CamHandle, qinfCooled, iValue ) ;
        if iValue <> 0 then CameraInfo.Add( 'CCD cooling ia available' ) ;
        end ;

     QCAM_GetInfo( Session.CamHandle, qinfFanControl, iValue ) ;
     if iValue <> 0 then CameraInfo.Add( 'Fan speed is controllable' ) ;

     QCAM_GetInfo( Session.CamHandle, qinfEMGain, iValue ) ;
     if iValue <> 0 then CameraInfo.Add( 'EMCCD camera' ) ;

     QCAM_GetInfo( Session.CamHandle, qinfFanControl, iValue ) ;
     if iValue <> 0 then CameraInfo.Add( 'Fan speed is controllable' ) ;

     // Gain range
     if Session.CameraType = qcCameraRetIT then begin
        // Intensified cameras
        QCam_GetParam64Min( Session.QCAMSettings, qprm64NormIntensGain, iMin64 ) ;
        QCam_GetParam64Max( Session.QCAMSettings, qprm64NormIntensGain, iMax64 ) ;
        CameraInfo.Add(format( 'Intensifier Gains: %.0f - %.0f',[iMin64*1E-6,iMax64*1E-6] )) ;
        end
     else begin
        QCAMAPI_CheckError( 'QCam_GetParamMin (qprmNormalizedGain)',
                            QCam_GetParamMin( Session.QCAMSettings, qprmNormalizedGain, iMin )) ;
        QCAMAPI_CheckError( 'QCam_GetParamMax (qprmNormalizedGain)',
                            QCam_GetParamMax( Session.QCAMSettings, qprmNormalizedGain, iMax )) ;
        CameraInfo.Add(format( 'Gains: %.0f - %.0f',[iMin*1E-6,iMax*1E-6] )) ;
        end ;

     // Readout speed range
     Session.NumReadoutSpeeds :=  High(Session.ReadoutSpeeds) ;
     QCAMAPI_CheckError( 'QCam_GetParamSparseTable (qprmReadoutSpeed)',
                         QCam_GetParamSparseTable( Session.QCAMSettings,
                               qprmReadoutSpeed,
                               @Session.ReadoutSpeeds,
                               Session.NumReadoutSpeeds )) ;

     s := 'Readout speeds: ' ;
     for i := 0 to Session.NumReadoutSpeeds-1 do begin
         s := s + format( '%.1f MHz',[qcReadoutSpeeds[Session.ReadoutSpeeds[i]]] ) ;
         if i < (Session.NumReadoutSpeeds-1) then s := s + ', ' ;
         end ;
     CameraInfo.Add( s ) ;

     // Binning factors
     Session.NumBinFactors :=  High(Session.BinFactors) ;
     QCAMAPI_CheckError( 'QCam_GetParamSparseTable (qprmBinning)',
                         QCam_GetParamSparseTable( Session.QCAMSettings,
                               qprmBinning,
                               @Session.BinFactors,
                               Session.NumBinFactors )) ;
     s := 'Binning factors: ' ;
     for i := 0 to Session.NumBinFactors-1 do begin
         s := s + format( '%d',[Session.BinFactors[i]] ) ;
         if i < (NumItems-1) then s := s + ', ' ;
         end ;
     CameraInfo.Add( s ) ;

     // Available image formats
     NumItems :=  High(iTable) ;
     QCAMAPI_CheckError( 'QCam_GetParamSparseTable (qprmImageFormat)',
                         QCam_GetParamSparseTable( Session.QCAMSettings,
                               qprmImageFormat,
                               @iTable,
                               NumItems )) ;
     s := 'Image formats: ' ;
     for i := 0 to NumItems-1 do begin
         s := s + format( '%s',[qcImageFormats[iTable[i]]] ) ;
         if i < (NumItems-1) then s := s + ', ' ;
         end ;
     CameraInfo.Add( s ) ;

     // Select 16 bit monochrome format if it is available
     Mono16Available := False ;
     Mono8Available := False ;
     for i := 0 to NumItems-1 do begin
         if iTable[i] = qfmtMono16 then Mono16Available := True
         else if iTable[i] = qfmtMono16 then Mono8Available := True ;
         end ;

     if Mono16Available then QCAMAPI_CheckError( 'QCam_SetParam (qprmImageFormat)',
                             QCam_SetParam( Session.QCAMSettings, qprmImageFormat, qfmtMono16 ))
     else if Mono8Available then QCAMAPI_CheckError( 'QCam_SetParam (qprmImageFormat)',
                                 QCam_SetParam( Session.QCAMSettings, qprmImageFormat, qfmtMono8 )) ;

     // Image format
     QCAMAPI_CheckError( 'QCam_GetParam (qprmImageFormat)',
                          QCam_GetParam( Session.QCAMSettings, qprmImageFormat, iValue )) ;
     CameraInfo.Add( 'Image format: ' + qcImageFormats[iValue] ) ;

     NumBytesPerPixel := 2 ;

     Session.CameraOpen := True ;
     Result := Session.CameraOpen ;

     PixelWidth := 10.0 ;

     end ;


procedure QCAMAPI_CloseCamera(
          var Session : TQCAMSession // Session record
          ) ;
// ------------
// Close camera
// ------------
begin

    if not Session.CameraOpen then Exit ;

    // Stop image capture
    QCAMAPI_StopCapture( Session ) ;

    // Close camera
    QCAMAPI_CheckError( 'QCAM_CloseCamera',
                         QCAM_CloseCamera( Session.CamHandle )) ;

    if @QCam_ReleaseCameraSettingsStruct <> Nil then begin
       QCAMAPI_CheckError( 'QCam_ReleaseCameraSettingsStruct',
                           QCam_ReleaseCameraSettingsStruct( Session.QCAMSettings )) ;
       end ;

    // Close QCAM driver
    QCAM_ReleaseDriver ;

    // Free DLL library
    FreeLibrary( LibraryHnd ) ;

    Session.CameraOpen := False ;

    end ;


procedure QCAMAPI_GetCameraGainList(
          var Session : TQCAMSession ;   // Camera session record
          CameraGainList : TStringList
          ) ;
// -------------------------------------
// Return list of available camera gains
// -------------------------------------
const
    GainList : Array[0..9] of Double = (1.0,2.0,5.0,10.,20.,50.0,100.0,200.0,500.0,1000.0) ;
var
    i : Integer ;
    iMin,iMax : Integer ;
    iMin64,iMax64 : Int64 ;
    GMin,GMax : Double ;
begin

    CameraGainList.Clear ;

    if Session.CameraType = qcCameraRetIT then begin
        // Intensified cameras
        QCAMAPI_CheckError( 'QCam_GetParam64Min (qprm64NormIntensGain)',
                            QCam_GetParam64Min( Session.QCAMSettings, qprm64NormIntensGain, iMin64 )) ;
        QCAMAPI_CheckError( 'QCam_GetParam64Max (qprm64NormIntensGain)',
                            QCam_GetParam64Max( Session.QCAMSettings, qprm64NormIntensGain, iMax64 )) ;
        GMin := iMin64*1E-6 ;
        GMax := IMax64*1E-6 ;
        end
    else begin
        // Get camera normalised gain range
        QCam_GetParamMin( Session.QCAMSettings, qprmNormalizedGain, iMin ) ;
        QCam_GetParamMax( Session.QCAMSettings, qprmNormalizedGain, iMax ) ; // S
        GMin := iMin*1E-6 ;
        GMax := IMax*1E-6 ;
        end ;

    // Set to gains available from list (and max)
    Session.NumGains := 0 ;
    for i := 0 to High(GainList) do begin
        if (GainList[i] >= GMin) and (GainList[i] <= GMax) then begin
           Session.Gains[Session.NumGains] := GainList[i] ;
           CameraGainList.Add( format( 'X%.1f',[Session.Gains[Session.NumGains]]));
          Inc( Session.NumGains ) ;
          end ;
        end ;
    if Session.Gains[Session.NumGains-1] <> GMax then begin
       Session.Gains[Session.NumGains] := GMax ;
       CameraGainList.Add( format( 'X%.1f',[Session.Gains[Session.NumGains]]));
       Inc( Session.NumGains ) ;
       end ;

    end ;


procedure QCAMAPI_GetCameraReadoutSpeedList(
          var Session : TQCAMSession ;   // Camera session record
          CameraReadoutSpeedList : TStringList
          ) ;
// -------------------------------------
// Return list of camera readout speeds
// -------------------------------------
var
    IsSupported,IsSparse,isRange,i : Integer ;
    NumItems : Integer ;
    iTable : Array[0..99] of Integer ;
begin

    CameraReadoutSpeedList.Clear ;

    // Readout speed range
     NumItems :=  High(iTable) ;
     QCAMAPI_CheckError( 'QCam_GetParamSparseTable (qprmReadoutSpeed)',
     QCam_GetParamSparseTable( Session.QCAMSettings,
                               qprmReadoutSpeed,
                               @iTable,
                               NumItems )) ;
     for i := 0 to NumItems-1 do begin
         CameraReadoutSpeedList.Add( format( '%.1f Mhz', [qcReadoutSpeeds[iTable[i]]]) ) ;
         end ;

    end ;


function QCAMAPI_StartCapture(
         var Session : TQCAMSession ;   // Camera session record
         var InterFrameTimeInterval : Double ;      // Frame exposure time
         AdditionalReadoutTime : Double ; // Additional readout time (s)
         AmpGain : Integer ;              // Camera amplifier gain index
         ReadoutSpeed : Integer ;         // Camera Read speed index number
         ExternalTrigger : Integer ;      // Trigger mode
         FrameLeft : Integer ;            // Left pixel in CCD readout area
         FrameRight : Integer ;           // Right pixel in CCD eadout area
         FrameTop : Integer ;             // Top of CCD readout area
         FrameBottom : Integer ;          // Bottom of CCD readout area
         BinFactor : Integer ;             // Binning factor (1,2,4,8,16)
         PFrameBuffer : Pointer ;         // Pointer to start of ring buffer
         NumFramesInBuffer : Integer ;    // No. of frames in ring buffer
         NumBytesPerFrame : Integer ;      // No. of bytes/frame
         CCDClearPreExposure : Boolean
         ) : Boolean ;
var
    Err : Integer ;
    i,iGain : Integer ;
    iGain64 : Int64 ;
    ExposureTime_ns : Int64 ;
//    ReadoutTime : Double ;
    qcTriggerMode : Integer ;
    qcClearMode : Integer ;
begin

    Result := False ;
    if not Session.CameraOpen then Exit ;

     // Abort any existing queued frames
//     QCAM_Abort( Session.CamHandle ) ;
     // Stop camera if it is running
     QCAMAPI_StopCapture( Session ) ;

     // Set camera readout speed
     ReadoutSpeed := Min(Max(ReadoutSpeed,0),Session.NumReadoutSpeeds-1) ;
     QCam_SetParam( Session.QCAMSettings,
                    qprmReadoutSpeed,
                    Session.ReadoutSpeeds[ReadoutSpeed] ) ;

     // Set camera normalised gain range
    if Session.CameraType = qcCameraRetIT then begin
        // Intensified cameras
        iGain64 := Round(Session.Gains[Min(Max(AmpGain,0),Session.NumGains-1)]*1E6) ;
        QCam_SetParam64( Session.QCAMSettings, qprm64NormIntensGain, iGain64 ) ;
        QCam_SetParam( Session.QCAMSettings, qprmNormalizedGain, 1000000 ) ;
        end
     else begin
         iGain := Round(Session.Gains[Min(Max(AmpGain,0),Session.NumGains-1)]*1E6) ;
         QCam_SetParam( Session.QCAMSettings, qprmNormalizedGain, iGain ) ;
         end ;

     // Set exposure time
//     InterFrameTimeInterval := Max( ReadoutTime, InterFrameTimeInterval ) ;
     ExposureTime_ns := Int64(Round(InterFrameTimeInterval*1E9)) ;
     QCAM_SetParam64( Session.QCAMSettings, qprm64Exposure, ExposureTime_ns ) ;
     InterFrameTimeInterval := ExposureTime_ns / 1E9 ;

     // Set trigger mode
     if ExternalTrigger = CamExtTrigger then begin
        qcTriggerMode := qcTriggerEdgeHi ;
        // Note. Exposure set to 95% of inter-frame interval to ensure frame exposure
        // has finished before next trigger pulse
        ExposureTime_ns := Int64(Round(((InterFrameTimeInterval*0.9) - AdditionalReadoutTime)*1E9)) ;
        QCAM_SetParam64( Session.QCAMSettings, qprm64Exposure, ExposureTime_ns ) ;
        if CCDClearPreExposure then qcClearMode := qcPreFrameClearing
                               else qcClearMode := qcNonClearing ;
        end
     else begin
        qcTriggerMode := qcTriggerFreerun ;
        qcClearMode := qcNonClearing ;
        end ;

     QCAM_SetParam( Session.QCAMSettings, qprmTriggerType, qcTriggerMode ) ;
     QCAM_SetParam( Session.QCAMSettings, qprmCCDClearingMode, qcClearMode ) ;

     // Update camera
     QCAMAPI_CheckError( 'QCam_SendSettingsToCam',
                         QCam_SendSettingsToCam( Session.CamHandle, Session.QCAMSettings)) ;

     // Turn streaming on
     QCAMAPI_CheckError( 'QCam_SetStreaming',
                         QCam_SetStreaming( Session.CamHandle, 1 )) ;

     // Create initial list of queued frames
     Session.NumFrames := NumFramesInBuffer ;
     Session.NumBytesPerFrame := NumBytesPerFrame ;
     for i := 0 to NumFramesInBuffer-1 do begin
         Session.FrameList[i].pBuffer := Pointer(Cardinal(PFrameBuffer) + i*NumBytesPerFrame) ;
         Session.FrameList[i].bufferSize := NumBytesPerFrame ;
         Err := QCAM_QueueFrame( Session.CamHandle,
                                 @Session.FrameList[i],
                                 @FrameDoneCallBack,
                                 qcCallbackDone,
                                 @Session,
                                 i) ;
         if Err <> 0 then Break ;
         end ;

     Session.FrameNum := 0 ;
     Session.CapturingImages := True ;
     Result := True ;

     end ;


procedure QCAMAPI_CheckROIBoundaries(
          var Session : TQCAMSession ;   // Camera session record
         var ReadoutSpeed : Integer ;         // Readout rate (index no.)
         var FrameLeft : Integer ;            // Left pixel in CCD readout area
         var FrameRight : Integer ;           // Right pixel in CCD eadout area
         var FrameTop : Integer ;             // Top of CCD readout area
         var FrameBottom : Integer ;          // Bottom of CCD readout area
         var BinFactor : Integer ;           // Pixel binning factor (In)
         var FrameWidth : Integer ;          // Image width
         var FrameHeight : Integer ;         // Image height
         ExternalTrigger : Integer ;         // True = camera in External trigger mode
         var FrameInterval : Double ;        // Time interval between frames (s)
         var ReadoutTime : Double ) ;        // Frame readout time (s)
// ----------------------------------------------------------
// Check and set CCD ROI boundaries and return valid settings
// (Also calculates minimum readout time)
// -----------------------------------------------------------
var
    i : Integer ;
    RScale : Double ;
begin

    // Set binning factor
    i := 0 ;
    while (BinFactor > Session.BinFactors[i]) and
           (i < Session.NumBinFactors) do Inc(i) ;
    BinFactor := Max( Session.BinFactors[i],1) ;

    QCAM_SetParam( Session.QCAMSettings, qprmBinning, BinFactor ) ;

    // Set CCD ROI region
    QCAM_SetParam( Session.QCAMSettings, qprmRoiX, FrameLeft div BinFactor ) ;
    QCAM_SetParam( Session.QCAMSettings, qprmRoiY, FrameTop  div BinFactor ) ;

    // Set CCD ROI width
    FrameWidth := (FrameRight - FrameLeft + 1) div BinFactor ;
    QCAM_SetParam( Session.QCAMSettings, qprmRoiWidth, FrameWidth ) ;

    // Set CCD ROI height
    FrameHeight := (FrameBottom - FrameTop + 1 ) div BinFactor ;
    QCAM_SetParam( Session.QCAMSettings, qprmRoiHeight, FrameHeight ) ;

    // Update camera
    if QCam_PreflightSettings( Session.CamHandle, @Session.QCAMSettings) <> 0 then Exit ;

    QCAM_GetParam( Session.QCAMSettings, qprmRoiX, FrameLeft ) ;
    FrameLeft := FrameLeft*BinFactor ;

    QCAM_GetParam( Session.QCAMSettings, qprmRoiY, FrameTop ) ;
    FrameTop := FrameTop*BinFactor ;

    // Set CCD ROI width

    QCAM_GetParam( Session.QCAMSettings, qprmRoiWidth, FrameWidth ) ;
    FrameRight := FrameWidth*BinFactor + FrameLeft - 1 ;

    // Set CCD ROI height
    QCAM_GetParam( Session.QCAMSettings, qprmRoiHeight, FrameHeight ) ;
    FrameBottom := FrameHeight*BinFactor + FrameTop - 1 ;

    // Calculate frame readout time
    // Note. Relationship between CCD readout time and no. of lines
    // calculated at 20 MHz and scaled for other readout rates
    // Minimum readout rate appears to be 20 ms
    ReadoutSpeed := Min(Max(ReadoutSpeed,0),Session.NumReadoutSpeeds-1) ;
    RScale := 20.0 / qcReadOutSpeeds[Session.ReadoutSpeeds[ReadoutSpeed]] ;
    ReadoutTime := RScale * Max( (FrameHeight*9E-5 + 0.0037)+ 1E-3, 0.02 ) ;

    if ExternalTrigger = CamExtTrigger then ReadoutTime := ReadoutTime + 5E-3 ;
    FrameInterval := Max( FrameInterval, ReadoutTime ) ;

    end ;


procedure QCAMAPI_Wait( Delay : Single ) ;
var
    Tend : Integer ;
begin

    TEnd :=timegettime + Round(delay*1000);
    repeat until timegettime >= TEnd ;

    end ;


procedure QCAMAPI_GetImage(
          var Session : TQCAMSession  // Camera session record
          ) ;
//
begin

    //outputdebugString(PChar(format('%d %d',[Session.FrameNum,Session.Counter]))) ;
    end ;


procedure QCAMAPI_StopCapture(
          var Session : TQCAMSession   // Camera session record
          ) ;
// -------------------------
// Stop camera frame capture
// -------------------------
begin

    if (not Session.CameraOpen) then Exit ;
    if (not Session.CapturingImages) then Exit ;

    // Abort any existing queued frames
    QCAMAPI_CheckError( 'QCAM_Abort', QCAM_Abort( Session.CamHandle )) ;

    // Turn streaming off
    QCAMAPI_CheckError( 'QCam_SetStreaming',
                        QCam_SetStreaming( Session.CamHandle, 0 )) ;

    Session.CapturingImages := False ;

    end ;


procedure QCAMAPI_CheckError(
          FuncName : String ;   // Name of function called
          ErrNum : Integer      // Error # returned by function
          ) ;
var
    Err : String ;
begin

    if ErrNum = 0 then Exit ;
    case ErrNum of
      qerrNotSupported : Err := ' Not supported' ;
      qerrInvalidValue  : Err :=  ' Invalid value' ;
      qerrBadSettings  : Err :=  'Bad settings' ;
      qerrNoUserDriver  : Err :=  'No user driver' ;
      qerrNoFirewireDriver  : Err :=  'No firewire driver' ;
      qerrDriverConnection  : Err :=  'Driver connection' ;
      qerrDriverAlreadyLoaded  : Err :=  'Driver already loaded' ;
      qerrDriverNotLoaded  : Err :=  'Driver not loaded' ;
      qerrInvalidHandle  : Err :=  'Invalid handle' ;
      qerrUnknownCamera  : Err :=  'Unknown camera' ;
      qerrInvalidCameraId  : Err :=  'Invalid camera ID' ;
      qerrNoMoreConnections  : Err := 'No more connections' ;
      qerrHardwareFault  : Err :=  'Hardware fault' ;
      qerrFirewireFault  : Err :=  'Firewire fault' ;
      qerrCameraFault  : Err :=  'Camera fault' ;
      qerrDriverFault  : Err :=  'Driver fault' ;
      qerrInvalidFrameIndex  : Err := 'Invalid frame index' ;
      qerrBufferTooSmall  : Err :=  'Buffer too small' ;
      qerrOutOfMemory  : Err :=  'Out of memory' ;
      qerrOutOfSharedMemory  : Err :=  'Out of shared memory' ;
      qerrBusy : Err := 'Camera is busy' ;
  	  qerrQueueFull : Err := 'Cannot queue more items; queue is full';
	    qerrCancelled : Err := 'Cancelled' ;
	    qerrNotStreaming : Err := 'Streaming must be on before calling this command ' ;
	    qerrLostSync : Err := 'Frame sync was lost';
	    qerrBlackFill : Err := 'This frame is damanged; some data is missing';
	    qerrFirewireOverflow : Err := 'Firewire overflow - restart streaming';
	    qerrUnplugged : Err := 'Camera has been unplugged or turned off';
	    qerrAccessDenied : Err := 'The camera is already open';
	    qerrStreamFault : Err := 'Stream Allocation Failed.  Is there enough Bandwidth';
	    qerrQCamUpdateNeeded : Err := 'QCam driver software is insufficient for the camera';
	    qerrRoiTooSmall : Err := 'ROI is too small';

      else Err := 'Unknown error' ;
      end ;

    ShowMessage( FuncName + ': Err= ' + Err ) ;

    end ;


procedure FrameDoneCallBack(
         UsrPtr : Pointer ;        // Pointer to use data
         UserData : Cardinal ;     // Supplied user data value
         ErrCode : Integer ;
         Flags : Cardinal ) ; stdcall ;
// --------------------------------
// Frame acquired callback function
// --------------------------------
begin

      if (not TQCAMSession(UsrPtr^).CapturingImages) then Exit ;
      if (UserData < 0) or (UserData >= TQCAMSession(UsrPtr^).NumFrames) then Exit ;
//      outputdebugString(PChar(format('%d %d',[UserData,TQCAMSession(UsrPtr^).NumFrames]))) ;
      Inc(TQCAMSession(UsrPtr^).Counter) ;

      // Re-queue this frame
      QCAM_QueueFrame( TQCAMSession(UsrPtr^).CamHandle,
                       @TQCAMSession(UsrPtr^).FrameList[UserData],
                       @FrameDoneCallBack,
                       qccallBackDone,
                       UsrPtr,
                       UserData) ;
      TQCAMSession(UsrPtr^).FrameNum := UserData ;
      end ;

procedure QCAMAPI_SetCooling(
          var Session : TQCAMSession ; // Session record
          CoolingOn : Boolean  // True = Cooling is on
          ) ;
var
    iActive,iCooled : Integer ;
begin

    QCAM_GetInfo( Session.CamHandle, qinfCooled, iCooled ) ;
    if iCooled <> 0 then begin
       if CoolingOn then iActive := 1
                    else iActive := 0 ;
       QCAM_SetParam( Session.QCAMSettings, qprmCoolerActive, iActive ) ;
       end ;

    end ;


procedure QCAMAPI_SetTemperature(
          var Session : TQCAMSession ; // Session record
          var TemperatureSetPoint : Single  // Required temperature
          ) ;
var
    iAvailable : Integer ;
begin

    QCAM_GetInfo( Session.CamHandle, qinfRegulatedCooling, iAvailable ) ;
    if iAvailable <> 0 then begin
       QCAM_SetParamS32( Session.QCAMSettings, qprmS32RegulatedCoolingTemp, Round(TemperatureSetPoint) ) ;
       end ;

    end ;



      initialization
    LibraryLoaded := False ;


end.
