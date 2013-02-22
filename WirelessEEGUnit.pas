unit WirelessEEGUnit;
//
// Wireless DBS/EEG transceiver
// ============================
// 24.06.2011 Still unreliable stimulator not working correctly.

interface

uses WinTypes,Dialogs, SysUtils, WinProcs,mmsystem,math;

  procedure WirelessEEG_InitialiseBoard ;

  function  WirelessEEG_ADCToMemory(
            var HostADCBuf : Array of SmallInt  ;
            nChannels : Integer ;
            nSamples : Integer ;
            var dt : Double ;
            ADCVoltageRange : Single ;
            TriggerMode : Integer ;
            CircularBuffer : Boolean
            ) : Boolean ;

  function WirelessEEG_StopADC : Boolean ;
  procedure WirelessEEG_GetADCSamples (
            var OutBuf : Array of SmallInt ;
            var OutBufPointer : Integer
            ) ;
  procedure WirelessEEG_CheckSamplingInterval(
            var SamplingInterval : Double
            ) ;

  function  WirelessEEG_GetLabInterfaceInfo(
            var Model : string ; { Laboratory interface model name/number }
            var ADCMinSamplingInterval : Double ; { Smallest sampling interval }
            var ADCMaxSamplingInterval : Double ; { Largest sampling interval }
            var ADCMinValue : Integer ; { Negative limit of binary ADC values }
            var ADCMaxValue : Integer ; { Positive limit of binary ADC values }
            var ADCVoltageRanges : Array of single ; { A/D voltage range option list }
            var NumADCVoltageRanges : Integer ; { No. of options in above list }
            var ADCBufferLimit : Integer ;      { Max. no. samples in A/D buffer }
            var DACMaxVolts : Single ; { Positive limit of bipolar D/A voltage range }
            var DACMinUpdateInterval : Double {Min. D/A update interval }
            ) : Boolean ;

  function WirelessEEG_GetMaxDACVolts : single ;

  function WirelessEEG_ReadADC( Channel : Integer ;
                        ADCVoltageRange : Single ) : SmallInt ;

  procedure WirelessEEG_GetChannelOffsets(
            var Offsets : Array of Integer ;
            NumChannels : Integer
            ) ;

  procedure WirelessEEG_SetPulseFrequency(
            var Frequency : Single ) ;
  function WirelessEEG_GetPulseFrequency : Single ;
  procedure WirelessEEG_SetPulseWidth(
            var Width : Single ) ;
  function WirelessEEG_GetPulseWidth : Single ;
  procedure WirelessEEG_SetStimulatorOn( StimOn : Boolean ) ;
  procedure WirelessEEG_CheckStimulatorOn( var StimOn : Boolean ) ;
  function  WirelessEEG_GetSleepMode : Boolean ;
  procedure WirelessEEG_SetSleepMode( SleepOn : Boolean  ) ;
  function  WirelessEEG_GetWirelessChannel : Integer ;
  function WirelessEEG_GetSamplingRate : Single ;
  function WirelessEEG_GetNumFramesLost : Integer ;
  procedure SendByteToDBS( iByte : Byte ) ;
  procedure Wait( idelay : Integer ) ;

  procedure WirelessEEG_CloseLaboratoryInterface ;


implementation

const

    DBSStimulusOn = $A ;
    DBSStimulusOff = $B ;
    DBSSleep = $C ;
    DBSWake = $D ;

     NumMultiplers = 4 ;
     MaxValue = 50 ;
     DBSSetFrequencyValue = $40 ;
     FrequencyMultiplier : Array[0..NumMultiplers-1] of Single = (0.1,1.0,10.0,100.0) ;
     FrequencyMultiplierCode : Array[0..NumMultiplers-1] of Integer = ($CB,$CA,$C9,$C8) ;
 //    FrequencyMultiplierCode : Array[0..NumMultiplers-1] of Integer = ($C8,$C9,$CA,$CB) ;

     DBSSetPulseWidthValue = $80 ;
     PulseWidthMultiplier : Array[0..NumMultiplers-1] of Single = (1E-5,1E-4,1E-3,1E-2) ;
     PulseWidthMultiplierCode : Array[0..NumMultiplers-1] of Integer = ($E4,$E5,$E6,$E7) ;

type
    TPacket = record
        ADCValue : Array[0..3] of Integer ;
        ByteIndex : Integer ;
        NumADCChannels : Integer ;
        PulseFrequency : Single ;
        PulseWidth : Single ;
        StimulusOn : Boolean ;
        NumBytesReceived : Integer ;
        EndOfFrame : Integer ;
        NumChannelSets : Integer ;
        TStart : Integer ;
        NumFramesLost : Integer ;
        end ;

var
   DeviceInitialised : Boolean ;
   ComHandle : Integer ;
   Packet : TPacket ;
   OverLapStructure : POverlapped ;

   FADCVoltageRanges : Array[0..15] of Single ; // A/D input voltage range options
   FNumADCVoltageRanges : Integer ;             // No. of available A/D voltage ranges
   //FADCVoltageRangeMax : Single ;               // Upper limit of A/D input voltage range
   FADCMinValue : Integer ;                     // Max. A/D integer value
   FADCMaxValue : Integer ;                     // Min. A/D integer value
   FADCMinSamplingInterval : Single ;           // Min. A/D sampling interval
   FADCMaxSamplingInterval : Single ;           // Max. A/D sampling interval
   FADCBufferLimit : Integer ;                  // Upper limit of A/D sample buffer
   CyclicADCBuffer : Boolean ;                  // Continuous cyclic A/D buffer mode flag
   FNumADCChannels : Integer ;                  // No. A/D channels/sweep
   OutPointer : Integer ;              // Pointer to last A/D sample transferred
                                       // (used by ITC_GetADCSamples)
   FDACVoltageRangeMax : Single ;  // Upper limit of D/A voltage range

   FDACMinUpdateInterval : Single ;

   ADCActive : Boolean ;           // A/D sampling in progress flag

   TestSignal : Integer ;

   WirelessChannel : Integer ;     // Wireless channel in use

function  WirelessEEG_GetLabInterfaceInfo(
          var Model : string ; { Laboratory interface model name/number }
          var ADCMinSamplingInterval : Double ; { Smallest sampling interval }
          var ADCMaxSamplingInterval : Double ; { Largest sampling interval }
          var ADCMinValue : Integer ; { Negative limit of binary ADC values }
          var ADCMaxValue : Integer ; { Positive limit of binary ADC values }
          var ADCVoltageRanges : Array of single ; { A/D voltage range option list }
          var NumADCVoltageRanges : Integer ; { No. of options in above list }
          var ADCBufferLimit : Integer ;      { Max. no. samples in A/D buffer }
          var DACMaxVolts : Single ; { Positive limit of bipolar D/A voltage range }
          var DACMinUpdateInterval : Double {Min. D/A update interval }
          ) : Boolean ;
{ --------------------------------------------
  Get information about the interface hardware
  -------------------------------------------- }
begin

     if not DeviceInitialised then WirelessEEG_InitialiseBoard ;

     if DeviceInitialised then begin

        { Get device model and serial number }
        Model := 'SIPBS: Wireless Transceiver' ;

        // Define available A/D voltage range options
        FNumADCVoltageRanges := 1 ;
        FADCVoltageRanges[0] := 0.6 ;
        ADCVoltageRanges[0] := FADCVoltageRanges[0] ;
        NumADCVoltageRanges := FNumADCVoltageRanges ;

        // A/D sample value range (16 bits)
        ADCMinValue := -32678 ;
        ADCMaxValue := -ADCMinValue - 1 ;
        FADCMinValue := ADCMinValue ;
        FADCMaxValue := ADCMaxValue ;

        // Upper limit of bipolar D/A voltage range
        DACMaxVolts := 10.25 ;
        FDACVoltageRangeMax := 10.25 ;
        DACMinUpdateInterval := 2.5E-6 ;
        FDACMinUpdateInterval := DACMinUpdateInterval ;

        // Min./max. A/D sampling intervals
        ADCMinSamplingInterval := 2E-3 ;
        ADCMaxSamplingInterval := 2E-3 ;
        FADCMinSamplingInterval := ADCMinSamplingInterval ;
        FADCMaxSamplingInterval := ADCMaxSamplingInterval ;

        FADCBufferLimit := 16128 ;
        ADCBufferLimit := FADCBufferLimit ;

        end ;

     Result := DeviceInitialised ;

     end ;


procedure WirelessEEG_InitialiseBoard ;
{ -------------------------------------------
  Initialise Wireless EEG interface hardware
  -------------------------------------------}
var

   DCB : TDCB ;           { Device control block for COM port }
   CommTimeouts : TCommTimeouts ;
begin

     DeviceInitialised := False ;

     { Open com port  }
     ComHandle :=  CreateFile( PCHar(format('COM%d',[1])),
                     GENERIC_READ or GENERIC_WRITE,
                     0,
                     Nil,
                     OPEN_EXISTING,
                     FILE_ATTRIBUTE_NORMAL,
                     0) ;

     if ComHandle < 0 then Exit ;

     { Get current state of COM port and fill device control block }
     GetCommState( ComHandle, DCB ) ;
     { Change settings to those required for 1902 }
     DCB.BaudRate := CBR_115200 ;
     DCB.ByteSize := 8 ;
     DCB.Parity := NOPARITY ;
     DCB.StopBits := ONESTOPBIT ;

     { Update COM port }
     SetCommState( ComHandle, DCB ) ;

     { Initialise Com port and set size of transmit/receive buffers }
     SetupComm( ComHandle, 4096000, 4096000 ) ;

     { Set Com port timeouts }
     GetCommTimeouts( ComHandle, CommTimeouts ) ;
     CommTimeouts.ReadIntervalTimeout := $FFFFFFFF ;
     CommTimeouts.ReadTotalTimeoutMultiplier := 0 ;
     CommTimeouts.ReadTotalTimeoutConstant := 0 ;
     CommTimeouts.WriteTotalTimeoutMultiplier := 0 ;
     CommTimeouts.WriteTotalTimeoutConstant := 5000 ;
     SetCommTimeouts( ComHandle, CommTimeouts ) ;

     Packet.NumADCChannels := 4 ;
     Packet.ByteIndex := 0 ;
     Packet.NumFramesLost := 0 ;

     DeviceInitialised := True ;
     ADCActive := false ;
     end ;

function  WirelessEEG_ADCToMemory(
            var HostADCBuf : Array of SmallInt  ;
            nChannels : Integer ;
            nSamples : Integer ;
            var dt : Double ;
            ADCVoltageRange : Single ;
            TriggerMode : Integer ;
            CircularBuffer : Boolean
            ) : Boolean ;
begin

    FNumADCChannels := nChannels ;

    // Upper limit of A/D storage buffer
    FADCBufferLimit := nChannels*nSamples - 1 ;

    // Fixed A/D sampling rate
    dt := FADCMinSamplingInterval ;

    // Circular buffer
    CyclicADCBuffer := CircularBuffer ;

    // Resest A/D buffer pointer
    OutPointer := 0 ;

    // Reset packet bit counter
    packet.PulseFrequency := 0.0 ;
    packet.PulseWidth := 0.0 ;
    packet.NumBytesReceived := 0 ;
    packet.EndofFrame := 0 ;
    Packet.NumChannelSets := 0 ;
    Packet.TStart := TimeGetTime ;
    Packet.ByteIndex := 0 ;
    Packet.NumFramesLost := 0 ;
    TestSignal := 32768 ;

    { Initialise Com port and set size of transmit/receive buffers }
     SetupComm( ComHandle, 4096000, 4096000 ) ;

    ADCActive := True ;
    Result := ADCActive ;
    end ;


function WirelessEEG_StopADC : Boolean ;
// --------------------------
// Stop acquiring A/D samples
// --------------------------
begin
    ADCActive := False ;
    Result := ADCActive ;
    end ;


procedure WirelessEEG_GetADCSamples (
            var OutBuf : Array of SmallInt ;
            var OutBufPointer : Integer
          ) ;
var
   ComState : TComStat ;
   PComState : PComStat ;
   ComError,NumBytesRead : DWORD ;
   rBuf : array[0..999999] of byte ;
   i,ch : Integer ;
   iByte : Byte ;
   s : string ;
   iMult : Integer ;
   SaveChannels : Boolean ;
begin

     if not ADCActive then Exit ;

     // Read characters in receive buffer
     PComState := @ComState ;
     ClearCommError( ComHandle, ComError, PComState )  ;
     NumBytesRead := 0 ;
     if ComState.cbInQue > 0 then begin
        ReadFile( ComHandle,
                  rBuf,
                  ComState.cbInQue,
                  NumBytesRead,
                  OverlapStructure ) ;
        end ;

     //s := 'RX: ' ;
     //for i := 0 to NumBytesRead-1 do s := s + format('%x ',[rBuf[i]]) ;
     //outputdebugstring(PChar(s)) ;
     s := '' ;
     if NumBytesRead > 0 then begin
        for i := 0 to NumBytesRead-1 do begin
            Inc(packet.NumBytesReceived) ;
            //if i < 16 then s := s + format('%x ',[rBuf[i]]);
            //if i = 16 then outputdebugstring(pchar(s));
            iByte := rBuf[i] ;
            SaveChannels := False ;
            case Packet.ByteIndex of

                // A/D Channel 0
                0 : begin
                  // MSB First byte in frame
                  if (iByte and $E0) = $80 then begin
                     packet.ADCValue[0] := (iByte and $1f) shl 11 ;
                     Inc(Packet.ByteIndex) ;
                     end
                  else begin
                     Packet.ByteIndex := 0 ;
                     Inc(Packet.NumFramesLost) ;
                     end ;

                  end ;

               1 : begin
                 // Middle byte
                 Packet.ADCValue[0] := packet.ADCValue[0] or (iByte shl 4) ;
                 Inc(Packet.ByteIndex) ;
                 end ;

               2 : begin
                 // LSB
                 Packet.ADCValue[0] := packet.ADCValue[0] or (iByte shr 3) ;
                 Inc(Packet.ByteIndex) ;
                 if (iByte and $1) <> 0 then Packet.StimulusOn := True
                                        else Packet.StimulusOn := False ;
                 WirelessChannel := (iByte and $2) shr 1 ;
                 if FNumADCChannels = 1 then SaveChannels := True ;
                 end ;

                // A/D Channel 1
                3 : begin
                    // MSB
                    if (iByte and $E0) = $A0 then begin
                       packet.ADCValue[1] := (iByte and $1f) shl 11 ;
                       Inc(Packet.ByteIndex) ;
                       end
                    else begin
                       Packet.ByteIndex := 0 ;
                       Inc(Packet.NumFramesLost) ;
                       end ;
                    end ;

               4 : begin
                   // Middle byte
                   Packet.ADCValue[1] := packet.ADCValue[1] or (iByte shl 4) ;
                   Inc(Packet.ByteIndex) ;
                   end ;

               5 : begin
                 // LSB
                 Packet.ADCValue[1] := packet.ADCValue[1] or (iByte shr 3) ;
                 Inc(Packet.ByteIndex) ;
                 if FNumADCChannels = 2 then SaveChannels := True ;
                 end ;

                // A/D Channel 2
               6 : begin
                 // MSB
                 if (iByte and $E0) = $C0 then begin
                    packet.ADCValue[2] := (iByte and $1f) shl 11 ;
                    Inc(Packet.ByteIndex) ;
                    end
                 else begin
                    Packet.ByteIndex := 0 ;
                    Inc(Packet.NumFramesLost) ;
                    end ;
                 end ;

               7 : begin
                 // Middle byte
                 Packet.ADCValue[2] := packet.ADCValue[2] or (iByte shl 4) ;
                 Inc(Packet.ByteIndex) ;
                 end ;

               8 : begin
                 // LSB
                 Packet.ADCValue[2] := packet.ADCValue[2] or (iByte shr 3) ;
                 if FNumADCChannels = 3 then SaveChannels := True ;
                 Inc(Packet.ByteIndex) ;
                 end ;

                // A/D Channel 3
               9 : begin
                 // MSB
                 if (iByte and $E0) = $E0 then begin
                    packet.ADCValue[3] := (iByte and $1f) shl 11 ;
                    Inc(Packet.ByteIndex) ;
                    end
                 else begin
                    Packet.ByteIndex := 0 ;
                    Inc(Packet.NumFramesLost) ;
                    end ;
                 end ;

               10 : begin
                 // Middle byte
                 Packet.ADCValue[3] := packet.ADCValue[3] or (iByte shl 4) ;
                 Inc(Packet.ByteIndex) ;
                 end ;

               11 : begin
                 // LSB
                 Packet.ADCValue[3] := packet.ADCValue[3] or (iByte shr 3) ;
                 if FNumADCChannels = 4 then SaveChannels := True ;
                 Inc(Packet.ByteIndex) ;
                 end ;

               12 : begin
                  // Stimulus pulse frequency
                  iMult := iByte shr 6 ;
                  packet.PulseFrequency := (iByte and $3F)*FrequencyMultiplier[iMult] ;
                  Inc(Packet.ByteIndex) ;
                  end ;

                13 : Begin
                   // Stimulus pulse width
                   iMult := iByte shr 6 ;
                   Packet.PulseWidth := (iByte and $3F)*PulseWidthMultiplier[iMult] ;
                   Packet.ByteIndex := 0 ;
                   end ;
               end ;

            // Write required number channels to output buffer
            if SaveChannels then begin
               for ch := 0 to FNumADCChannels-1 do begin
                   if OutPointer > FADCBufferLimit then break ;
                   if ch < Packet.NumADCChannels then begin
                      OutBuf[OutPointer] := packet.ADCValue[ch] - $8000 ;
                      end
                   else OutBuf[OutPointer] := 0 ;

                   Inc(OutPointer) ;
                   if CyclicADCBuffer and (OutPointer > FADCBufferLimit) then OutPointer := 0 ;
                   end ;
               Inc(Packet.NumChannelSets) ;
               end ;

            end ;
        end ;

    OutBufPointer := OutPointer ;

    end ;


procedure WirelessEEG_CheckSamplingInterval(
            var SamplingInterval : Double ) ;
begin

    SamplingInterval := FADCMinSamplingInterval ;
    end ;


function WirelessEEG_GetMaxDACVolts : single ;
begin
    Result := 1.0 ;
    end ;


function WirelessEEG_ReadADC( Channel : Integer ;
                        ADCVoltageRange : Single ) : SmallInt ;
begin
    Result := 0 ;
    end ;


procedure WirelessEEG_GetChannelOffsets(
            var Offsets : Array of Integer ;
            NumChannels : Integer
            ) ;
// -----------------------------------------
// Define A/D channel offset into A/D buffer
// -----------------------------------------
var
    ch : Integer ;
begin

    for ch := 0 to NumChannels-1 do begin
        Offsets[ch] := ch ;
        end ;
    end ;

procedure SendByteToDBS( iByte : Byte ) ;
// ----------------
// Send byte to DBS
// ----------------
var
   nWritten : DWORD ;
   Overlapped : Pointer ; //POverlapped ;
   OK : Boolean ;
begin

    Overlapped := Nil ;
    OK := WriteFile( ComHandle, iByte, 1, nWritten, Overlapped ) ;
    if (not OK) or (nWRitten <> 1) then
        ShowMessage( ' Error writing to COM port ' ) ;

    // Wait for 100ms because receiver cannot send more than 1 byte / 2ms
    Wait( 100 ) ;

    end ;

procedure Wait( idelay : Integer ) ;
// ------------------
// Wait for idelay ms
// ------------------
var
    T,TDone : Integer ;
begin
    TDone := TimeGetTime + iDelay ;
    repeat
        T := TimeGetTime ;
        Until T >= TDone ;
    end ;


procedure WirelessEEG_SetPulseFrequency(
          var Frequency : Single           // Pulse frequency (Hz)
          ) ;
// ----------------------------------
// Set DBS stimulator pulse frequency
// ----------------------------------
var
    iMult : Integer ;
    Value : Integer ;
    Done : Boolean ;
    DBSCommand : Byte ;
begin

    iMult := 0 ;
    Done := False ;
    repeat
        Value := Max(Round(Frequency/FrequencyMultiPlier[iMult]),1) ;
        if (Value <= MaxValue) or (iMult >= (NumMultiplers-1))then Done := True
        else Inc(iMult) ;
        until Done ;

    Value := Min(Value,MaxValue) ;

    // Set value
    DBSCommand := DBSSetFrequencyValue or (Value and $3F) ;
    SendByteToDBS( DBSCommand ) ;

    // Set multiplier
    DBSCommand := FrequencyMultiplierCode[iMult] ;
    SendByteToDBS( DBSCommand ) ;

    Frequency := FrequencyMultiplier[iMult]*Value ;

    end ;


function WirelessEEG_GetPulseFrequency : Single ;
// ------------------------------------
// Get current stimulus pulse frequency
// ------------------------------------
begin
    Result := packet.PulseFrequency ;
    end ;


procedure WirelessEEG_SetPulseWidth(
          var Width : Single           // Pulse width (secs)
          ) ;
// ------------------------------
// Set DBS stimulator pulse width
// ------------------------------
var
    iMult : Integer ;
    Value : Integer ;
    Done : Boolean ;
    DBSCommand : Byte ;
begin

    iMult := 0 ;
    Done := False ;
    repeat
        Value := Max(Round(Width/PulseWidthMultiPlier[iMult]),1) ;
        if (Value <= MaxValue) or (iMult >= (NumMultiplers-1))then Done := True
        else Inc(iMult) ;
        until Done ;
    Value := Min(Value,MaxValue) ;

    // Set value
    DBSCommand := DBSSetPulseWidthValue or (Value and $3F) ;
    SendByteToDBS( DBSCommand ) ;

    // Set multiplier
    DBSCommand := PulseWidthMultiplierCode[iMult] ;
    SendByteToDBS( DBSCommand ) ;

    Width := PulseWidthMultiplier[iMult]*Value ;

    end ;

procedure WirelessEEG_CheckStimulatorOn( var StimOn : Boolean ) ;
// --------------------------------
// Return StimOn=TRUE if DBS stimulator On
// --------------------------------
begin
    if ADCActive then StimOn  := packet.StimulusOn ;
    end ;


function WirelessEEG_GetPulseWidth : Single ;
// ------------------------------------
// Get current stimulus pulse frequency
// ------------------------------------
begin
    Result := packet.PulseWidth ;
    end ;


procedure WirelessEEG_SetStimulatorOn( StimOn : Boolean ) ;
// -------------------------
// Start/stop DBS stimulator
// -------------------------
const
     DBSStimulusOn = $A ;
     DBSStimulusOff = $B ;
var
    DBSCommand : Byte ;
begin

    if StimOn then DBSCommand := DBSStimulusOn
              else DBSCommand := DBSStimulusOff ;
    SendByteToDBS( DBSCommand ) ;
    end ;


procedure WirelessEEG_SetSleepMode( SleepOn : Boolean ) ;
// -----------------------------------------------
// Set Wireless EEG/DBS into low power sleep mode
// -----------------------------------------------
const
    DBSSleep = $C ;
    DBSWake = $D ;
var
    DBSCommand : Byte ;
begin
    if SleepOn then DBSCommand := DBSSleep
               else DBSCommand := DBSWake ;
    SendByteToDBS( DBSCommand ) ;
    end ;


function  WirelessEEG_GetSleepMode : Boolean ;
// --------------------------------
// Return TRUE if sleep mode is on
// --------------------------------
begin
    Result := False ;
    end ;


function  WirelessEEG_GetWirelessChannel : Integer ;
// --------------------------------
// Return wireless channel number
// --------------------------------
begin
    Result := WirelessChannel ;
    end ;

function WirelessEEG_GetSamplingRate : Single ;
// --------------------------------
// Return dynamic sampling rate
// --------------------------------
var
  T : Single ;
begin
    Result := 0.0 ;
    if ADCActive then begin
       T := (TimeGetTime - Packet.TStart)*1E-3 ;
       if T > 0 then Result := packet.NumChannelSets/T ;
       end ;
    end ;


function WirelessEEG_GetNumFramesLost : Integer ;
// --------------------------------
// Return number of packet errors
// --------------------------------
begin
    Result := Packet.NumFramesLost ;
    end ;


procedure WirelessEEG_CloseLaboratoryInterface ;
// -------------------
// Shut down interface
// -------------------
begin

     // Close serial port
     if ComHandle >= 0 then CloseHandle( ComHandle ) ;
     ComHandle := -1 ;

    end ;

end.
