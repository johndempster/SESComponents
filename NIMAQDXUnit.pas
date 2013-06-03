unit NIMAQDXUnit;
// ----------------------------------------------------------
// National Instruments NIMAQmx image capture library support
// ----------------------------------------------------------
// JD 6.9.10 NIMAQ-DX library
// JD 07.9.10 Working
// JD 13.12.10 BGRA format now detected correctly
// JD 15.12.10 Camera now closed properly when IMAQDX_CameraClose
//             called allowing programs to shut down correctly
// JD 30.07.12 Framewidthmax and Frameheightmax now set correctly by IMAQDX_SetVideoMode
// JD 15.05.13 IMAQDX_SetVideoMode() Top/left of AOI set to 0,0 and biining to 1
//             to ensure that maximum of AOI width and height correctly reported

interface

uses WinTypes,sysutils, classes, dialogs, mmsystem, math, strutils ;

const

   IMAQDX_MAX_API_STRING_LENGTH = 512 ;
//==============================================================================
//  Error Codes Enumeration
//==============================================================================
    IMAQdxErrorSuccess = 0;                   // Success
    IMAQdxErrorSystemMemoryFull = $BFF69000 ;   // Not enough memory
    IMAQdxErrorInternal=1;                        // Internal error
    IMAQdxErrorInvalidParameter=2;                // Invalid parameter
    IMAQdxErrorInvalidPointer=3;                  // Invalid pointer
    IMAQdxErrorInvalidInterface=4;                // Invalid camera session
    IMAQdxErrorInvalidRegistryKey=5;              // Invalid registry key
    IMAQdxErrorInvalidAddress = 6;                  // Invalid address
    IMAQdxErrorInvalidDeviceType = 7;               // Invalid device type
    IMAQdxErrorNotImplemented = 8;                  // Not implemented yet
    IMAQdxErrorCameraNotFound = 9;                  // Camera not found
    IMAQdxErrorCameraInUse = 10;                     // Camera is already in use.
    IMAQdxErrorCameraNotInitialized = 11;            // Camera is not initialized.
    IMAQdxErrorCameraRemoved = 12;                   // Camera has been removed.
    IMAQdxErrorCameraRunning = 13;                   // Acquisition in progress.
    IMAQdxErrorCameraNotRunning = 14;                // No acquisition in progress.
    IMAQdxErrorAttributeNotSupported = 15;           // Attribute not supported by the camera.
    IMAQdxErrorAttributeNotSettable = 16;            // Unable to set attribute.
    IMAQdxErrorAttributeNotReadable = 17;            // Unable to get attribute.
    IMAQdxErrorAttributeOutOfRange = 18;             // Attribute value is out of range.
    IMAQdxErrorBufferNotAvailable = 19;              // Requested buffer is unavailable.

    IMAQdxErrorBufferListEmpty = 20;                 // Buffer list is empty. Add one or more buffers.
    IMAQdxErrorBufferListLocked = 21;                // Buffer list is already locked. Reconfigure acquisition and try again.
    IMAQdxErrorBufferListNotLocked = 22;             // No buffer list. Reconfigure acquisition and try again.
    IMAQdxErrorResourcesAllocated = 23;              // Transfer engine resources already allocated. Reconfigure acquisition and try again.
    IMAQdxErrorResourcesUnavailable = 24;            // Insufficient transfer engine resources.
    IMAQdxErrorAsyncWrite = 25;                      // Unable to perform asychronous register write.
    IMAQdxErrorAsyncRead = 26;                       // Unable to perform asychronous register read.
    IMAQdxErrorTimeout = 27;                         // Timeout
    IMAQdxErrorBusReset = 28;                        // Bus reset occurred during a transaction.
    IMAQdxErrorInvalidXML = 29;                      // Unable to load camera's XML file.
    IMAQdxErrorFileAccess = 30;                      // Unable to read/write to file.
    IMAQdxErrorInvalidCameraURLString = 31;          // Camera has malformed URL string.
    IMAQdxErrorInvalidCameraFile = 32;               // Invalid camera file.
    IMAQdxErrorGenICamError = 33;                    // Unknown Genicam error.
    IMAQdxErrorFormat7Parameters = 34;               // For format 7: The combination of speed = ; image position = ; image size = ; and color coding is incorrect.
    IMAQdxErrorInvalidAttributeType = 35;            // The attribute type is not compatible with the passed variable type.
    IMAQdxErrorDLLNotFound = 36;                     // The DLL could not be found.
    IMAQdxErrorFunctionNotFound = 37;                // The function could not be found.
    IMAQdxErrorLicenseNotActivated = 38;             // License not activated.
    IMAQdxErrorCameraNotConfiguredForListener = 39;  // The camera is not configured properly to support a listener.
    IMAQdxErrorCameraMulticastNotAvailable = 40;     // Unable to configure the system for multicast support.
    IMAQdxErrorBufferHasLostPackets = 41;            // The requested buffer has lost packets and the user requested an error to be generated.
    IMAQdxErrorGiGEVisionError = 42;                 // Unknown GiGE Vision error.
    IMAQdxErrorNetworkError = 43;                    // Unknown network error.
    IMAQdxErrorCameraUnreachable = 44;               // Unable to connect to the camera
    IMAQdxErrorHighPerformanceNotSupported = 45;     // High performance acquisition is not supported on the specified network interface. Connect the camera to a network interface running the high performance driver.
    IMAQdxErrorInterfaceNotRenamed = 46;             // Unable to rename interface. Invalid or duplicate name specified.
    IMAQdxErrorNoSupportedVideoModes = 47;           // The camera does not have any video modes which are supported
    IMAQdxErrorSoftwareTriggerOverrun = 48;          // Software trigger overrun
    IMAQdxErrorTestPacketNotReceived = 49;           // The system did not receive a test packet from the camera. The packet size may be too large for the network configuration or a firewall may be enabled.
    IMAQdxErrorCorruptedImageReceived = 50;          // The camera returned a corrupted image
    IMAQdxErrorCameraConfigurationHasChanged = 51;   // The camera did not return an image of the correct type it was configured for previously
    IMAQdxErrorCameraInvalidAuthentication = 52;     // The camera is configured with password authentication and either the user name and password were not configured or they are incorrect
    IMAQdxErrorUnknownHTTPError = 53;                // The camera returned an unknown HTTP error
    IMAQdxErrorGuard  = $FFFFFFFF ;


//==============================================================================
//  Bus Type Enumeration
//==============================================================================
    IMAQdxBusTypeFireWire = $31333934;
    IMAQdxBusTypeEthernet = $69707634;
    IMAQdxBusTypeSimulator = $2073696D;
    IMAQdxBusTypeDirectShow = $64736877;
    IMAQdxBusTypeIP = $4950636D;
    IMAQdxBusTypeGuard = $FFFFFFFF;

//==============================================================================
//  Camera Control Mode Enumeration
//==============================================================================
    IMAQdxCameraControlModeController = 0 ;
    IMAQdxCameraControlModeListener = 1 ;
    IMAQdxCameraControlModeGuard = $FFFFFFFF ;

//==============================================================================
//  Buffer Number Mode Enumeration
//==============================================================================
    IMAQdxBufferNumberModeNext = 0 ;
    IMAQdxBufferNumberModeLast = 1 ;
    IMAQdxBufferNumberModeBufferNumber = 2 ;
    IMAQdxBufferNumberModeGuard = $FFFFFFFF ;

//==============================================================================
//  Plug n Play Event Enumeration
//==============================================================================
    IMAQdxPnpEventCameraAttached = 0 ;
    IMAQdxPnpEventCameraDetached = 1 ;
    IMAQdxPnpEventBusReset = 2 ;
    IMAQdxPnpEventGuard = $FFFFFFFF ;

//==============================================================================
//  Bayer Pattern Enumeration
//==============================================================================
    IMAQdxBayerPatternNone = 0;
    IMAQdxBayerPatternGB = 1;
    IMAQdxBayerPatternGR = 2;
    IMAQdxBayerPatternBG = 3;
    IMAQdxBayerPatternRG = 4;
    IMAQdxBayerPatternHardware = 5;
    IMAQdxBayerPatternGuard = $FFFFFFFF ;

//==============================================================================
//  Controller Destination Mode Enumeration
//==============================================================================
    IMAQdxDestinationModeUnicast = 0;
    IMAQdxDestinationModeBroadcast = 1;
    IMAQdxDestinationModeMulticast = 2;
    IMAQdxDestinationModeGuard = $FFFFFFFF ;

//==============================================================================
//   Attribute Type Enumeration
//==============================================================================
    IMAQdxAttributeTypeU32 = 0;
    IMAQdxAttributeTypeI64 = 1;
    IMAQdxAttributeTypeF64 = 2;
    IMAQdxAttributeTypeString = 3;
    IMAQdxAttributeTypeEnum = 4;
    IMAQdxAttributeTypeBool = 5;
    IMAQdxAttributeTypeCommand = 6;
    IMAQdxAttributeTypeBlob = 7;  //Internal Use Only
    IMAQdxAttributeTypeGuard = $FFFFFFFF ;

//==============================================================================
//  Value Type Enumeration
//==============================================================================
    IMAQdxValueTypeU32 = 0;
    IMAQdxValueTypeI64 = 1;
    IMAQdxValueTypeF64 = 2;
    IMAQdxValueTypeString = 3;
    IMAQdxValueTypeEnumItem = 4;
    IMAQdxValueTypeBool = 5;
    IMAQdxValueTypeDisposableString = 6;
    IMAQdxValueTypeGuard = $FFFFFFFF ;

//==============================================================================
//  Interface File Flags Enumeration
//==============================================================================
    IMAQdxInterfaceFileFlagsConnected = 1 ;
    IMAQdxInterfaceFileFlagsDirty = 2 ;
    IMAQdxInterfaceFileFlagsGuard = $FFFFFFFF ;

//==============================================================================
//  Overwrite Mode Enumeration
//==============================================================================
    IMAQdxOverwriteModeGetOldest = 0 ;
    IMAQdxOverwriteModeFail = 2 ;
    IMAQdxOverwriteModeGetNewest = 3 ;
    IMAQdxOverwriteModeGuard = $FFFFFFFF ;

//==============================================================================
//  Lost Packet Mode Enumeration
//==============================================================================
    IMAQdxLostPacketModeIgnore = 0;
    IMAQdxLostPacketModeFail = 1;
    IMAQdxLostPacketModeGuard = $FFFFFFFF ;

//==============================================================================
//  Attribute Visibility Enumeration
//==============================================================================
    IMAQdxAttributeVisibilitySimple = $00001000 ;
    IMAQdxAttributeVisibilityIntermediate = $00002000 ;
    IMAQdxAttributeVisibilityAdvanced = $00004000 ;
    IMAQdxAttributeVisibilityGuard = $FFFFFFFF ;

//==============================================================================
//  Stream Channel Mode Enumeration
//==============================================================================
    IMAQdxStreamChannelModeAutomatic = 0;
    IMAQdxStreamChannelModeManual = 1;
    IMAQdxStreamChannelModeGuard = $FFFFFFFF ;

//==============================================================================
//  Pixel Signedness Enumeration
//==============================================================================
    IMAQdxPixelSignednessUnsigned = 0;
    IMAQdxPixelSignednessSigned = 1;
    IMAQdxPixelSignednessHardware = 2;
    IMAQdxPixelSignednessGuard = $FFFFFFFF ;

//==============================================================================
//  Attributes
//==============================================================================
      IMAQdxAttributeBaseAddress =              'CameraInformation::BaseAddress'         ; // Read only. Gets the base address of the camera registers.
      IMAQdxAttributeBusType =                  'CameraInformation::BusType'             ; // Read only. Gets the bus type of the camera.
      IMAQdxAttributeModelName =                'CameraInformation::ModelName'           ; // Read only. Returns the model name.
      IMAQdxAttributeSerialNumberHigh =         'CameraInformation::SerialNumberHigh'    ; // Read only. Gets the upper 32-bits of the camera 64-bit serial number.
      IMAQdxAttributeSerialNumberLow =          'CameraInformation::SerialNumberLow'     ; // Read only. Gets the lower 32-bits of the camera 64-bit serial number.
      IMAQdxAttributeVendorName =               'CameraInformation::VendorName'          ; // Read only. Returns the vendor name.
      IMAQdxAttributeHostIPAddress =            'CameraInformation::HostIPAddress'       ; // Read only. Returns the host adapter IP address.
      IMAQdxAttributeIPAddress =                'CameraInformation::IPAddress'           ; // Read only. Returns the IP address.
      IMAQdxAttributePrimaryURLString =         'CameraInformation::PrimaryURLString'    ; // Read only. Gets the camera's primary URL string.
      IMAQdxAttributeSecondaryURLString =       'CameraInformation::SecondaryURLString'  ; // Read only. Gets the camera's secondary URL string.
      IMAQdxAttributeAcqInProgress =             'StatusInformation::AcqInProgress'       ; // Read only. Gets the current state of the acquisition. TRUE if acquiring; otherwise FALSE.
      IMAQdxAttributeLastBufferCount =          'StatusInformation::LastBufferCount'     ; // Read only. Gets the number of transferred buffers.
      IMAQdxAttributeLastBufferNumber =         'StatusInformation::LastBufferNumber'    ; // Read only. Gets the last cumulative buffer number transferred.
      IMAQdxAttributeLostBufferCount =          'StatusInformation::LostBufferCount'     ; // Read only. Gets the number of lost buffers during an acquisition session.
      IMAQdxAttributeLostPacketCount =          'StatusInformation::LostPacketCount'     ; // Read only. Gets the number of lost packets during an acquisition session.
      IMAQdxAttributeRequestedResendPackets =   'StatusInformation::RequestedResendPacketCount' ; // Read only. Gets the number of packets requested to be resent during an acquisition session.
      IMAQdxAttributeReceivedResendPackets =    'StatusInformation::ReceivedResendPackets' ; // Read only. Gets the number of packets that were requested to be resent during an acquisition session and were completed.
      IMAQdxAttributeHandledEventCount =        'StatusInformation::HandledEventCount'   ; // Read only. Gets the number of handled events during an acquisition session.
      IMAQdxAttributeLostEventCount =           'StatusInformation::LostEventCount'      ; // Read only. Gets the number of lost events during an acquisition session.
      IMAQdxAttributeBayerGainB =               'AcquisitionAttributes::Bayer::GainB'    ; // Sets/gets the white balance gain for the blue component of the Bayer conversion.
      IMAQdxAttributeBayerGainG=                'AcquisitionAttributes::Bayer::GainG'    ; // Sets/gets the white balance gain for the green component of the Bayer conversion.
      IMAQdxAttributeBayerGainR=                'AcquisitionAttributes::Bayer::GainR'    ; // Sets/gets the white balance gain for the red component of the Bayer conversion.
      IMAQdxAttributeBayerPattern=              'AcquisitionAttributes::Bayer::Pattern'  ; // Sets/gets the Bayer pattern to use.
      IMAQdxAttributeStreamChannelMode=         'AcquisitionAttributes::Controller::StreamChannelMode' ; // Gets/sets the mode for allocating a FireWire stream channel.
      IMAQdxAttributeDesiredStreamChannel=      'AcquisitionAttributes::Controller::DesiredStreamChannel' ; // Gets/sets the stream channel to manually allocate.
      IMAQdxAttributeFrameInterval=             'AcquisitionAttributes::FrameInterval'   ; // Read only. Gets the duration in milliseconds between successive frames.
      IMAQdxAttributeIgnoreFirstFrame=          'AcquisitionAttributes::IgnoreFirstFrame' ; // Gets/sets the video delay of one frame between starting the camera and receiving the video feed.
      IMAQdxAttributeOffsetX=                   'AcquisitionAttributes::OffsetX'                                ; // Gets/sets the left offset of the image.
      IMAQdxAttributeOffsetY=                   'AcquisitionAttributes::OffsetY'                                ; // Gets/sets the top offset of the image.
      IMAQdxAttributeWidth=                     'AcquisitionAttributes::Width'                                  ; // Gets/sets the width of the image.
      IMAQdxAttributeHeight=                    'AcquisitionAttributes::Height'                                 ; // Gets/sets the height of the image.
      IMAQdxAttributePixelFormat=               'PixelFormat'                            ; // Gets/sets the pixel format of the source sensor.
      IMAQdxAttributePacketSize=                'PacketSize'                             ; // Gets/sets the packet size in bytes.
      IMAQdxAttributePayloadSize=               'PayloadSize'                            ; // Gets/sets the frame size in bytes.
      IMAQdxAttributeSpeed=                     'AcquisitionAttributes::Speed'           ; // Gets/sets the transfer speed in Mbps for a FireWire packet.
      IMAQdxAttributeShiftPixelBits=            'AcquisitionAttributes::ShiftPixelBits'  ; // Gets/sets the alignment of 16-bit cameras. Downshift the pixel bits if the camera returns most significant bit-aligned data.
      IMAQdxAttributeSwapPixelBytes=            'AcquisitionAttributes::SwapPixelBytes'  ; // Gets/sets the endianness of 16-bit cameras. Swap the pixel bytes if the camera returns little endian data.
      IMAQdxAttributeOverwriteMode=             'AcquisitionAttributes::OverwriteMode'   ; // Gets/sets the overwrite mode, used to determine acquisition when an image transfer cannot be completed due to an overwritten internal buffer.
      IMAQdxAttributeTimeout=                   'AcquisitionAttributes::Timeout'         ; // Gets/sets the timeout value in milliseconds, used to abort an acquisition when the image transfer cannot be completed within the delay.
      IMAQdxAttributeVideoMode=                 'AcquisitionAttributes::VideoMode'       ; // Gets/sets the video mode for a camera.
      IMAQdxAttributeBitsPerPixel=              'AcquisitionAttributes::BitsPerPixel'    ; // Gets/sets the actual bits per pixel. For 16-bit components, this represents the actual bit depth (10-, 12-, 14-, or 16-bit).
      IMAQdxAttributePixelSignedness=           'AcquisitionAttributes::PixelSignedness' ; // Gets/sets the signedness of the pixel. For 16-bit components, this represents the actual pixel signedness (Signed, or Unsigned).
      IMAQdxAttributeReserveDualPackets=        'AcquisitionAttributes::ReserveDualPackets' ; // Gets/sets if dual packets will be reserved for a very large FireWire packet.
      IMAQdxAttributeReceiveTimestampMode=      'AcquisitionAttributes::ReceiveTimestampMode' ; // Gets/sets the mode for timestamping images received by the driver.
      IMAQdxAttributeActualPeakBandwidth=       'AcquisitionAttributes::AdvancedEthernet::BandwidthControl::ActualPeakBandwidth' ; // Read only. Returns the actual maximum peak bandwidth the camera will be configured to use.
      IMAQdxAttributeDesiredPeakBandwidth=      'AcquisitionAttributes::AdvancedEthernet::BandwidthControl::DesiredPeakBandwidth' ; // Gets/sets the desired maximum peak bandwidth the camera should use.
      IMAQdxAttributeDestinationMode=           'AcquisitionAttributes::AdvancedEthernet::Controller::DestinationMode' ; // Gets/Sets where the camera is instructed to send the image stream.
      IMAQdxAttributeDestinationMulticastAddress= 'AcquisitionAttributes::AdvancedEthernet::Controller::DestinationMulticastAddress' ; // Gets/Sets the multicast address the camera should send data in multicast mode.
      IMAQdxAttributeEventsEnabled=             'AcquisitionAttributes::AdvancedEthernet::EventParameters::EventsEnabled' ; // Gets/Sets if events will be handled.
      IMAQdxAttributeMaxOutstandingEvents=      'AcquisitionAttributes::AdvancedEthernet::EventParameters::MaxOutstandingEvents' ; // Gets/Sets the maximum number of outstanding events to queue.
      IMAQdxAttributeTestPacketEnabled=         'AcquisitionAttributes::AdvancedEthernet::TestPacketParameters::TestPacketEnabled' ; // Gets/Sets whether the driver will validate the image streaming settings using test packets prior to an acquisition
      IMAQdxAttributeTestPacketTimeout=         'AcquisitionAttributes::AdvancedEthernet::TestPacketParameters::TestPacketTimeout' ; // Gets/Sets the timeout for validating test packet reception (if enabled)
      IMAQdxAttributeMaxTestPacketRetries=      'AcquisitionAttributes::AdvancedEthernet::TestPacketParameters::MaxTestPacketRetries' ; // Gets/Sets the number of retries for validating test packet reception (if enabled)
      IMAQdxAttributeLostPacketMode=            'AcquisitionAttributes::AdvancedEthernet::LostPacketMode' ; // Gets/sets the behavior when the user extracts a buffer that has missing packets.
      IMAQdxAttributeMemoryWindowSize=          'AcquisitionAttributes::AdvancedEthernet::ResendParameters::MemoryWindowSize' ; // Gets/sets the size of the memory window of the camera in kilobytes. Should match the camera's internal buffer size.
      IMAQdxAttributeResendsEnabled=            'AcquisitionAttributes::AdvancedEthernet::ResendParameters::ResendsEnabled' ; // Gets/sets if resends will be issued for missing packets.
      IMAQdxAttributeResendThresholdPercentage= 'AcquisitionAttributes::AdvancedEthernet::ResendParameters::ResendThresholdPercentage' ; // Gets/sets the threshold of the packet processing window that will trigger packets to be resent.
      IMAQdxAttributeResendBatchingPercentage=  'AcquisitionAttributes::AdvancedEthernet::ResendParameters::ResendBatchingPercentage' ; // Gets/sets the percent of the packet resend threshold that will be issued as one group past the initial threshold sent in a single request.
      IMAQdxAttributeMaxResendsPerPacket=       'AcquisitionAttributes::AdvancedEthernet::ResendParameters::MaxResendsPerPacket' ; // Gets/sets the maximum number of resend requests that will be issued for a missing packet.
      IMAQdxAttributeResendResponseTimeout=     'AcquisitionAttributes::AdvancedEthernet::ResendParameters::ResendResponseTimeout' ; // Gets/sets the time to wait for a resend request to be satisfied before sending another.
      IMAQdxAttributeNewPacketTimeout=          'AcquisitionAttributes::AdvancedEthernet::ResendParameters::NewPacketTimeout' ; // Gets/sets the time to wait for new packets to arrive in a partially completed image before assuming the rest of the image was lost.
      IMAQdxAttributeMissingPacketTimeou=      'AcquisitionAttributes::AdvancedEthernet::ResendParameters::MissingPacketTimeout' ; // Gets/sets the time to wait for a missing packet before issuing a resend.
      IMAQdxAttributeResendTimerResolution=     'AcquisitionAttributes::AdvancedEthernet::ResendParameters::ResendTimerResolution' ; // Gets/sets the resolution of the packet processing system that is used for all packet-related timeouts.

      IMAQdxAttributeAOIBinningHorizontal = 'CameraAttributes::AOI::BinningHorizontal';
      IMAQdxAttributeAOIBinningVertical = 'CameraAttributes::AOI::BinningVertical';
      IMAQdxAttributeAOICenterX = 'CameraAttributes::AOI::CenterX';
      IMAQdxAttributeAOICenterY = 'CameraAttributes::AOI::CenterY';
      IMAQdxAttributeAOIHeight = 'CameraAttributes::AOI::Height';
      IMAQdxAttributeAOIOffsetX = 'CameraAttributes::AOI::OffsetX';
      IMAQdxAttributeAOIOffsetY = 'CameraAttributes::AOI::OffsetY';
      IMAQdxAttributeAOIWidth = 'CameraAttributes::AOI::Width';

      IMAQdxAttributeImageFormatPixelColorFilter = 'CameraAttributes::ImageFormat::PixelColorFilter';
      IMAQdxAttributeImageFormatPixelDynamicRangeMax = 'CameraAttributes::ImageFormat::PixelDynamicRangeMax';
      IMAQdxAttributeImageFormatPixelDynamicRangeMin = 'CameraAttributes::ImageFormat::PixelDynamicRangeMin';
      IMAQdxAttributeImageFormatPixelFormat = 'CameraAttributes::ImageFormat::PixelFormat';
      IMAQdxAttributeImageFormatPixelSize = 'CameraAttributes::ImageFormat::PixelSize';
      IMAQdxAttributeImageFormatReverseX = 'CameraAttributes::ImageFormat::ReverseX';
      IMAQdxAttributeImageFormatTestImageSelector = 'CameraAttributes::ImageFormat::TestImageSelector';




//==============================================================================
//  Camera Information Structure
//==============================================================================

Type

    TIMAQdxCameraInformation = packed Record
        IType : DWord ;
        Version : DWord ;
        Flags : DWord ;
        SerialNumberHi : DWord ;
        SerialNumberLo : DWord ;
        IMAQdxBusType : DWord ;
        InterfaceName : Array[0..IMAQDX_MAX_API_STRING_LENGTH-1] of ANSIChar ;
        VendorName : Array[0..IMAQDX_MAX_API_STRING_LENGTH-1] of ANSIChar ;
        ModelName : Array[0..IMAQDX_MAX_API_STRING_LENGTH-1] of ANSIChar ;
        CameraFileName : Array[0..IMAQDX_MAX_API_STRING_LENGTH-1] of ANSIChar ;
        CameraAttributeURL : Array[0..IMAQDX_MAX_API_STRING_LENGTH-1] of ANSIChar ;
        end ;

//==============================================================================
//  Attribute Information Structure
//==============================================================================
    TIMAQdxAttributeInformation= packed record
       iType : DWord ;
       Readable : LongBool ;
       Writable : LongBool ;
       Name : Array[0..IMAQDX_MAX_API_STRING_LENGTH-1] of ANSIChar ;
       end ;

//==============================================================================
//  Enumeration Item Structure
//==============================================================================
    TIMAQdxEnumItem = packed record
       Value : DWord ;
       Reserved : DWord ;
       Name : Array[0..IMAQDX_MAX_API_STRING_LENGTH-1] of ANSIChar ;
       end ;



 TIMAQDXSession = packed record
    ID : Integer ;
    CameraOpen : Boolean ;
    AcquisitionInProgress : Boolean ;
    NumFramesInBuffer : Integer ;
    FrameBufPointer : Pointer ;
    NumBytesPerFrame : Integer ;
    NumPixelComponents : Integer ;
    NumBytesPerComponent : Integer ;
    UseComponent : Integer ;
    FrameCounter : Integer ;
    BufferIndex : Integer ;
    CameraInfo : Array [0..9] of TIMAQdxCameraInformation ;
    Attributes : Array[0..255] of TIMAQdxAttributeInformation ;
    PixelSettings : Array[0..31] of TIMAQdxEnumItem ;
    NumPixelSettings : Cardinal ;
    NumAttributes : Cardinal ;
    NumCameras : Cardinal ;
    VideoMode : Integer ;
    VideoModes : Array[0..255] of TIMAQdxEnumItem ;
    NumVideoModes : Cardinal ;
    PixelFormat : Integer ;
    PixelFormats : Array[0..255] of TIMAQdxEnumItem ;
    NumPixelFormats : Cardinal ;
    CurrentVideoMode : Cardinal ;
    FrameWidthMax : Integer ;
    FrameHeightMax : Integer ;
    FrameLeft : Integer ;
    FrameTop : Integer ;
    FrameWidth : Integer ;
    FrameHeight : Integer ;
    PixelDepth : Integer ;
    GreyLevelMin : Integer ;
    GreyLevelMax : Integer ;
    Buf : PByteArray ;
    BufSize : Integer ;
    AttrHeight : Integer ;
    AttrWidth : Integer ;
    AttrXOffset : Integer ;
    AttrYOffset : Integer ;
    AttrXBin : Integer ;
    AttrYBin : Integer ;
    AttrPixelFormat : Integer ;
    AttrPixelSize : Integer ;
    AttrBitsPerPixel : Integer ;
    AttrVideoMode : Integer ;
    AttrExposureTime : Integer ;
    AttrLastBufferNumber : Integer ;
    AttrLastBufferCount : Integer ;
    AttrAcqInProgress : Integer ;
    AttrTriggerMode : Integer ;
    AttrTriggerSelector : Integer ;
    AttrTriggerSource : Integer ;
    AttrTriggerActivation : Integer ;
    AOIAvailable : Boolean ;
    end ;



//==============================================================================
//  Camera File Structure
//==============================================================================
    TIMAQdxCameraFile= packed record
      iType : DWord ;
      Version : DWord ;
      FileName : Array[0..IMAQDX_MAX_API_STRING_LENGTH-1] of ANSIChar ;
      end ;




//==============================================================================
//  Camera Information Structure
//==============================================================================
//typedef IMAQdxEnumItem IMAQdxVideoMode;


//==============================================================================
//  Callbacks
//==============================================================================
//typedef     uInt32 (NI_FUNC *FrameDoneEventCallbackPtr)(IMAQdxSession id, uInt32 bufferNumber, void* callbackData);
//typedef     uInt32 (NI_FUNC *PnpEventCallbackPtr)(IMAQdxSession id, IMAQdxPnpEvent pnpEvent, void* callbackData);
//typedef     void (NI_FUNC *AttributeUpdatedEventCallbackPtr)(IMAQdxSession id, const char* name, void* callbackData);



//==============================================================================
//  Functions
//==============================================================================
     TIMAQdxSnap= function(
       SessionID : Integer ;
       pImage : Pointer ) : Integer ; stdcall ;

     TIMAQdxConfigureGrab= function(
       SessionID : Integer ) : Integer ; stdcall ;

     TIMAQdxGrab= function(
       SessionID : Integer ;
       pImage : Pointer ;
       waitForNextBuffer : LongBool ;
       var actualBufferNumber : Cardinal ) : Integer ; stdcall ;

     TIMAQdxSequence= function(
        SessionID : Integer ;
        pImages : Pointer ;
        Count : Cardinal ) : Integer ; stdcall ;

     TIMAQdxDiscoverEthernetCameras= function(
         Address : PANSIChar ;
         Timeout : Cardinal
         ) : Integer ; stdcall ;

     TIMAQdxEnumerateCameras= function(
        pIMAQdxCameraInformation : Pointer ;
        var Count : Cardinal ;
        ConnectedOnly : LongBool ) : Integer ; stdcall ; //

     TIMAQdxResetCamera= function(
          Name : PANSIChar ;
          ResetAll  : LongBool) : Integer ; stdcall ; //

     TIMAQdxOpenCamera= function(
          Name : PANSIChar ;
          Mode : DWord ;
          var SessionID : Integer  ) : Integer ; stdcall ; //

     TIMAQdxCloseCamera= function(
          SessionID : Integer ) : Integer ; stdcall ; //

     TIMAQdxConfigureAcquisition= function(
          SessionID : Integer ;
          Continuous : Cardinal ;
          BufferCount : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxStartAcquisition= function(
          SessionID : Integer ) : Integer ; stdcall ; //

     TIMAQdxGetImage= function(
          SessionID : Integer ;
          pImage : Pointer ;
          BufferNumberMode : Cardinal ;
          DesiredBufferNumber : Cardinal ;
          var ActualBufferNumber : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxGetImageData= function(
         SessionID : Integer ;
         pBuffer : Pointer ;
         BufferSize : Cardinal ;
         BufferNumberMode  : Cardinal ;
         DesiredBufferNumber : Cardinal ;
         var ActualBufferNumber : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxStopAcquisition= function(
         SessionID : Integer ) : Integer ; stdcall ; //

     TIMAQdxUnconfigureAcquisition= function(
         SessionID : Integer ) : Integer ; stdcall ; //

     TIMAQdxEnumerateVideoModes= function(
         SessionID : Integer ;
         pVideoMode : Pointer ;
         var Count : Cardinal ;
         var currentMode  : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxEnumerateAttributes= function(
         SessionID : Integer ;
         pAttributeInformation : Pointer ;
         var count : Cardinal ;
         Root : PANSIChar ) : Integer ; stdcall ; //

     TIMAQdxGetAttribute= function(
         SessionID : Integer ;
         Name : PANSIChar ;
         ValueType : Cardinal ;
         pValue : Pointer ) : Integer ; stdcall ; //

     TIMAQdxSetAttribute= function(
         SessionID : Integer ;
         Name : PANSIChar ;
         ValueType : Cardinal ;
         Value : Integer ) : Integer ; cdecl ; //

     TIMAQdxSetAttributeEnum= function(
         SessionID : Integer ;
         Name : PANSIChar ;
         ValueType : Cardinal ;
         Value : Cardinal ) : Integer ; cdecl ; //


     TIMAQdxGetAttributeMinimum= function(
         SessionID : Integer ;
         Name : PANSIChar ;
         ValueType : Cardinal ;
         pValue : Pointer ) : Integer ; stdcall ; //

     TIMAQdxGetAttributeMaximum= function(
         SessionID : Integer ;
         Name : PANSIChar ;
         ValueType : Cardinal ;
         pValue : Pointer ) : Integer ; stdcall ; //

     TIMAQdxGetAttributeIncrement= function(
         SessionID : Integer ;
         Name : PANSIChar ;
         ValueType : Cardinal ;
         pValue : Pointer ) : Integer ; stdcall ; //

     TIMAQdxGetAttributeType= function(
         SessionID : Integer ;
         Name : PANSIChar ;
         var AttributeType : Cardinal) : Integer ; stdcall ; //

     TIMAQdxIsAttributeReadable= function(
        SessionID : Integer ;
        Name : PANSIChar ;
        var Readable : LongBool ) : Integer ; stdcall ; //

     TIMAQdxIsAttributeWritable= function(
        SessionID : Integer ;
        Name : PANSIChar ;
        var writable : LongBool ) : Integer ; stdcall ; //

     TIMAQdxEnumerateAttributeValues= function(
        SessionID : Integer ;
        Name : PANSIChar ;
        pEnumItems : Pointer ;
        var Size : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxGetAttributeTooltip= function(
        SessionID : Integer ;
        Name : PANSIChar ;
        Tooltip : PANSIChar ;
        Length : Cardinal ) : Integer ; stdcall ; //
        
     TIMAQdxGetAttributeUnits= function(
        SessionID : Integer ;
        Name : PANSIChar ;
        Units : PANSIChar ;
        Length : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxRegisterFrameDoneEvent= function(
        SessionID : Integer ;
        BufferInterval : Cardinal ;
        pFrameDoneEventCallbackPtr : Pointer ;
        pCallbackData : Pointer ) : Integer ; stdcall ; //

     TIMAQdxRegisterPnpEvent= function(
        SessionID : Integer ;
        Event : Cardinal ;
        PnpEventCallbackPtr : Pointer ;
        pCallbackData : Pointer) : Integer ; stdcall ; //

     TIMAQdxWriteRegister= function(
        SessionID : Integer ;
        Offset : Cardinal ;
        Value : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxReadRegister= function(
        SessionID : Integer ;
        Offset : Cardinal ;
        var Value : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxWriteMemory= function(
        SessionID : Integer ;
        Offset : Cardinal ;
        Values : pANSIChar ;
        Count : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxReadMemory= function(
        SessionID : Integer ;
        offset : Cardinal ;
        Values : PANSIChar ;
        Count  : Cardinal) : Integer ; stdcall ; //

     TIMAQdxGetErrorString= function(
        Error : DWord ;
        ErrorMsg : PANSIChar ;
        MessageLength : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxWriteAttributes= function(
        SessionID : Integer ;
        Filename : PANSIChar ) : Integer ; stdcall ; //

     TIMAQdxReadAttributes= function(
        SessionID : Integer ;
        Filename : PANSIChar ) : Integer ; stdcall ; //

     TIMAQdxResetEthernetCameraAddress= function(
        Name : PANSIChar ;
        Address : PANSIChar ;
        Subnet : PANSIChar ;
        Gateway : PANSIChar ;
        Timeout : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxEnumerateAttributes2= function(
        SessionID : Integer ;
        pAttributeInformation : Pointer  ;
        var Count : Cardinal ;
        Root : PANSIChar ;
        Visibility : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxGetAttributeVisibility= function(
        SessionID : Integer ;
        Name : PANSIChar ;
        var visibility : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxGetAttributeDescription= function(
        SessionID : Integer ;
        Name : PANSIChar ;
        Description : PANSIChar ;
        Length : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxGetAttributeDisplayName= function(
        SessionID : Integer ;
        Name : PANSIChar ;
        DisplayName : PANSIChar ;
        Length : Cardinal ) : Integer ; stdcall ; //

     TIMAQdxRegisterAttributeUpdatedEvent= function(
        SessionID : Integer ;
        Name : PANSIChar ;
        AttributeUpdatedEventCallbackPtr : Pointer ;
        CallbackData : Pointer ) : Integer ; stdcall ; //

// ----------------------
// Library function calls
// ----------------------

function IMAQDX_OpenCamera(
          var Session : TIMAQDXSession ;   // Camera session
          var CameraMode : Integer ;
          var PixelFormat : Integer ;
          var FrameWidthMax : Integer ;
          var FrameHeightMax : Integer ;
          var NumBytesPerPixel : Integer ;
          var PixelDepth : Integer ;
          var BinFactorMax : Integer ;
          CameraInfo : TStringList         // Returns Camera details
          ) : Boolean ;

procedure IMAQDX_CloseCamera(
          var Session : TIMAQDXSession     // Camera session #
          ) ;

procedure IMAQDX_SetVideoMode(
          var Session : TIMAQDXSession ;
          VideoMode : Integer ;
          PixelFormat : Integer ;
          var FrameWidthMax : Integer ;  // Returns camera frame width
          var FrameHeightMax : Integer ; // Returns camera height width
          var NumBytesPerComponent : Integer ; // Returns bytes/pixel
          var PixelDepth : Integer ;        // Returns no. bits/pixel
          var GreyLevelMin : Integer ;      // Min. grey level
          var GreyLevelMax : Integer        // Max. grey level
          ) ;

procedure IMAQDX_SetPixelFormat(
          var Session : TIMAQDXSession ;
          var PixelFormat : Integer ;               // Video mode
          var NumBytesPerComponent : Integer ; // Returns bytes/pixel
          var PixelDepth : Integer         // Returns no. bits/pixel
          ) ;


function IMAQDX_GetVideoMode(
          var Session : TIMAQDXSession ) : Integer ;

function IMAQDX_StartCapture(
         var Session : TIMAQDXSession ;
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

procedure IMAQDX_StopCapture(
          var Session : TIMAQDXSession              // Camera session #
          ) ;

procedure IMAQDX_GetImage(
          var Session : TIMAQDXSession
          ) ;

procedure IMAQDX_GetCameraGainList( CameraGainList : TStringList ) ;

procedure IMAQDX_GetCameraVideoModeList(
          var Session : TIMAQDXSession ;
          List : TStringList ) ;

procedure IMAQDX_GetCameraPixelFormatList(
          var Session : TIMAQDXSession ;
          List : TStringList ) ;

function IMAQDX_CheckFrameInterval(
          var Session : TIMAQDXSession ;
          var FrameInterval : Double ) : Integer ;

procedure IMAQDX_LoadLibrary  ;
function IMAQDX_GetDLLAddress(
         Handle : Integer ;
         const ProcName : ANSIstring ) : Pointer ;

procedure IMAQDX_CheckROIBoundaries( var Session : TIMAQDXSession ;
                                   var FFrameLeft : Integer ;
                                   var FFrameRight : Integer ;
                                   var FFrameTop : Integer ;
                                   var FFrameBottom : Integer ;
                                   var FBinFactor : Integer ;
                                   var FFrameWidth : Integer ;
                                   var FFrameHeight : Integer
                                   ) ;

function IMAQDX_AttributeAvailable(
         var Session : TIMAQDXSession ;
         AttributeName : PANSIChar ;
         CheckWritable : Boolean
         ) : Boolean ;

procedure IMAQDX_CheckError( ErrNum : Integer ) ;

function IMAQDX_CharArrayToString( cBuf : Array of ANSIChar ) : ANSIString ;

function IMAQDX_FindAttribute(
          var Session : TIMAQDXSession ;
          Name : ANSIString ) : Integer ;

procedure IMAQDX_SetAttribute(
          var Session : TIMAQDXSession ;
          Attribute : Integer ;
          Value : Integer
          ) ;

var

     IMAQdxSnap : TIMAQdxSnap;
     IMAQdxConfigureGrab : TIMAQdxConfigureGrab;
     IMAQdxGrab : TIMAQdxGrab;
     IMAQdxSequence : TIMAQdxSequence;
     IMAQdxDiscoverEthernetCameras : TIMAQdxDiscoverEthernetCameras ;
     IMAQdxEnumerateCameras : TIMAQdxEnumerateCameras ;
     IMAQdxResetCamera : TIMAQdxResetCamera ;
     IMAQdxOpenCamera : TIMAQdxOpenCamera ;
     IMAQdxCloseCamera : TIMAQdxCloseCamera ;
     IMAQdxConfigureAcquisition : TIMAQdxConfigureAcquisition ;
     IMAQdxStartAcquisition : TIMAQdxStartAcquisition ;
     IMAQdxGetImage : TIMAQdxGetImage ;
     IMAQdxGetImageData : TIMAQdxGetImageData ;
     IMAQdxStopAcquisition : TIMAQdxStopAcquisition ;
     IMAQdxUnconfigureAcquisition : TIMAQdxUnconfigureAcquisition ;
     IMAQdxEnumerateVideoModes : TIMAQdxEnumerateVideoModes ;
     IMAQdxEnumerateAttributes : TIMAQdxEnumerateAttributes ;
     IMAQdxGetAttribute : TIMAQdxGetAttribute ;
     IMAQdxSetAttribute : TIMAQdxSetAttribute ;
     IMAQdxSetAttributeEnum : TIMAQdxSetAttributeEnum ;     
     IMAQdxGetAttributeMinimum : TIMAQdxGetAttributeMinimum ;
     IMAQdxGetAttributeMaximum : TIMAQdxGetAttributeMaximum ;
     IMAQdxGetAttributeIncrement : TIMAQdxGetAttributeIncrement ;
     IMAQdxGetAttributeType : TIMAQdxGetAttributeType ;
     IMAQdxIsAttributeReadable : TIMAQdxIsAttributeReadable ;
     IMAQdxIsAttributeWritable : TIMAQdxIsAttributeWritable ;
     IMAQdxEnumerateAttributeValues : TIMAQdxEnumerateAttributeValues ;
     IMAQdxGetAttributeTooltip : TIMAQdxGetAttributeTooltip ;
     IMAQdxGetAttributeUnits : TIMAQdxGetAttributeUnits ;
     IMAQdxRegisterFrameDoneEvent : TIMAQdxRegisterFrameDoneEvent ;
     IMAQdxRegisterPnpEvent : TIMAQdxRegisterPnpEvent ;
     IMAQdxWriteRegister : TIMAQdxWriteRegister ;
     IMAQdxReadRegister : TIMAQdxReadRegister ;
     IMAQdxWriteMemory : TIMAQdxWriteMemory ;
     IMAQdxReadMemory : TIMAQdxReadMemory ;
     IMAQdxGetErrorString : TIMAQdxGetErrorString ;
     IMAQdxWriteAttributes : TIMAQdxWriteAttributes ;
     IMAQdxReadAttributes : TIMAQdxReadAttributes ;
     IMAQdxResetEthernetCameraAddress : TIMAQdxResetEthernetCameraAddress ;
     IMAQdxEnumerateAttributes2 : TIMAQdxEnumerateAttributes2 ;
     IMAQdxGetAttributeVisibility : TIMAQdxGetAttributeVisibility ;
     IMAQdxGetAttributeDescription : TIMAQdxGetAttributeDescription ;
     IMAQdxGetAttributeDisplayName : TIMAQdxGetAttributeDisplayName ;
     IMAQdxRegisterAttributeUpdatedEvent : TIMAQdxRegisterAttributeUpdatedEvent ;

implementation

uses sescam ;


var
    LibraryHnd : THandle ;         // PVCAM32.DLL library handle
    LibraryLoaded : boolean ;      // PVCAM32.DLL library loaded flag
    Val : Integer ;

procedure IMAQDX_LoadLibrary  ;
{ -------------------------------------
  Load IMAQ.DLL library into memory
  -------------------------------------}
var
    LibFileName : ANSIstring ;
begin

     { Load interface DLL library }
     LibFileName := 'NIIMAQDX.DLL' ;
     LibraryHnd := LoadLibrary( PANSIChar(LibFileName));

     { Get addresses of procedures in library }
     if LibraryHnd > 0 then begin

        @IMAQdxRegisterAttributeUpdatedEvent := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxRegisterAttributeUpdatedEvent') ;
        @IMAQdxGetAttributeDisplayName := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxGetAttributeDisplayName') ;
        @IMAQdxGetAttributeDescription := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxGetAttributeDescription') ;
        @IMAQdxGetAttributeVisibility := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxGetAttributeVisibility') ;
        @IMAQdxEnumerateAttributes2 := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxEnumerateAttributes2') ;
        @IMAQdxResetEthernetCameraAddress := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxResetEthernetCameraAddress') ;
        @IMAQdxReadAttributes := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxReadAttributes') ;
        @IMAQdxWriteAttributes := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxWriteAttributes') ;
        @IMAQdxGetErrorString := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxGetErrorString') ;
        @IMAQdxReadMemory := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxReadMemory') ;
        @IMAQdxWriteMemory := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxWriteMemory') ;
        @IMAQdxReadRegister := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxReadRegister') ;
        @IMAQdxWriteRegister := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxWriteRegister') ;
        @IMAQdxRegisterPnpEvent := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxRegisterPnpEvent') ;
        @IMAQdxRegisterFrameDoneEvent := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxRegisterFrameDoneEvent') ;
        @IMAQdxGetAttributeUnits := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxGetAttributeUnits') ;
        @IMAQdxGetAttributeTooltip:= IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxGetAttributeTooltip') ;
        @IMAQdxEnumerateAttributeValues := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxEnumerateAttributeValues') ;
        @IMAQdxIsAttributeWritable := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxIsAttributeWritable') ;
        @IMAQdxIsAttributeReadable := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxIsAttributeReadable') ;
        @IMAQdxGetAttributeType := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxGetAttributeType') ;
        @IMAQdxGetAttributeIncrement := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxGetAttributeIncrement') ;
        @IMAQdxGetAttributeMaximum := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxGetAttributeMaximum') ;
        @IMAQdxGetAttributeMinimum := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxGetAttributeMinimum') ;
        @IMAQdxSetAttribute := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxSetAttribute') ;
        @IMAQdxSetAttributeEnum := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxSetAttribute') ;
        @IMAQdxGetAttribute := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxGetAttribute') ;
        @IMAQdxEnumerateAttributes := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxEnumerateAttributes') ;
        @IMAQdxEnumerateVideoModes := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxEnumerateVideoModes') ;
        @IMAQdxUnconfigureAcquisition := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxUnconfigureAcquisition') ;
        @IMAQdxStopAcquisition := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxStopAcquisition') ;
        @IMAQdxGetImageData := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxGetImageData') ;
        @IMAQdxGetImage := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxGetImage') ;
        @IMAQdxStartAcquisition := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxStartAcquisition') ;
        @IMAQdxConfigureAcquisition := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxConfigureAcquisition') ;
        @IMAQdxCloseCamera := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxCloseCamera') ;
        @IMAQdxOpenCamera := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxOpenCamera') ;
        @IMAQdxResetCamera := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxResetCamera') ;
        @IMAQdxEnumerateCameras := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxEnumerateCameras') ;
        @IMAQdxDiscoverEthernetCameras := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxDiscoverEthernetCameras') ;
        @IMAQdxSequence := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxSequence') ;
        @IMAQdxGrab := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxGrab') ;
        @IMAQdxConfigureGrab := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxConfigureGrab') ;
        @IMAQdxSnap := IMAQDX_GetDLLAddress(LibraryHnd,'IMAQdxSnap') ;

        LibraryLoaded := True ;
        end
     else begin
          ShowMessage( 'IMAQDX: ' + LibFileName + ' not found!' ) ;
          LibraryLoaded := False ;
          end ;

     end ;


function IMAQDX_GetDLLAddress(
         Handle : Integer ;
         const ProcName : ANSIstring ) : Pointer ;
// -----------------------------------------
// Get address of procedure within PVCAM32.DLL
// -----------------------------------------
begin
    Result := GetProcAddress(Handle,PANSIChar(ProcName)) ;
    if Result = Nil then
       ShowMessage('NIIMAQDX.DLL: ' + ProcName + ' not found') ;
    end ;


function IMAQDX_OpenCamera(
          var Session : TIMAQDXSession ;   // Camera session
          var CameraMode : Integer ;       // Video mode
          var PixelFormat : Integer ;        // Pixel format
          var FrameWidthMax : Integer ;    // Returns max. frame width (pixels)
          var FrameHeightMax : Integer ;   // Returns max. frame height (pixels)
          var NumBytesPerPixel : Integer ; // Returns no. of bytes per pixel
          var PixelDepth : Integer ;       // Returns bits per pixel
          var BinFactorMax : Integer ;
          CameraInfo : TStringList         // Returns Camera details
          ) : Boolean ;
// ---------------------
// Open camera
// ---------------------
var
    Err : Integer ;
    i,j :Integer ;
    Supported : Boolean ;
    s : String ;
    Description : Array[0..255] of ANSIChar ;
    InterfaceType : Integer ;
    ColourSupported : Integer ;
    BoardType : String ;
    PixelFormatMax : Cardinal ;
begin

     Result := False ;

     // Load DLL libray
     if not LibraryLoaded then IMAQDX_LoadLibrary  ;
     if not LibraryLoaded then Exit ;

     // Discover available cameras
     Err := IMAQdxEnumerateCameras( Nil, Session.NumCameras, True) ;
     if Session.NumCameras > 0 then begin
        Err := IMAQdxEnumerateCameras( @Session.CameraInfo, Session.NumCameras, True) ;
        end
     else begin
        ShowMessage('IMAQDX: No cameras detected!') ;
        Exit ;
        end ;

     CameraInfo.Add( 'Interface Name: ' + String(Session.CameraInfo[0].InterfaceName) ) ;
     CameraInfo.Add( 'Vendor: ' + PANSIChar(String(Session.CameraInfo[0].VendorName)) ) ;
     CameraInfo.Add( 'Model: ' + String(Session.CameraInfo[0].ModelName) ) ;
     CameraInfo.Add( 'Camera File: ' + String(Session.CameraInfo[0].CameraFileName) ) ;
     CameraInfo.Add( 'URL: ' + String(Session.CameraInfo[0].CameraAttributeURL) ) ;

     // Open camera
     Err := IMAQdxOpenCamera (
             Session.CameraInfo[0].InterfaceName,
             IMAQdxCameraControlModeController,
             Session.ID) ;
     IMAQDX_CheckError( Err ) ;
     if Err = 0 then Session.CameraOpen := True
     else begin
        Session.CameraOpen := False ;
        ShowMessage('IMAQDX: Unable to open camera!') ;
        Exit ;
        end ;

     // Get list of available camera attributes
     Session.NumAttributes := 0 ;
     Err := IMAQdxEnumerateAttributes2( Session.id,
                                        Nil,
                                        Session.NumAttributes,
                                        PANSIChar(''),
                                        IMAQdxAttributeVisibilityAdvanced ) ;
     if Err = 0 then IMAQdxEnumerateAttributes2( Session.id,
                                                 @Session.Attributes,
                                                 Session.NumAttributes,
                                                 PANSIChar(''),
                                                 IMAQdxAttributeVisibilityAdvanced ) ;

     // Get attribute code
     Session.AttrVideoMode  := IMAQDX_FindAttribute( Session, 'AcquisitionAttributes::VideoMode' ) ;
     Session.AttrWidth := IMAQDX_FindAttribute( Session, 'AOI::Width' ) ;
     if Session.AttrWidth < 0 then Session.AttrWidth := IMAQDX_FindAttribute( Session, 'Width' ) ;
     Session.AttrHeight := IMAQDX_FindAttribute( Session, 'AOI::Height' ) ;
     if Session.AttrHeight < 0 then Session.AttrHeight := IMAQDX_FindAttribute( Session, 'Height' ) ;
     Session.AttrXOffset := IMAQDX_FindAttribute( Session, 'AOI::OffsetX' ) ;
     Session.AttrYOffset := IMAQDX_FindAttribute( Session, 'AOI::OffsetY' ) ;
     Session.AttrXBin := IMAQDX_FindAttribute( Session, 'AOI::BinningHorizontal' ) ;
     Session.AttrYBin := IMAQDX_FindAttribute( Session, 'AOI::BinningVertical' ) ;

     Session.AttrPixelFormat  := IMAQDX_FindAttribute( Session, 'ImageFormat::PixelFormat' ) ;
     if Session.AttrPixelFormat < 0 then Session.AttrPixelFormat  := IMAQDX_FindAttribute( Session, 'PixelFormat' ) ;
     Session.AttrBitsPerPixel  := IMAQDX_FindAttribute( Session, 'BitsPerPixel' ) ;
     Session.AttrPixelSize  := IMAQDX_FindAttribute( Session, 'PixelSize' ) ;
     Session.AttrExposureTime  := IMAQDX_FindAttribute( Session, 'ExposureTimeRaw' ) ;
     Session.AttrAcqInProgress  := IMAQDX_FindAttribute( Session, 'StatusInformation::AcqInProgress' ) ;
     Session.AttrLastBufferNumber  := IMAQDX_FindAttribute( Session, 'StatusInformation::LastBufferNumber' ) ;
     Session.AttrLastBufferCount  := IMAQDX_FindAttribute( Session, 'StatusInformation::LastBufferCount' ) ;
     Session.AttrTriggerMode :=  IMAQDX_FindAttribute( Session, 'AcquisitionTrigger::TriggerMode') ;
     Session.AttrTriggerSelector := IMAQDX_FindAttribute( Session, 'AcquisitionTrigger::TriggerSelector');
     Session.AttrTriggerSource := IMAQDX_FindAttribute( Session, 'AcquisitionTrigger::TriggerSource');
     Session.AttrTriggerActivation := IMAQDX_FindAttribute( Session, 'AcquisitionTrigger::TriggerActivation');
     // Area of interest supported by camera
     if (Session.AttrXOffset >= 0) and (Session.AttrYOffset >= 0) then Session.AOIAvailable := True
                                                                  else Session.AOIAvailable := False ;

     // Get no. of video modes
     if Session.AttrVideoMode >= 0 then begin
        IMAQdxGetAttributeMaximum( Session.id,
                                   Session.Attributes[Session.AttrVideoMode].Name,
                                   IMAQdxAttributeTypeU32,
                                   @Session.NumVideoModes ) ;

        IMAQdxEnumerateAttributeValues( Session.id,
                                        Session.Attributes[Session.AttrVideoMode].Name,
                                        @Session.VideoModes,
                                        Session.NumVideoModes ) ;

        end
     else begin
        CameraInfo.Add('None') ;
        CameraMode := 0 ;
        Session.VideoMode := 0 ;
        Session.NumVideoModes := 0 ;
        end ;


     // Pixel binning
     if (Session.AttrXBin >= 0) and (Session.AttrYBin >= 0) then begin
        // Set binning to 1X1 during opening of camera
        IMAQdxSetAttribute( Session.id,
                            Session.Attributes[Session.AttrXBin].Name,
                            IMAQdxAttributeTypeU32,
                            1) ;
        IMAQdxSetAttribute( Session.id,
                            Session.Attributes[Session.AttrYBin].Name,
                            IMAQdxAttributeTypeU32,
                            1) ;
        // Get maximum pixel binning
        IMAQdxGetAttributeMaximum( Session.id,
                                   Session.Attributes[Session.AttrXBin].Name,
                                   IMAQdxAttributeTypeU32,
                                   @BinFactorMax ) ;
        end
     else BinFactorMax := 1 ;


     // Pixel depth
     if Session.AttrBitsPerPixel >= 0 then begin
        CameraInfo.Add('Bits per pixel:') ;
        IMAQdxEnumerateAttributeValues( Session.id,
                                        Session.Attributes[Session.AttrBitsPerPixel].Name,
                                        Nil,
                                        Session.NumPixelSettings ) ;
        IMAQdxEnumerateAttributeValues( Session.id,
                                        Session.Attributes[Session.AttrBitsPerPixel].Name,
                                        @Session.PixelSettings,
                                        Session.NumPixelSettings ) ;
        for i := 0 to Session.NumPixelSettings-1 do begin
            CameraInfo.Add( IMAQDX_CharArrayToString(Session.PixelSettings[i].Name)) ;
            end ;
        end
     else   CameraInfo.Add('Bits per pixel attribute not available!') ;

     // Set video mode
     IMAQDX_SetVideoMode( Session,
                          CameraMode,
                          PixelFormat,
                          Session.FrameWidthMax,
                          Session.FrameHeightMax,
                          Session.NumBytesPerComponent,
                          Session.PixelDepth,
                          Session.GreyLevelMin,
                          Session.GreyLevelMax ) ;

     if Session.NumVideoModes > 1 then CameraInfo.Add( format('Video Mode: %s',[Session.VideoModes[Session.VideoMode].Name])) ;
     CameraInfo.Add( format('Pixel Format: %s',[Session.PixelFormats[Session.PixelFormat].Name])) ;

     CameraInfo.Add( format('CCD: Width %d, Height %d, Pixel depth %d',
                             [Session.FrameWidthMax,Session.FrameHeightMax,Session.PixelDepth]));


     CameraInfo.Add( 'Video Modes: ') ;
     for i := 0 to Session.NumVideoModes-1 do begin
         CameraInfo.Add( IMAQDX_CharArrayToString(Session.VideoModes[i].Name)) ;
         end ;

     CameraInfo.Add('Pixel formats:') ;
     for i := 0 to Session.NumPixelFormats-1 do begin
         CameraInfo.Add(Session.PixelFormats[i].Name) ;
         end ;

     // List camera attributes
     CameraInfo.Add('Camera Attributes:') ;
     for i := 0 to Session.NumAttributes-1 do begin
         s := IMAQDX_CharArrayToString( Session.Attributes[i].Name) ;
         if Session.Attributes[i].Readable then s := s + ' R' ;
         if Session.Attributes[i].Writable then s := s + 'W' ;
         CameraInfo.Add( s ) ;
         end ;


//     CameraInfo.Add(format('Image size: %d x %d pixels (%d bits/pixel)',
//                    [Session.FrameWidthMax,Session.FrameHeightMax,PixelDepth])) ;

     // Clear flags
     Session.AcquisitionInProgress := False ;
     Session.CameraOpen := True ;
     Session.Buf := Nil ;

     CameraMode := Session.VideoMode ;
     PixelFormat := Session.PixelFormat ;
     FrameWidthMax := Session.FrameWidthMax ;
     FrameHeightMax := Session.FrameHeightMax ;
     NumBytesPerPixel := Session.NumBytesPerComponent ;
     PixelDepth := Session.PixelDepth  ;

     Result := True ;

     end ;


function IMAQDX_FindAttribute(
          var Session : TIMAQDXSession ;
          Name : ANSIString ) : Integer ;
// ----------------------------------------------------
// Find camera attribute matching Name and return index
// ----------------------------------------------------
var
    i : Integer ;
    s : ANSIString ;
begin
     Result := -1 ;
     for i := 0 to Session.NumAttributes-1 do begin
         s := IMAQDX_CharArrayToString( Session.Attributes[i].Name) ;
         if ANSIContainsText( s, Name ) then begin
            Result := i ;
            Break ;
            end ;
         end ;
     end ;


procedure IMAQDX_SetVideoMode(
          var Session : TIMAQDXSession ;
          VideoMode : Integer ;
          PixelFormat : Integer ;
          var FrameWidthMax : Integer ;  // Returns camera frame width
          var FrameHeightMax : Integer ; // Returns camera height width
          var NumBytesPerComponent : Integer ; // Returns bytes/pixel
          var PixelDepth : Integer ;        // Returns no. bits/pixel
          var GreyLevelMin : Integer ;      // Min. grey level
          var GreyLevelMax : Integer        // Max. grey level
          ) ;
// --------------
// Set video mode
// --------------
var
    i,Err : Integer ;
begin

      // Set mode (if available)
      if Session.AttrVideoMode >= 0 then
         Err := IMAQdxSetAttribute( Session.id,
                             Session.Attributes[Session.AttrVideoMode].Name,
                             IMAQdxAttributeTypeU32,
                             VideoMode) ;

   //      If Err <> 0 then ShowMessage('Video mode error') ;

      // Set top-left of AOI to 0,0 and binning to 1
      // to ensure that maximum of AOI width and heght correctly reported

      if Session.AttrXOffset >= 0 then
         IMAQdx_SetAttribute( Session,Session.AttrXOffset, 0 ) ;
      if Session.AttrYOffset >= 0 then
         IMAQdx_SetAttribute( Session,Session.AttrYOffset, 0 ) ;
      if Session.AttrXBin >= 0 then
         IMAQdx_SetAttribute( Session,Session.AttrXBin, 1 ) ;
      if Session.AttrYBin >= 0 then
         IMAQdx_SetAttribute( Session,Session.AttrYBin, 1 ) ;

     // Max. Image width
     if Session.AttrWidth >= 0 then begin
        IMAQdxGetAttributeMaximum( Session.id,
                                   Session.Attributes[Session.AttrWidth].Name,
                                   IMAQdxAttributeTypeU32,
                                   @Session.FrameWidthMax ) ;
        end ;
     FrameWidthMax := Session.FrameWidthMax ;

     if Session.AttrHeight >= 0 then begin
        IMAQdxGetAttributeMaximum( Session.id,
                                   Session.Attributes[Session.AttrHeight].Name,
                                   IMAQdxAttributeTypeU32,
                                   @Session.FrameHeightMax ) ;
        end ;
     FrameHeightMax := Session.FrameHeightMax ;

     // Get pixel formats available in this video mode
     if Session.AttrPixelFormat >= 0 then begin
        IMAQdxEnumerateAttributeValues( Session.id,
                                        Session.Attributes[Session.AttrPixelFormat].Name,
                                        Nil,
                                        Session.NumPixelFormats ) ;
        IMAQdxEnumerateAttributeValues( Session.id,
                                        Session.Attributes[Session.AttrPixelFormat].Name,
                                        @Session.PixelFormats,
                                        Session.NumPixelFormats ) ;
        end ;

     // Set pixel format
     IMAQDX_SetPixelFormat( Session,
                            PixelFormat,
                            NumBytesPerComponent,
                            PixelDepth ) ;

     GreyLevelMin := 0 ;
     GreyLevelMax := 1 ;
     for i := 1 to PixelDepth do  GreyLevelMax := GreyLevelMax*2 ;
     GreyLevelMax := GreyLevelMax - 1 ;
     end ;


function IMAQDX_GetVideoMode(
          var Session : TIMAQDXSession ) : Integer ;
// --------------
// Get video mode
// --------------
var
    Mode : Integer ;
begin
      if Session.AttrVideoMode >= 0 then begin
         IMAQdxGetAttribute( Session.id,
                             Session.Attributes[Session.AttrVideoMode].Name,
                             IMAQdxAttributeTypeU32,
                             @Mode) ;
         Result := Mode ;
         end
      else Result := 0 ;

      end ;


procedure IMAQDX_SetPixelFormat(
          var Session : TIMAQDXSession ;
          var PixelFormat : Integer ;               // Video mode
          var NumBytesPerComponent : Integer ; // Returns bytes/pixel
          var PixelDepth : Integer         // Returns no. bits/pixel
          ) ;
// ----------------
// Set pixel format
// ----------------
var
    Err : Integer ;
    iValue : Dword ;
begin

    // Set pixel format (if attribute available)
    if Session.AttrPixelFormat < 0 then PixelFormat := 0 ;
    IMAQdx_SetAttribute( Session,
                         Session.AttrPixelFormat,
                         Session.PixelFormats[Session.PixelFormat].Value ) ;

     PixelFormat := Min(PixelFormat,Session.NumPixelFormats-1);
     Session.PixelFormat := PixelFormat ;

     // Set image format
     if ANSIContainsText(String(Session.PixelFormats[Session.PixelFormat].Name),'RGB 8') then begin
        Session.NumPixelComponents := 3 ;
        Session.UseComponent := 1 ;
        PixelDepth := 8 ;
        end
     else if ANSIContainsText(String(Session.PixelFormats[Session.PixelFormat].Name),'YUV 422') then begin
        Session.NumPixelComponents := 2 ;
        Session.UseComponent := 1 ;
        PixelDepth := 8 ;
        end
     else if ANSIContainsText(String(Session.PixelFormats[Session.PixelFormat].Name),'Mono 8') then begin
        Session.NumPixelComponents := 1 ;
        Session.UseComponent := 0 ;
        PixelDepth := 8 ;
        end
     else if ANSIContainsText(String(Session.PixelFormats[Session.PixelFormat].Name),'Mono 12') then begin
        Session.NumPixelComponents := 1 ;
        Session.UseComponent := 0 ;
        PixelDepth := 12 ;
        end
     else if ANSIContainsText(String(Session.PixelFormats[Session.PixelFormat].Name),'BGRA 8') then begin
        Session.NumPixelComponents := 4 ;
        Session.UseComponent := 1 ;
        PixelDepth := 8 ;
        end
     else begin
        Session.NumPixelComponents := 1 ;
        Session.UseComponent := 0 ;
        PixelDepth := 8 ;
        end ;

     // Bytes per pixel
     if PixelDepth <= 8 then Session.NumBytesPerComponent := 1
                        else Session.NumBytesPerComponent := 2 ;
     NumBytesPerComponent := Session.NumBytesPerComponent ;

     end ;


procedure IMAQDX_CheckROIBoundaries( var Session : TIMAQDXSession ;
                                   var FFrameLeft : Integer ;
                                   var FFrameRight : Integer ;
                                   var FFrameTop : Integer ;
                                   var FFrameBottom : Integer ;
                                   var FBinFactor : Integer ;
                                   var FFrameWidth : Integer ;
                                   var FFrameHeight : Integer
                                   ) ;
// -------------------------------
// Ensure ROI boundaries are valid
// -------------------------------
var
    Err : Integer ;
begin

      if not Session.CameraOpen then Exit ;

      FFrameLeft := Min(Max(FFrameLeft,0),Session.FrameWidthMax-1) ;
      FFrameTop := Min(Max(FFrameTop,0),Session.FrameHeightMax-1) ;
      FFrameRight := Min(Max(FFrameRight,FFrameLeft),Session.FrameWidthMax-1) ;
      FFrameBottom := Min(Max(FFrameBottom,FFrameTop),Session.FrameHeightMax-1) ;

      FFrameLeft := FFrameLeft div FBinFactor ;
      FFrameTop := FFrameTop div FBinFactor ;
      FFrameRight := FFrameRight div FBinFactor ;
      FFrameBottom := FFrameBottom div FBinFactor ;

      // Set horizontal binning
      IMAQdx_SetAttribute( Session,Session.AttrXBin, FBinFactor ) ;

      // Set vertical binning
      IMAQdx_SetAttribute( Session,Session.AttrYBin, FBinFactor ) ;

      // Left edge of CCD readout area
      IMAQdx_SetAttribute( Session,Session.AttrXOffset, FFrameLeft ) ;

      // Set top edge of CCD readout areas
      IMAQdx_SetAttribute( Session,Session.AttrYOffset, FFrameTop ) ;

      // Set width of CCD readout areas
      FFrameWidth := FFrameRight - FFrameLeft + 1 ;
      IMAQdx_SetAttribute( Session,Session.AttrWidth, FFrameWidth ) ;

      // Set height of CCD readout areas
      FFrameHeight := FFrameBottom - FFrameTop + 1 ;
      IMAQdx_SetAttribute( Session,Session.AttrHeight, FFrameHeight ) ;

     FFrameRight := (FFrameLeft + FFrameWidth)*FBinFactor -1;
     FFrameBottom := (FFrameTop + FFrameHeight)*FBinFactor -1;
     FFrameLeft := FFrameLeft*FBinFactor ;
     FFrameTop := FFrameTop*FBinFactor ;
     Session.FrameHeight := FFrameHeight ;
     Session.FrameWidth := FFrameWidth ;

     end ;


procedure IMAQDX_CloseCamera(
          var Session : TIMAQDXSession     // Camera session #
          ) ;
// ----------------
// Shut down camera
// ----------------
begin

     if not LibraryLoaded then Exit ;

     // Stop any acquisition which is in progress
     if Session.AcquisitionInProgress then begin
       IMAQdxStopAcquisition( Session.ID ) ;
       IMAQDX_CheckError(IMAQdxUnconfigureAcquisition(Session.ID)) ;
       Session.AcquisitionInProgress := false ;
       end ;

    // Close camers
    IMAQdxCloseCamera( Session.ID ) ;
    Session.CameraOpen := False ;

    // Unload library
    FreeLibrary(libraryHnd) ;
    LibraryLoaded := False ;

    end ;


function IMAQDX_StartCapture(
         var Session : TIMAQDXSession ;          // Camera session #
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
    FrameRight,FrameBottom : Integer ;
    TriggerMode,ExpTimeMicroSec : Integer ;
begin

      // Stop any acquisition which is in progress
      if Session.AcquisitionInProgress then begin
          IMAQDX_StopCapture( Session ) ;
          end ;

      // Set AOI boundaries
      FrameRight := FrameLeft + FrameWidth - 1 ;
      FrameBottom := FrameTop + FrameHeight - 1 ;
      IMAQDX_CheckROIBoundaries( Session,
                                 FrameLeft,
                                 FrameRight,
                                 FrameTop,
                                 FrameBottom,
                                 BinFactor,
                                 FrameWidth,
                                 FrameHeight) ;

      // Set exposure time
      IMAQdx_SetAttribute( Session,Session.AttrExposureTime, Round(ExposureTime*1E6) ) ;
      if Session.AttrExposureTime >= 0 then begin
         IMAQdxGetAttribute( Session.id,
                             Session.Attributes[Session.AttrExposureTime].Name,
                             IMAQdxAttributeTypeU32,
                             @ExpTimeMicroSec) ;
         ExposureTime := ExpTimeMicroSec*1E-6 ;
         end ;

      // Allocate camera buffer
      if Session.Buf <> Nil then FreeMem(Session.Buf) ;
      Session.BufSize := Session.FrameWidthMax*Session.FrameHeightMax*
                         Session.NumPixelComponents*Session.NumBytesPerComponent ;
      GetMem( Session.Buf, Session.BufSize ) ;

      // Set up ring buffer
      IMAQDX_CheckError( IMAQdxConfigureAcquisition( Session.ID,
                                                     1,
                                                     NumFramesInBuffer)) ;
                                                     
      Session.NumFramesInBuffer := NumFramesInBuffer ;
      Session.FrameBufPointer := PFrameBuffer ;
      Session.NumBytesPerFrame := NumBytesPerFrame ;
      Session.BufferIndex := 0 ;
      Session.FrameCounter := 0 ;
      Session.FrameHeight := FrameHeight ;
      Session.FrameWidth := FrameWidth ;
      Session.FrameLeft := FrameLeft ;
      Session.FrameTop := FrameTop ;

     // Internal/external triggering of frame capture
     if ExternalTrigger = CamFreeRun then begin
        // Free run trigger mode
        TriggerMode := 0 ;
        IMAQdx_SetAttribute( Session,Session.AttrTriggerMode, TriggerMode ) ;
        end
     else begin
        // External trigger
        TriggerMode := 1 ;
        IMAQdx_SetAttribute( Session,Session.AttrTriggerMode, TriggerMode ) ;
        IMAQdx_SetAttribute( Session,Session.AttrTriggerSelector, 1 ) ;   // Trigger frame
        IMAQdx_SetAttribute( Session,Session.AttrTriggerSource, 1 ) ;     // Line 1
        IMAQdx_SetAttribute( Session,Session.AttrTriggerActivation, 0 ) ; //Rising Edge
        end ;

     // Start acquisition
     IMAQDX_CheckError(IMAQdxStartAcquisition(Session.id));

     Result := True ;
     Session.AcquisitionInProgress := True ;

     end;


procedure IMAQDX_SetAttribute(
          var Session : TIMAQDXSession ;           // Camera session #
          Attribute : Integer ;
          Value : Integer
          ) ;
// -------------
// Set attribute
// -------------
begin

      if Attribute < 0 then Exit ;
      if not Session.Attributes[Attribute].Writable then Exit ;

      IMAQdxSetAttribute( Session.id,
                          Session.Attributes[Attribute].Name,
                          IMAQdxAttributeTypeU32,
                          Value) ;

      end ;

procedure IMAQDX_StopCapture(
          var Session : TIMAQDXSession            // Camera session #
          ) ;
// -----------------
// Stop frame capture
// ------------------
begin

     if not Session.AcquisitionInProgress then Exit ;

     // Stop acquisition
     IMAQDX_CheckError(IMAQdxStopAcquisition(Session.ID)) ;

     IMAQDX_CheckError(IMAQdxUnconfigureAcquisition(Session.ID)) ;

     FreeMem( Session.Buf ) ;
     Session.Buf := Nil ;

     Session.AcquisitionInProgress := False ;

     end;


procedure IMAQDX_GetImage(
          var Session : TIMAQDXSession
          ) ;
// -----------------------------------------------------
// Copy images from IMAQ buffer to circular frame buffer
// -----------------------------------------------------
var
    i,j,y,x : Cardinal ;
    Err : Integer ;
    t0 :Integer ;
    Status,LatestIndex :Integer ;
    PFromBuf, PToBuf : Pointer ;
    ActualBufferNumber,LatestFrameCount,LatestFrameTransferred,NumCopied : Cardinal ;
    AcqInProgress : LongBool ;
begin

    if not Session.AcquisitionInProgress then Exit ;
    if Session.AttrAcqInProgress < 0 then Exit ;
    if Session.AttrLastBufferNumber < 0 then Exit ;
    if Session.AttrLastBufferCount < 0 then Exit ;

    // If no buffers yet .. exit
    IMAQdxGetAttribute( Session.ID,
                        Session.Attributes[Session.AttrLastBufferCount].Name,
                        IMAQdxAttributeTypeU32,
                        @LatestFrameCount ) ;
    if LatestFrameCount <= 0 then Exit ;

    // Get latest buffer
    IMAQdxGetAttribute( Session.ID,
                        Session.Attributes[Session.AttrLastBufferNumber].Name,
                        IMAQdxAttributeTypeU32,
                        @LatestFrameTransferred ) ;

//    outputdebugstring(pchar(format('%d %d',[LatestFrameTransferred,LatestFrameCount])));

    // Copy all new frames to output buffer

    NumCopied := 0 ;
    while (LatestFrameTransferred > Session.FrameCounter) and
          (NumCopied < Session.NumFramesInBuffer) do begin

       // Try to read latest frame
       Err := IMAQdxGetImageData( Session.id,
                              Session.Buf,
                              Session.BufSize,
                              IMAQdxBufferNumberModeBufferNumber,
                              Session.FrameCounter,
                              ActualBufferNumber);

       IMAQDX_CheckError( Err ) ;
       if Err = 0 then begin
          // If frame available copy to output to frame buffer
          PToBuf := Pointer( (Session.BufferIndex*Session.NumBytesPerFrame)
                             + Cardinal(Session.FrameBufPointer) ) ;
          i := 0 ;
          if Session.AOIAvailable then begin
              // In-camera AOI available... copy whole image to buffer
              if Session.NumBytesPerComponent = 1 then begin
                 // one byte pixels
                 j := Session.UseComponent ;
                 for i := 0 to (Session.FrameHeight*Session.FrameWidth*Session.NumPixelComponents)-1 do begin
          //           PByteArray(Session.Buf)^[j] := PByteArray(Session.Buf)^[j] shr 8 ;
                     PByteArray(PToBuf)^[i] := PByteArray(Session.Buf)^[j] ;
                     j := j + Session.NumPixelComponents ;
                     end ;
                 end
              else begin
                 // two byte pixels
                 j := Session.UseComponent ;
                 for i := 0 to (Session.FrameHeight*Session.FrameWidth*Session.NumPixelComponents)-1 do begin
                     PWordArray(PToBuf)^[i] := PWordArray(Session.Buf)^[j] ;
                     j := j + Session.NumPixelComponents ;
                     end ;
                 end ;
              end
          else begin
              // Software AOI - copy area of interest to buffer
              for y := Session.FrameTop to Session.FrameTop + Session.FrameHeight -1 do begin
                 j := (y*Session.FrameWidthMax + Session.FrameLeft)*Session.NumPixelComponents
                      + Session.UseComponent ;
                 for x := 0 to Session.FrameWidth -1 do begin
                     PByteArray(PToBuf)^[i] := PByteArray(Session.Buf)^[j] ;
                     j := j + Session.NumPixelComponents ;
                     Inc(i) ;
                     end ;
                 end ;
              end ;
          // Increment circular output buffer index
          Inc(Session.BufferIndex) ;
          if Session.BufferIndex >= Session.NumFramesInBuffer then Session.BufferIndex := 0 ;
          // Increment next buffer counter
          Inc(Session.FrameCounter) ;
          Inc(NumCopied) ;
          end ;
       end ;

    end ;


procedure IMAQDX_GetCameraGainList( CameraGainList : TStringList ) ;
// --------------------------------------------
// Get list of available camera amplifier gains
// --------------------------------------------
var
    i : Integer ;
begin
    CameraGainList.Clear ;
    for i := 1 to 1 do CameraGainList.Add( format( '%d',[i] )) ;
    end ;


procedure IMAQDX_GetCameraVideoModeList(
          var Session : TIMAQDXSession ;
          List : TStringList ) ;
// --------------------------------------------
// Get list of available camera video mode
// --------------------------------------------
var
    i : Integer ;
begin

    List.Clear ;
    for i := 0 to Session.NumVideoModes-1 do begin
        List.Add(String(Session.VideoModes[i].Name)) ;
        end ;

    end ;


procedure IMAQDX_GetCameraPixelFormatList(
          var Session : TIMAQDXSession ;
          List : TStringList ) ;
// --------------------------------------------
// Get list of available camera video mode
// --------------------------------------------
var
    i : Integer ;
begin

    List.Clear ;
    for i := 0 to Session.NumPixelFormats-1 do begin
        List.Add(String(Session.PixelFormats[i].Name)) ;
        end ;

    end ;


function IMAQDX_CheckFrameInterval(
         var Session : TIMAQDXSession ;
         var FrameInterval : Double
         ) : Integer ;
// -------------------------------------------
// Check that selected frame interval is valid
// -------------------------------------------
//
var
    iInterval : Cardinal ;

begin

     // Get frame interval (this is a read-only value)
     IMAQdxGetAttribute( Session.ID,
                         IMAQdxAttributeFrameInterval,
                         IMAQdxAttributeTypeF64,
                         @FrameInterval ) ;
     FrameInterval := FrameInterval*0.001 ;

     end ;


procedure IMAQDX_CheckError( ErrNum : Integer ) ;
// ------------
// Report error
// ------------
const
    MaxMsgSize = 256 ;
var
    cBuf : Array[0..MaxMsgSize-1] of ANSIChar ;
    i : Integer ;
    s : string ;
begin

    if ErrNum <> 0 then begin
       for i := 0 to High(cBuf) do cBuf[i] := #0 ;

       IMAQdxGetErrorString( ErrNum, cBuf, MaxMsgSize ) ;
       s := '' ;
       for i := 0 to High(cBuf) do if cBuf[i] <> #0 then s := s + cBuf[i] ;
       ShowMessage( 'IMAQ: ' + s ) ;
       end ;

    end ;


function IMAQDX_CharArrayToString(
         cBuf : Array of ANSIChar
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

function IMAQDX_AttributeAvailable(
         var Session : TIMAQDXSession ;
         AttributeName : PANSIChar ;
         CheckWritable : Boolean
         ) : Boolean ;
// -------------------------------------
// Return TRUE if Attribute is available
// -------------------------------------
var
    i : Integer ;
    s : string ;
begin
      Result := False ;
      for i := 0 to Session.NumAttributes-1 do begin
          s := IMAQDX_CharArrayToString(Session.Attributes[i].Name) ;
          if AnsiContainsText(s,AttributeName) then begin
             if CheckWritable then Result := Session.Attributes[i].Writable
                              else Result := True ;
             Break ;
             end ;
          end ;
      end ;


end.
