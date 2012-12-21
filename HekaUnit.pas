unit HekaUnit;
//
// HEKA patch clamps & Instrutech interfaces
// 08.09.10

interface

const

// defines for EPC9_SetMuxPath:
  EPC9_F2Ext = 0 ;
  EPC9_Imon1 = 1 ;
  EPC9_Vmon =  2 ;

// defines for EPC9_Get/SetExtStimPath:
  EPC9_ExtStimOff =      0 ;
  EPC9_ExtStimStimDac =  1 ;
  EPC9_ExtStimInput =    2 ;

// defines for EPC9_SetCCGain:
  EPC9_CC1pA = 0 ;
  EPC9_CC10pA =          1 ;
  EPC9_CC100pA =         2 ;

// defines for EPC9_CCTrackTaus:
  EPC9_TauOff =          0 ;
  EPC9_Tau1 =  1 ;
  EPC9_Tau3 =  2 ;
  EPC9_Tau10 = 3 ;
  EPC9_Tau30 = 4 ;
  EPC9_Tau100 =          4 ;

  EPC9_RsModeOff =        0 ;
  EPC9_RsMode100us =      1 ;
  EPC9_RsMode10us =      2 ;
  EPC9_RsMode2us =       3 ;

  EPC9_Success =         0 ;
  EPC9_NoScaleFiles =    22 ;
  EPC9_MaxFileLength =   10240 ;

  EPC9_Epc7Ampl =        0 ;
  EPC9_Epc8Ampl =        1 ;
  EPC9_Epc9Ampl =        2 ;
  EPC9_Epc10Ampl =        3 ;
  EPC9_Epc10PlusAmpl =   4 ;
  EPC9_Epc10USB =        5 ;

type

TEPC9_StateType = packed record
     StateVersion : Array[0..7] of char ;
     CalibDate : Array[0..15] of char ;
     RealCurrentGain : Double ;
     RealF2Bandwidth : Double ;
     F2Frequency : Double ;
     RsValue : Double ;
     RsFraction : Double ;
     GLeak : Double ;
     CFastAmp1 : Double ;
     CFastAmp2 : Double ;
     CFastTau : Double ;
     CSlow : Double ;
     GSeries : Double ;
     StimDacScale : Double ;
     CCStimScale : Double ;
     VHold : Double ;
     LastVHold : Double ;
     VpOffset : Double ;
     VLiquidJunction : Double ;
     CCIHold : Double ;
     CSlowStimVolts : Double ;
     CCTrackVHold : Double ;
     TimeoutLength : Double ;
     SearchDelay : Double ;
     MConductance : Double ;
     MCapacitance : Double ;
     RsTau : Double ;
     StimFilterHz : Double ;
     SerialNumber : Array[0..7] of char ;
     E9Boards : SmallInt ;
     CSlowCycles : SmallInt ;
     IMonAdc : SmallInt ;
     VMonAdc : SmallInt ;
     MuxAdc : SmallInt ;
     TstDac : SmallInt ;
     StimDac : SmallInt ;
     StimDacOffset : SmallInt ;
     MaxDigitalBit : SmallInt ;
     SpareInt1 : SmallInt ;
     SpareInt2 : SmallInt ;
     SpareInt3 : SmallInt ;
     AmplKind : Byte ;
     IsEpc9N : ByteBool ;
     ADBoard : Byte ;
     BoardVersion : char ;
     ActiveE9Board : Byte ;
     Mode : Byte ;
     Range : Byte ;
     F2Response : Byte ;
     RsOn : ByteBool ;
     CSlowRange : Byte ;
     CCRange : Byte ;
     CCGain : Byte ;
     CSlowToTstDac : ByteBool ;
     StimPath : Byte ;
     CCTrackTau : Byte ;
     WasClipping : ByteBool ;
     RepetitiveCSlow : ByteBool ;
     LastCSlowRange : Byte ;
     Locked : ByteBool ;
     CanCCFast : ByteBool ;
     CanLowCCRange : ByteBool ;
     CanHighCCRange : ByteBool ;
     CanCCTracking : ByteBool ;
     HasVmonPath : ByteBool ;
     HasNewCCMode : ByteBool ;
     Selector : char ;
     HoldInverted : ByteBool ;
     AutoCFast : Byte ;
     AutoCSlow : Byte ;
     HasVmonX100 : ByteBool ;
     TestDacOn : ByteBool ;
     QMuxAdcOn : ByteBool ;
     RealImon1Bandwidth : Double ;
     StimScale : Double ;
     Gain : Byte ;
     Filter1 : Byte ;
     StimFilterOn : ByteBool ;
     RsSlow : ByteBool ;
     StateInited : ByteBool ;
     CCCFastOn : ByteBool ;
     CCFastSpeed : ByteBool ;
     F2Source : Byte ;
     TestRange : Byte ;
     TestDacPath : Byte ;
     MuxChannel : Byte ;
     MuxGain64 : ByteBool ;
     VmonX100 : ByteBool ;
     IsQuadro : ByteBool ;
     F1Mode : Byte ;
     CSlowNoGLeak : ByteBool ;
     SelHold : Double ;
	   Spare : Array[0..63] of char ;
     end ;
implementation

end.
