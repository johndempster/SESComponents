unit HamC4880;
{ =========================================================================================
  HamC4880 - Hamamatsu C4880-81 control software (c) J. Dempster, University of Strathclyde
  23/08/01 Started
  17/06/03
  60/6/5 .... C4880_GetCameraGainList now supplies correct gain list
  08/07/05 .. Readout time now functions
  17/7/07 ... External frame trigger mode now works
              Upper limit (255 frame read times) now imposed on exposure time
  24/7/07 ... CCD readout region only changed when required to reduce delay in starting camera

  ========================================================================================= }
interface

uses SESCam,Dialogs,SysUtils, Maths, Windows, Classes, StrUtils, math ;

    { Private declarations }
const
    FastReadout = 0 ;
    SlowReadout = 1 ;
var
    ComPort : Integer ;
    ComHandle : Integer ;
    Reply : string ;

    function C4880_OpenCamera(
             ComPortNum : Integer ;
             ReadoutRate : Integer ;          // Readout rate (fast/slow)
             CameraInfo : TStringList
             ) : Boolean ;
    procedure C4880_CloseCamera ;
    function C4880_StartCapture(
             ReadoutRate : Integer ;
             var ExposureTime : Double ;
             AmpGain : Integer ;
             ExternalTrigger : Integer ;
             FrameLeft : Integer ;            // Left pixel in CCD readout area
             FrameTop : Integer ;             // Top pixel in CCD eadout area
             FrameWidth : Integer ;           // Width of CCD readout area
             FrameHeight : Integer ;           // Width of CCD readout area
             BinFactor : Integer ;
             var ReadoutTimeLimit : Double         // Frame readout time (s) (return)
             ) : Boolean ;

    function C4880_CheckFrameInterval(
         FrameLeft : Integer ;            // Left pixel in CCD readout area
         FrameTop : Integer ;             // Top pixel in CCD eadout area
         FrameWidth : Integer ;           // Width of CCD readout area
         FrameHeight : Integer ;          // Width of CCD readout area
         BinFactor : Integer ;             // Binning factor (1,2,4,8,16)
         ReadoutRate : Integer ;          // Readout rate (fast/slow)
         var ExposureTime : Double ;      // Frame exposure time
         var ReadoutTime : Double         // Frame readout time (s) (return)
         ) : Boolean ;


    procedure C4880_StopCapture ;

    procedure C4880_GetCameraGainList( CameraGainList : TStringList ) ;
    procedure C4880_GetCameraReadoutSpeedList( CameraReadoutSpeedList : TStringList ) ;

    function SendCommand( Command : string ) : string ;
    function SendQuery( Command : string ) : string ;
    function OpenCOMPort : Boolean ;
    procedure CloseCOMPort ;
    procedure TransmitLine( const Line : string ) ;
    function ReceiveLine : string ;


implementation

var

     OldFrameLeft : Integer ;
     OldFrameTop : Integer ;
     OldFrameWidth : Integer ;
     OldFrameHeight : Integer ;
     OldBinFactor : Integer ;

function C4880_OpenCamera(
          ComPortNum : Integer ;
          ReadoutRate : Integer ;          // Readout rate (fast/slow)
          CameraInfo : TStringList
          ) : Boolean ;
// ------------------------------------------
// Open COM link to C4880 camera and reset it
// ------------------------------------------
var
    Reply : string ;
begin

     Result := False ;

     // Close COM port if it is already open
     CloseCOMPort ;

     // Get new COM port selection
     ComPort := ComPortNum ;

     // Open port
     if not OpenCOMPort then begin
        ShowMessage( 'Could not open COM port link with camera' ) ;
        Exit ;
        end ;

     // Reset camera to initial conditions
     Reply := SendCommand( 'INI' ) ;
     Reply := SendCommand( 'SMD E' ) ;

     if ReadoutRate = FastReadout then
        CameraInfo.Add('Pixel depth=' + SendQuery( '?CAI I' ) + ' bits' )
     else
        CameraInfo.Add('Pixel depth=' + SendQuery( '?CAI S' ) + ' bits' ) ;

     CameraInfo.Add('CCD=' + SendQuery( '?CHP' ) ) ;
     CameraInfo.Add('ROM Version=' + SendQuery( '?ROM' ) ) ;

     OldFrameLeft := -1 ;
     OldFrameTop := -1 ;
     OldFrameWidth := -1 ;
     OldFrameHeight := -1 ;
     OldBinFactor := -1 ;

     Result := True ;

     end ;


procedure C4880_CloseCamera ;
// ----------------
// Shut down camera
// ----------------
begin

    // Stop frame capture
    C4880_StopCapture ;

    // Close serial port
    CloseCOMPort ;

    end ;


function C4880_StartCapture(
         ReadoutRate : Integer ;          // Readout rate (fast/slow)
         var ExposureTime : Double ;      // Frame exposure time
         AmpGain : Integer ;              // Camera amplifier gain index
         ExternalTrigger : Integer ;      // Trigger mode
         FrameLeft : Integer ;            // Left pixel in CCD readout area
         FrameTop : Integer ;             // Top pixel in CCD eadout area
         FrameWidth : Integer ;           // Width of CCD readout area
         FrameHeight : Integer ;          // Width of CCD readout area
         BinFactor : Integer ;            // Binning factor (1,2,4,8,16)
         var ReadoutTimeLimit : Double    // Frame readout time (s) (return)
         ) : Boolean ;
// -------------------
// Start frame capture
// -------------------
var
    Command,Reply : string ;
    NumAccFrames : Integer ;  // No. readout frames to accumulate
    FrameReadTime : Single ;
begin

     Command := '' ;

     // Set scan rate/pixel resolution (10 bit/high speed, 12 bit high res.)
     if ReadoutRate = FastReadout then Reply := SendCommand('SSP H')
                                  else Reply := SendCommand('SSP S') ;

     // Set amplifier gain
     if AmpGain = 0 then
        Reply := SendCommand('SAG L')
     else if AmpGain = 1 then
        Reply := SendCommand('SAG H')
     else
        Reply := SendCommand('SAG S') ;

     // Internal/external triggering of frame capture
     if ExternalTrigger = CamFreeRun then Reply := SendCommand('AMD I')
                                     else Reply := SendCommand('AMD E') ;

     if (FrameLeft <> OldFrameLeft) or
        (FrameTop <> OldFrameTop) or
        (FrameWidth <> OldFrameWidth) or
        (FrameHeight <> OldFrameHeight) or
        (BinFactor <> OldBinFactor) then begin

        // Set camera to extended scan mode (to support binning/sub-areas
        Reply := SendCommand('SMD E') ;

        // Reset scan region
        Reply := SendCommand('SAR R') ;

        // Set scan region and binning
        Command := format('SAR %d,%d,%d,%d,%d',
                         [FrameLeft,
                          FrameTop,
                          FrameWidth,
                          FrameHeight,
                          BinFactor] ) ;

        // Send command sequence to camera
        Reply := SendCommand( Command ) ;

        OldFrameLeft := FrameLeft ;
        OldFrameTop := FrameTop ;
        OldFrameWidth := FrameWidth ;
        OldFrameHeight := FrameHeight ;
        OldBinFactor := BinFactor ;

        end ;

     // Get frame readout time
     Reply := SendQuery( '?FRT' ) ;
     FrameReadTime := ExtractFloat(Reply, 1.0) ;

     // Set exposure time limit
     if (BinFactor = 1) and ((FrameWidth*FrameHeight) > (300*250)) then begin
        ReadoutTimeLimit := 3.0*FrameReadTime ;
        end
     else ReadoutTimeLimit := 2.0*FrameReadTime ;

     // Keep exposure time above limit
     if ExposureTime < ReadoutTimeLimit then ExposureTime := ReadoutTimeLimit ;

     // No.of frames to accumulate

     if ExternalTrigger <> CamFreeRun then begin
        // External frame trigger
        NumAccFrames := Min(Max(Round(ExposureTime/FrameReadTime)-2,1),255) ;
        Reply := SendCommand( format('FCN %d',[1]) ) ;
        Reply := SendCommand( format('AET %d',[NumAccFrames]) ) ;
        end
     else begin
        // Internal frame trigger
        NumAccFrames := Min(Max(Round(ExposureTime/FrameReadTime),1),255) ;
        Reply := SendCommand( format('AET %d',[NumAccFrames]) ) ;
        // Only update exposure time if in internal timing mode
        ExposureTime := NumAccFrames*FrameReadTime ;
        end ;

     // Start continuous capture
     Reply := SendCommand('MON') ;

     Result := True ;

     end;


procedure C4880_StopCapture ;
// ------------------
// Stop frame capture
// ------------------
begin
        Reply := SendCommand('STP') ;
        Reply := ReceiveLine ;
        end;


function C4880_CheckFrameInterval(
         FrameLeft : Integer ;            // Left pixel in CCD readout area
         FrameTop : Integer ;             // Top pixel in CCD eadout area
         FrameWidth : Integer ;           // Width of CCD readout area
         FrameHeight : Integer ;          // Width of CCD readout area
         BinFactor : Integer ;             // Binning factor (1,2,4,8,16)
         ReadoutRate : Integer ;          // Readout rate (fast/slow)
         var ExposureTime : Double ;      // Frame exposure time
         var ReadoutTime : Double         // Frame readout time (s) (return)
         ) : Boolean ;
// -------------------
// Check frame interval and return nearest valid interval and readout time
// -------------------
var
    Command,Reply : string ;
    NumAccFrames : Integer ;  // No. readout frames to accumulate
begin

     Command := '' ;

     // Set scan rate/pixel resolution (10 bit/high speed, 12 bit high res.)
     if ReadoutRate = FastReadout then Reply := SendCommand('SSP H')
                                  else Reply := SendCommand('SSP S') ;

     // Set camera to extended scan mode (to support binning/sub-areas
     Reply := SendCommand('SMD E') ;

     // Reset scan region
     Reply := SendCommand('SAR R') ;
     // Set scan region and binning
     Command := format('SAR %d,%d,%d,%d,%d',
                         [FrameLeft,
                          FrameTop,
                          FrameWidth,
                          FrameHeight,
                          BinFactor] ) ;

     // Send command sequence to camera
     Reply := SendCommand( Command ) ;

     // Get frame readout time
     Reply := SendQuery( '?FRT' ) ;
     ReadoutTime := ExtractFloat(Reply, 1.0) ;

     // No.of frames to accumulate
     NumAccFrames := Min(Max(Round(ExposureTime/ReadoutTime),1),255) ;
     ExposureTime := NumAccFrames*ReadoutTime ;

     Result := True ;

     end;


procedure C4880_GetCameraGainList( CameraGainList : TStringList ) ;
// --------------------------------------------
// Get list of available camera amplifier gains
// --------------------------------------------
begin
    CameraGainList.Clear ;
    CameraGainList.Add( ' Low ' ) ;
    CameraGainList.Add( ' High ' ) ;
    CameraGainList.Add( ' Super-High ' ) ;
    end ;


procedure C4880_GetCameraReadoutSpeedList( CameraReadoutSpeedList : TStringList ) ;
// -------------------------------------------
// Get list of available camera readout speeds
// -------------------------------------------
begin
    CameraReadoutSpeedList.Clear ;
    CameraReadoutSpeedList.Add( ' Slow ' ) ;
    CameraReadoutSpeedList.Add( ' Fast ' ) ;
    end ;


function SendCommand( Command : string ) : string ;
// ----------------------
// Send command to camera
// ----------------------
var
    RetString : String ;
begin

    TransmitLine( Command ) ;
    RetString := '' ;
    While (LeftStr(RetString,3) <> LeftStr(Command,3)) and (RetString <> 'E3') do
        RetString := ReceiveLine ;
    if RetString = 'E3' then MessageDlg( ' Error in command '+ Command, mtWarning, [mbOK], 0 ) ;
    Result := RetString ;
    end ;


function SendQuery( Command : string ) : string ;
// ----------------------
// Send command to camera
// ----------------------
begin
    TransmitLine( Command ) ;
    Result := ReceiveLine ;
    Result := RightStr( Result, Length(Result) - Length(Command) );
    if Result = 'E3' then MessageDlg( ' Error in command '+ Command, mtWarning, [mbOK], 0 ) ;
    end ;


// *** Com port communications methods ***

function OpenCOMPort : Boolean ;
//
// Open com port link with camera
// ------------------------------
var
   DCB : TDCB ;           { Device control block for COM port }
   CommTimeouts : TCommTimeouts ;
begin

     if ComPort <= 1 then ComPort := 1 ;
     if ComPort >= 2 then ComPort := 2 ;

     { Open com port  }
     ComHandle :=  CreateFile( PCHar(format('COM%d',[ComPort])),
                               GENERIC_READ or GENERIC_WRITE,
                               0,
                               Nil,
                               OPEN_EXISTING,
                               FILE_ATTRIBUTE_NORMAL,
                               0) ;

     if ComHandle >= 0 then begin

        { Get current state of COM port and fill device control block }
        GetCommState( ComHandle, DCB ) ;
        { Change settings to those required for 1902 }
        DCB.BaudRate := CBR_9600 ;
        DCB.ByteSize := 8 ;
        DCB.Parity := NOPARITY ;
        DCB.StopBits := ONESTOPBIT ;

        { Update COM port }
        SetCommState( ComHandle, DCB ) ;

        { Initialise Com port and set size of transmit/receive buffers }
        SetupComm( ComHandle, 4096, 4096 ) ;

        { Set Com port timeouts }
        GetCommTimeouts( ComHandle, CommTimeouts ) ;
        CommTimeouts.ReadIntervalTimeout := $FFFFFFFF ;
        CommTimeouts.ReadTotalTimeoutMultiplier := 0 ;
        CommTimeouts.ReadTotalTimeoutConstant := 0 ;
        CommTimeouts.WriteTotalTimeoutMultiplier := 0 ;
        CommTimeouts.WriteTotalTimeoutConstant := 5000 ;
        SetCommTimeouts( ComHandle, CommTimeouts ) ;
        Result := True ;
        end
     Else Result := False ;
     end ;


procedure CloseCOMPort ;
//
// Close serial COM link to camera
// -------------------------------
begin
     //   If COM link is open, close it
     if ComHandle >= 0 then CloseHandle( ComHandle ) ;
     ComHandle := -1 ;
     end ;


procedure TransmitLine(
          const Line : string   { Text to be sent to Com port }
          ) ;
{ --------------------------------------
  Write a line of ASCII text to Com port
  --------------------------------------}
var
   i,nC : Integer ;
   nWritten : DWORD ;
   xBuf : array[0..258] of char ;
begin
     { Copy command line to be sent to xMit buffer and and a CR character }
     nC := Length(Line) ;
     for i := 1 to nC do xBuf[i-1] := Line[i] ;
     xBuf[nC] := chr(13) ;
     Inc(nC) ;

    WriteFile( ComHandle, xBuf, nC, nWritten, {OverlapWrite}Nil ) ;

    if nWRitten <> nC then
       MessageDlg( ' Error writing to COM port ', mtWarning, [mbOK], 0 ) ;
     end ;


function ReceiveLine : string ;          { Return line of bytes received }
{ -------------------------------------------------------
  Read bytes from Com port until a line has been received
  -------------------------------------------------------}
const
     TimeOut = 20000 ;
var
   Line : string ;
   rBuf : array[0..1] of char ;
   NumBytesRead,ComError : Cardinal ;
   ComState : TComStat ;
   PComState : PComStat ;
   TimeOutTickCount : LongInt ;
begin
     { Set time that ReceiveLine will give up at if a full line has not
       been received }
     TimeOutTickCount := GetTickCount + TimeOut ;

     PComState := @ComState ;
     Line := '' ;
     repeat
        rBuf[0] := ' ' ;
        { Find out if there are any characters in receive buffer }
        ClearCommError( ComHandle, ComError, PComState )  ;
        NumBytesRead := 0 ;
        if ComState.cbInQue > 0 then begin
           ReadFile( ComHandle,
                     rBuf,
                     1,
                     NumBytesRead,
                     Nil ) ;

           end ;
        if NumBytesRead > 0 then begin
           if (rBuf[0] <> chr(13)) and (rBuf[0]<>chr(10)) then
              Line := Line + rBuf[0] ;
           end ;
        until (rBuf[0] = chr(13)) or (GetTickCount >= TimeOutTickCount) ;
     Result := Line ;
     end ;




end.
