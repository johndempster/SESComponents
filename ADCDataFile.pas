unit ADCDataFile;
// -------------------------------------------------
// Analogue data file handling component
// (c) J. Dempster, University of Strathclyde, 2003
// -------------------------------------------------
// 14.9.03
// 19.11.03 Importing of SCAN and SPAN data files added
// 2.12.03  Export to ABF and ASCII added
// 18.12.03 FNumScansPerRecord now updated by SaveADCBuffer
// 1.01.04  Valid RecordNum now ensured in Save/LoadADCBuffer
// 17.03.04 Import of ABF files improved (scaling of floating point data now correct)
// 19.03.04 ASCII and binary file import updated
// 20.03.04 ABFOperationMode added
// 07.04.04 Errors in raw binary import fixed
// 11.04.05 2X error in .ADCScale fixed
// 16.07.05 ASCIITimeScale changed to ASCIITimeUnits
//          Strathclyde Chart (*.CHT) files now supported
// 17.07.05 WAV files can now be imported
// 14.12.05 Bugs in IBW file import fixed
// 21.09.06 Export to WCP files now works correctly
// 23.10.06 Missing ABF V1.5 header parameters added and set to zero
//          to avoid errors when using low-pass filtering in CLAMPFIT V9
// 14.12.06 Export to IGOR IBW (V5) files now works
// 01.02.07 Differences in channel scaling in WCP record header
//          now stored in .ChannelGain. Imported WCP now scaled correctly
//          Zero samples/channel in a CFS file no longer prevents file being imported
// 04.06.07 Import of HEKA format ASCII data files now possible
// 28.04.08 ABF V1.8 files can now be imported with correct scaling factors
//          ABF files saved as V1.5
// 09.07.08 Bug in CFS file import fixed. Files no longer imported with data blocks repeated
// 20.08.08 .SaveADCBuffer Buffer overflow when saving large records fixed
// 18.09.08 .SaveADCBuffer memory leak fixed
// 15.12.08 ASCIIFixedRecordSize property added, which forces fixed record size even if there is a time column.
//          ASCIITimeDataInCol0 Property now reports setting correctly
//          .NumScansPerRecord property no longer forced to multiple of 256 when set.
// 03.09.09 4 byte integer, 4 byte and 8 byte floating point CFS data files can now be read
//          CFS files can now be created
// 14.06.10 WCP file format updated to V9. Now supports up to 128 channels
// 04.02.11 FChannelGain now correctly included in WCP ADCVoltageRange
// 04.07.11 Error in amplitude scaling of V1.8+ ABF files with telegraphs
//          turned off fixed. (Bug reported by Trevor Smart in WinEDR files)
// 22.07.11 Max. number of channel increased to 128
// 14.08.12 PhysioNet file import now works correctly (supports 16 bit sample size as well as 12 bit)
// 11.03.13 FP error on import of CHT files now fixed. FChannelADCVoltageRange[] now read from YCch#= header variable

{$R 'adcdatafile.dcr'}
interface

uses
  SysUtils, Classes, maths, windows, math  ;

const
  ChannelLimit = 127 ;
  //WCPChannelLimit = 7 ;
  WCPMaxChannels = 128 ;
  WCPMaxAnalysisBytesPerRecord = 10240 ;
  WCPMaxBytesInFileHeader = 10240 ;
  WCPMaxAnalysisVariables = 28 ;
  WCPLastMeasureVariable = 14;
  WCPMaxRecordIdentChars = 16 ;
  WCPMaxRecordTypeChars = 4 ;
  WCPMaxRecordStatusChars = 8 ;


       WCPvRecord = 0 ;
     WCPvGroup = 1 ;
     WCPvTime = 2 ;
     WCPvAWCPverage = 3 ;
     WCPvArea = 4 ;
     WCPvPeak = 5 ;
     WCPvWCPvariance = 6 ;
     WCPvRiseTime = 7 ;
     WCPvRateofRise = 8 ;
     WCPvLatency = 9 ;
     WCPvTDecay = 10 ;
     WCPvT90 = 11 ;
     WCPvInterWCPval = 12 ;
     WCPvBaseline = 13 ;
     WCPvConductance = 14 ;

     // Curve fitting variable
     WCPvFitEquation = WCPLastMeasureVariable+1 ;
     WCPvFitChan = WCPLastMeasureVariable+2 ;
     WCPvFitCursor0 =  WCPLastMeasureVariable+3 ;
     WCPvFitCursor1 = WCPLastMeasureVariable+4 ;
     WCPvFitCursor2 = WCPLastMeasureVariable+5 ;
     WCPvFitResSD = WCPLastMeasureVariable+6 ;
     WCPvFitNumIterations = WCPLastMeasureVariable+7 ;
     WCPvFitDegF = WCPLastMeasureVariable+8 ;
     WCPvFitAvg = WCPLastMeasureVariable+9 ;
     WCPvFitPar = WCPLastMeasureVariable+10 ;
     WCPvFitParSD = WCPLastMeasureVariable+11 ;

  EDRFileHeaderSize = 2048 ;
  CHTFileHeaderSize = 8192 ;
  ABFFileHeaderSize_V15 = 2048 ;

type
  TByteDynArray         = array of Byte ;
  TSmallIntArray = Array[0..10000000] of SmallInt ;
  PSmallIntArray = ^TSmallIntArray ;
  // Types of image file supported
  TADCDataFileType = ( ftUnknown,
                ftWCP,
                ftEDR,
                ftCFS,
                ftAxonABF,
                ftAxonPClampV5,
                ftSCD,
                ftWCD,
                ftCDR,
                ftSPA,
                ftSCA,
                ftASC,
                ftWFDB,
                ftRaw,
                ftIBW,
                ftPNM,
                ftCHT,
                ftWAV,
                ftHEK ) ;

  TpClampV5 = packed record { Note. FETCHEX format header block }
	    par : Array[0..79] of single ;
	    Comment : Array[1..77] of char ;
      Labels : Array[1..80] of char ;
      Reserved : Array[1..3] of char ;
      ChannelNames : Array[0..15,1..10] of char ;
	    ADCOffset : Array[0..15] of single ;
	    ADCGain : Array[0..15] of single ;
      ADCAmplification : Array[0..15] of single ;
	    ADCShift : Array[0..15] of single ;
	    Units : Array[0..15,1..8] of char ;
      end ;

  TABF = packed record
      { Group #1 }
      FileType : Array[1..4] of char ;
      FileVersionNumber : single ;
	    OperationMode : SmallInt ;
      ActualAcqLength : LongInt ;
	    NumPointsIgnored : SmallInt ;
	    ActualEpisodes : LongInt ;
	    FileStartDate : LongInt ;
	    FileStartTime : LongInt ;
	    StopwatchTime : LongInt ;
	    HeaderVersionNumber : single ;
	    nFileType : SmallInt ;
	    MSBinFormat : SmallInt ;
      { Group #2 }
	    DataSectionPtr : LongInt ;
	    TagSectionPtr : LongInt ;
	    NumTagEntries : LongInt ;
	    ScopeConfigPtr : LongInt ;
	    NumScopes : LongInt ;
	    DACFilePtr : LongInt ;
	    DACFileNumEpisodes : LongInt ;
	    Unused68 : Array[1..4] of char ;
	    DeltaArrayPtr : LongInt ;
	    NumDeltas : LongInt ;
	    VoiceTagPtr : LongInt ;
	    VoiceTagEntries : LongInt ;
      Unused88 : LongInt ;
	    SynchArrayPtr : LongInt ;
	    SynchArraySize : LongInt ;
      DataFormat : SmallInt ;
      SimultaneousScan : SmallInt ;
      StatisticsConfigPtr : LongInt ;
      AnnotationSectionPtr : LongInt ;
      NumAnnotations : LongInt ;
	    Unused108 : Array[1..2] of char ;
      ChannelCountAcquired : SmallInt ;

      { Group #3 }
	    ADCNumChannels : SmallInt ;
	    ADCSampleInterval : single ;
	    ADCSecondSampleInterval : single ;
	    SynchTimeUnit : single ;
	    SecondsPerRun : single ;
	    NumSamplesPerEpisode : LongInt ;
	    PreTriggerSamples : LongInt ;
	    EpisodesPerRun : LongInt ;
	    RunsPerTrial : LongInt ;
	    NumberOfTrials : LongInt ;
	    AveragingMode  : SmallInt ;
	    UndoRunCount : SmallInt ;
	    FirstEpisodeInRun : SmallInt ;
	    TriggerThreshold : single ;
	    TriggerSource : SmallInt ;
	    TriggerAction : SmallInt ;
	    TriggerPolarity : SmallInt ;
	    ScopeOutputInterval : single ;
	    EpisodeStartToStart : single ;
	    RunStartToStart : single ;
	    TrialStartToStart : single ;
	    AverageCount : LongInt ;
      ClockChange : LongInt ;
      AutoTriggerStrategy : SmallInt ;

      { Group #4 }
	    DrawingStrategy : SmallInt ;
	    TiledDisplay : SmallInt ;
	    nEraseStrategy : SmallInt ;
	    DataDisplayMode : SmallInt ;
	    DisplayAverageUpdate : LongInt ;
	    ChannelStatsStrategy : SmallInt ;
	    CalculationPeriod : LongInt ;
	    SamplesPerTrace : LongInt ;
	    StartDisplayNum : LongInt ;
	    FinishDisplayNum : LongInt ;
	    MultiColor : SmallInt ;
	    ShowPNRawData : SmallInt ;
      StatisticsPeriod : single ;
      StatisticsMeasurements : LongInt ;
      StatisticsSaveStrategy : SmallInt ;
      
      { Group #5}
	    ADCRange : single ;
	    DACRange : single ;
	    ADCResolution : LongInt ;
	    DACResolution : LongInt ;
      { Group #6 }
	    ExperimentType : SmallInt ;
	    AutosampleEnable : SmallInt ;
	    AutosampleADCNum : SmallInt ;
	    AutosampleInstrument : SmallInt ;
	    AutosampleAdditGain : single ;
	    AutosampleFilter : single ;
	    AutosampleMembraneCap : single ;
	    ManualInfoStrategy : SmallInt ;
	    CellID1 : single ;
	    CellID2 : single ;
	    CellID3 : single ;
	    CreatorInfo : Array[1..16] of char ;
	    FileComment : Array[1..56] of char ;
      FileStartMillisecs : SmallInt ;
      CommentEnabled : SmallInt ;
	    Unused338 : Array[1..8] of char ;

      { Group #7 }
	    ADCPtoLChannelMap : Array[0..15] of SmallInt ;
	    ADCSamplingSeq : Array[0..15] of SmallInt ;
	    ADCChannelName : Array[0..15,1..10] of char ;
	    ADCUnits: Array[0..15,1..8] of char ;
	    ProgrammableGain : Array[0..15] of  single ;
	    DisplayAmplification : Array[0..15] of  single ;
	    DisplayOffset : Array[0..15] of  single ;
	    InstrumentScaleFactor : Array[0..15] of  single ;
	    InstrumentOffset : Array[0..15] of  single ;
	    SignalGain : Array[0..15] of  single ;
	    SignalOffset : Array[0..15] of  single ;
	    SignalLowPassFilter : Array[0..15] of  single ;
	    SignalHighPassFilter : Array[0..15] of  single ;

      DACChannelName : Array[0..3,1..10] of char ;
      DACChannelUnits : Array[0..3,1..8] of char ;
      DACScaleFactor : Array[0..3] of single ;
      DACHoldingLevel : Array[0..3] of single ;
      SignalType : SmallInt ;
      Unused1412 : Array[1..10] of char ;
      
      { Group #8 }
      OutEnable : SmallInt ;
      SampleNumberOUT1 : SmallInt ;
      SampleNumberOUT2 : SmallInt ;
      FirstEpisodeOUT : SmallInt ;
      LastEpisodeOut : SmallInt ;
      PulseSamplesOUT1 : SmallInt ;
      PulseSamplesOUT2 : SmallInt ;
      { group #9 }
      DigitalEnable : SmallInt ;
      WaveformSource : SmallInt ;
      ActiveDACChannel : SmallInt ;
      InterEpisodeLevel : SmallInt ;
      EpochType : Array[0..9] of SmallInt ;
      EpochInitLevel : Array[0..9] of single ;
      EpochLevelInc : Array[0..9] of single ;
      EpochInitDuration : Array[0..9] of SmallInt ;
      EpochDurationInc : Array[0..9] of SmallInt ;
      DigitalHolding : SmallInt ;
      DigitalInterEpisode : SmallInt ;
      DigitalValue : Array[0..9] of SmallInt ;
      Unavailable : Array[1..4] of char ;
      DigitalDACChannel : SmallInt ;
      Unused1612 : Array[1..6] of char ;

      { Group 10 }
      DACFileStatus : single ;
      DACFileOffset : single ;
      Unused1628 : Array[1..2] of char ;
      DACFileEpisodeNum : SmallInt ;
      DACFileADCNum : SmallInt ;
      DACFilePath : Array[1..84] of char ;
      { Group 11 }
      ConditEnable : SmallInt ;
      ConditChannel : SmallInt ;
      ConditNumPulses : LongInt ;
      BaselineDuration : single ;
      BaselineLevel : single ;
      StepDuration : single ;
      StepLevel : single ;
      PostTrainPeriod : single ;
      PostTrainLevel : single ;
      Unused1750 : array[1..12] of char ;

      { Group 12 }
      ParamToVary : SmallInt ;
      ParamValueList : Array[1..80] of char ;
      { Group 13 }
      AutoPeakEnable : SmallInt ;
      AutoPeakPolarity : SmallInt ;
      AutoPeakADCNum : SmallInt ;
      AutoPeakSearchMode : SmallInt ;
      AutoPeakStart : LongInt ;
      AutoPeakEnd : LongInt ;
      AutoPeakSmoothing : SmallInt ;
      AutoPeakBaseline : SmallInt ;
      AutoPeakAverage : SmallInt ;
      Unavailable1866 : array[1..2] of char ;
      AutopeakBaselineStart : LongInt ;
      AutopeakBaselineEnd : LongInt ;
      AutopeakMeasurements : LongInt ;
      { Group #14 }
      ArithmeticEnable : SmallInt ;
      ArithmeticUpperLimit : single ;
      ArithmeticLowerLimit : single ;
      ArithmeticADCNumA : SmallInt ;
      ArithmeticADCNumB : SmallInt ;
      ArithmeticK1 : single ;
      ArithmeticK2  : single ;
      ArithmeticK3 : single ;
      ArithmeticK4 : single ;
      ArithmeticOperator : Array[1..2] of char ;
      ArithmeticUnits : Array[1..8] of char ;
      ArithmeticK5 : single ;
      ArithmeticK6 : single ;
      ArithmeticExpression : SmallInt ;
      Unused1930 : array[1..2] of char ;

      { Group #15 }
      PNEnable : SmallInt ;
      PNPosition : SmallInt ;
      PNPolarity : SmallInt ;
      PNNumPulses : SmallInt ;
      PNADCNum : SmallInt ;
      PNHoldingLevel : single ;
      PNSettlingTime : single ;
      PNInterPulse : single ;
      Unused1954 : array[1..12] of char ;

      { Group #16 }
      ListEnable : SmallInt ;
      BellEnable : Array[0..1] of SmallInt ;
      BellLocation : Array[0..1] of SmallInt ;
      BellRepetitions : Array[0..1] of SmallInt ;
      LevelHysteresis : SmallInt ;
      TimeHysteresis : LongInt ;
      AllowExternalTags : SmallInt ;
      LowpassFilterType : Array[0..15] of char ;
      HighpassFilterType : Array[0..15] of char ;
      AverageAlgorithm : SmallInt ;
      AverageWeighting : single ;
      UndoPromptStrategy : SmallInt ;
      TrialTriggerSource : SmallInt ;
      StatisticsDisplayStrategy : SmallInt ;
      ExternalTagType : SmallInt ;
      //
      HeaderSize : Integer ;
      FileDuration : Double ;
      StatisticsClearStrategy : SmallInt ; // = 2048 byte V1.5

   // Extra parameters in v1.6
   // EXTENDED GROUP #2 - File Structure (26 bytes)
   lDACFilePtr : Array[0..1] of Integer ;
   lDACFileNumEpisodes : Array[0..1] of Integer ;

   // EXTENDED GROUP #3 - Trial Hierarchy
   fFirstRunDelay : single ;
   sUnused010 : Array[1..6] of char ;

   // EXTENDED GROUP #7 - Multi-channel information (62 bytes)
   fDACCalibrationFactor : Array[0..3] of single ;
   fDACCalibrationOffset : Array[0..3] of single ;
   sUnused011 : Array[1..30] of char ;

   // GROUP #17 - Trains parameters (160 bytes)
   lEpochPulsePeriod : Array[0..1,0..9] of Integer ;
   lEpochPulseWidth : Array[0..1,0..9] of Integer ;

   // EXTENDED GROUP #9 - Epoch Waveform and Pulses ( 412 bytes)
   nWaveformEnable : Array[0..1] of smallint ;
   nWaveformSource : Array[0..1] of smallint ;
   nInterEpisodeLevel : Array[0..1] of smallint ;
   nEpochType : Array[0..1,0..9] of smallint ;
   fEpochInitLevel : Array[0..1,0..9] of single ;
   fEpochLevelInc : Array[0..1,0..9] of single ;
   lEpochInitDuration : Array[0..1,0..9] of integer ;
   lEpochDurationInc : Array[0..1,0..9] of integer ;
   nDigitalTrainValue : Array[0..9] of smallint ;                         // 2 * 10 = 20 bytes
   nDigitalTrainActiveLogic : smallint ;                                   // 2 bytes
   sUnused012: Array[1..18] of char ;

   // EXTENDED GROUP #10 - DAC Output File (552 bytes)
   fDACFileScale : Array[0..1] of single ;
   fDACFileOffset : Array[0..1] of single ;
   lDACFileEpisodeNum : Array[0..1] of integer ;
   nDACFileADCNum : Array[0..1] of smallint ;
   sDACFilePath : Array[0..1,0..255] of char ;
   sUnused013 : Array[1..12] of char ;

   // EXTENDED GROUP #11 - Presweep (conditioning) pulse train (100 bytes)
   nConditEnable : Array[0..1] of smallint ;
   lConditNumPulses : Array[0..1] of integer ;
   fBaselineDuration : Array[0..1] of single ;
   fBaselineLevel : Array[0..1] of single ;
   fStepDuration : Array[0..1] of single ;
   fStepLevel : Array[0..1] of single ;
   fPostTrainPeriod : Array[0..1] of single ;
   fPostTrainLevel : Array[0..1] of single ;
   sUnused014 : Array[1..40] of char ;

   // EXTENDED GROUP #12 - Variable parameter user list (1096 bytes)
   nULEnable : Array[0..3] of smallint ;
   nULParamToVary : Array[0..3] of smallint ;
   sULParamValueList : Array[0..3,0..255] of char ;
   nULRepeat : Array[0..3] of smallint ;
   sUnused015 : Array[1..48] of char ;

   // EXTENDED GROUP #15 - On-line subtraction (56 bytes)
   nPNEnable : Array[0..1] of smallint ;
   nPNPolarity : Array[0..1] of smallint ;
   __nPNADCNum : Array[0..1] of smallint ;
   fPNHoldingLevel : Array[0..1] of single ;
   nPNNumADCChannels : Array[0..1] of smallint ;
   nPNADCSamplingSeq : Array[0..1,0..15] of char ;

   // EXTENDED GROUP #6 Environmental Information  (898 bytes)
   nTelegraphEnable : Array[0..15] of smallint ;
   nTelegraphInstrument : Array[0..15] of smallint ;
   fTelegraphAdditGain : Array[0..15] of single ;
   fTelegraphFilter : Array[0..15] of single ;
   fTelegraphMembraneCap : Array[0..15] of single ;
   nTelegraphMode : Array[0..15] of smallint ;
   nTelegraphDACScaleFactorEnable : Array[0..3] of smallint ;
   sUnused016a : Array[1..24] of char ;

   nAutoAnalyseEnable : SmallInt ;
   sAutoAnalysisMacroName : Array[0..63] of char ;
   sProtocolPath : Array[0..255] of char ;

   sFileComment : Array[0..127] of char;
   GUID : Array[0..15] of char ;
   fInstrumentHoldingLevel : Array[0..3] of single ;
   ulFileCRC : Integer ;
   sModifierInfo : Array[0..15] of char ;
   sUnused017 : Array[1..76] of char ;

   // EXTENDED GROUP #13 - Statistics measurements (388 bytes)
   nStatsEnable : SmallInt ;
   nStatsActiveChannels : SmallInt ;             // Active stats channel bit flag
   nStatsSearchRegionFlags : SmallInt ;          // Active stats region bit flag
   nStatsSelectedRegion : SmallInt ;
   _nStatsSearchMode : SmallInt ;
   nStatsSmoothing : SmallInt ;
   nStatsSmoothingEnable : SmallInt ;
   nStatsBaseline : SmallInt ;
   lStatsBaselineStart : Integer ;
   lStatsBaselineEnd : Integer ;
   lStatsMeasurements : Array[0..7] of Integer ;  // Measurement bit flag for each region
   lStatsStart : Array[0..7] of Integer ;
   lStatsEnd : Array[0..7] of Integer ;
   nRiseBottomPercentile : Array[0..7] of smallint ;
   nRiseTopPercentile : Array[0..7] of smallint ;
   nDecayBottomPercentile : Array[0..7] of smallint ;
   nDecayTopPercentile : Array[0..7] of smallint ;
   nStatsChannelPolarity : Array[0..15] of smallint ;
   nStatsSearchMode : Array[0..7] of smallint ;    // Stats mode per region: mode is cursor region, epoch etc
   sUnused018 : Array[1..156] of char ;

   // GROUP #18 - Application version data (16 bytes)
       nCreatorMajorVersion : smallint;
       nCreatorMinorVersion : smallint;
       nCreatorBugfixVersion : smallint;
       nCreatorBuildVersion : smallint;
       nModifierMajorVersion : smallint;
       nModifierMinorVersion : smallint;
       nModifierBugfixVersion : smallint;
       nModifierBuildVersion : smallint;

   // GROUP #19 - LTP protocol (14 bytes)
       nLTPType : smallint;
   nLTPUsageOfDAC : Array[0..1] of smallint ;
   nLTPPresynapticPulses : Array[0..1] of smallint ;
   sUnused020 : Array[1..4] of char ;

   // GROUP #20 - Digidata 132x Trigger out flag. (8 bytes)
   nDD132xTriggerOut : smallint ;
   sUnused021 : array[1..6] of char ;

   // GROUP #21 - Epoch resistance (40 bytes)
   sEpochResistanceSignalName : Array[0..1,0..9] of char;
   nEpochResistanceState : array[0..1] of smallint ;
   sUnused022 : array[1..16] of char ;

   // GROUP #22 - Alternating episodic mode (58 bytes)
   nAlternateDACOutputState : smallint ;
   nAlternateDigitalValue : Array[0..9] of smallint ;
   nAlternateDigitalTrainValue : Array[0..9] of smallint ;
   nAlternateDigitalOutputState : smallint ;
   sUnused023 : array[1..14] of char ;

   // GROUP #23 - Post-processing actions (210 bytes)
   fPostProcessLowpassFilter : Array[0..15] of single ;
   nPostProcessLowpassFilterType : Array[0..15] of char ;

   // 6014 header bytes allocated + 130 header bytes not allocated
   sUnused2048 : array[1..130] of char ;

   end ;

// WCP V9.0 file structure

{ Data file header block }
TWCPFileHeader = packed record
            FileName : string ;
            FileHandle : integer ;
            NumSamples : LongInt ;
            NumChannels : LongInt ;
            NumSamplesPerRecord : LongInt ;
            NumBytesPerRecord : LongInt ;
            NumDataBytesPerRecord : LongInt ;
            NumAnalysisBytesPerRecord : LongInt ;
            NumBytesInHeader : LongInt ;
            NumRecords : LongInt ;
            MaxADCValue : Integer ;
            MinADCValue : Integer ;
            RecordNum : LongInt ;
            dt : single ;
            ADCVoltageRange : single ;
            ADCMaxBits : single ;
            NumZeroAvg : LongInt ;
            IdentLine : string ;
            Version : Single ;
            CurrentRecord : LongInt ;
            DecayTimePercentage : Single ;          // Selected T(x%) decay percentage value
            // Non-stationary variance analysis parameters
            NSVChannel : Integer ;          // Current channel to be analysed
            NSVType : Integer ;             // Type of record to analyse
            NSVAlignmentMode : Integer ;   // Alignment mode for averaging
            NSVScaleToPeak : Boolean ;     // Scale to peak selected
            NSVAnalysisCursor0 : Integer ; // Variance-mean plot selection cursor 0
            NSVAnalysisCursor1 : Integer ; // Variance-mean plot selection cursor 1
            SaveHeader : Boolean ;
            CreationTime : String ;
            end ;

{ WCP file data record header block }
TWCPRecordHeader = packed record
           Status : string[8] ;
           RecType : string[4] ;
           Number : Single ;
           Time : Single ;
           dt : Single ;
           ADCVoltageRange : array[0..WCPMaxChannels-1] of Single ;
           Ident : string ;
           Value : array[0..WCPMaxChannels*WCPMaxAnalysisVariables-1] of single ;
           EqnType : TEqnType ;
           FitCursor0 : Integer ;
           FitCursor1 : Integer ;
           FitCursor2 : Integer ;
           FitChan : Integer ;
           AnalysisAvailable : boolean ;
           end ;


  TABFAcquisitionMode = (ftGapFree, ftEpisodic ) ;


TLDTFileHeader = packed record
           Leader : Cardinal ;
           SamplingInterval : Word ;
           Scaling : Word ;
           end ;

TLDTSegmentHeader = packed record
           Start : Cardinal ;
           NumSamples : Cardinal ;
           end ;

    TCFSChannelDef = packed record
        ChanName : String[21] ;
        UnitsY : String[9] ;
        UnitsX : String[9] ;
        dType : Byte ;
        dKind : Byte ;
        dSpacing : Word ;
        OtherChan : Word ;
        end ;

    TCFSChannelInfo = packed record
	        DataOffset : LongInt ; {offset to first point}
	        DataPoints : LongInt ; {number of points in channel}
	        scaleY : single ;
	        offsetY : single ;
	        scaleX : single ;
	        offsetX : single ;
          end ;

    TCFSDataHeader = packed record
	     lastDS : LongInt ;
	     dataSt : LongInt ;
	     dataSz : LongInt ;
	     Flags : Word ;
       Space : Array[1..8] of Word ;
       end ;

    TCFSFileHeader = packed record
	      Marker : Array[1..8] of char ;
	      Name : Array[1..14] of char ;
	      FileSz : LongInt ;
        TimeStr : Array[1..8] of char ;
	      DateStr : Array[1..8] of char ;
	      DataChans : SmallInt ;
	      FilVars : SmallInt ;
	      DatVars : SmallInt ;
	      fileHeadSz : SmallInt ;
	      DataHeadSz : SmallInt ;
	      EndPnt : LongInt ;
	      DataSecs : SmallInt ;
	      DiskBlkSize : SmallInt ;
	      CommentStr : Array[1..74] of char ;
	      TablePos : LongInt ;
	      Fspace : Array[1..20] of Word ;
        end ;

// IGOR file header structures
const
    MAXDIMS = 4 ;
    MAX_WAVE_NAME2 = 18 ;
    MAX_WAVE_NAME5 = 31 ;
    MAX_UNIT_CHARS = 3 ;
    NT_CMPLX = 1 ;			// Complex numbers.
    NT_FP32 = 2	;		// 32 bit fp numbers.
    NT_FP64 = 4	;		// 64 bit fp numbers.
    NT_I8 = 8	;			// 8 bit signed integer. Requires Igor Pro 2.0 or later.
    NT_I16 = 16	;	// 16 bit integer numbers. Requires Igor Pro 2.0 or later.
    NT_I32 =	32 ;		// 32 bit integer numbers. Requires Igor Pro 2.0 or later.
    NT_UNSIGNED = 64 ;	// Makes above signed integers unsigned. Requires Igor Pro 3.0 or later.

type

TIGORBinHeader1 = packed Record
	  Version : SmallInt ;						// Version number for backwards compatibility.
	  WfmSize : LongInt;						// The size of the WaveHeader2 data structure plus the wave data plus 16 bytes of padding.
	  Checksum : SmallInt ;					// Checksum over this header and the wave header.
    end ;

TIGORBinHeader2 = packed Record
	  Version :SmallInt ;						// Version number for backwards compatibility.
	  WfmSize : LongInt;						// The size of the WaveHeader2 data structure plus the wave data plus 16 bytes of padding.
	  NoteSize : LongInt;						// The size of the note text.
	  PictSize : LongInt;						// Reserved. Write zero. Ignore on read.
	  Checksum : SmallInt ;					// Checksum over this header and the wave header.
    end ;

TIGORBinHeader3 = packed Record
	  Version : SmallInt ;						// Version number for backwards compatibility.
	  WfmSize : LongInt;						// The size of the WaveHeader2 data structure plus the wave data plus 16 bytes of padding.
	  NoteSize : LongInt;						// The size of the note text.
	  FormulaSize : LongInt; 				// The size of the dependency formula, if any.
	  PictSize : LongInt;						// Reserved. Write zero. Ignore on read.
	  Checksum : SmallInt ;					// Checksum over this header and the wave header.
    end ;

TIGORBinHeader5 = packed Record
	Version : SmallInt ;						// Version number for backwards compatibility.
	Checksum : SmallInt ;					// Checksum over this header and the wave header.
	WfmSize : LongInt;						// The size of the WaveHeader5 data structure plus the wave data plus 16 bytes of padding.
	FormulaSize : LongInt; 				// The size of the dependency formula, if any.
	NoteSize : LongInt;						// The size of the note text.
	DataEUnitsSize : LongInt;					// The size of optional extended data units.
	DimEUnitsSize : Array[0..MAXDIMS-1] of LongInt;		// The size of optional extended dimension units.
	DimLabelsSize : Array[0..MAXDIMS-1] of LongInt;		// The size of optional dimension labels.
	SIndicesSize : LongInt;					// The size of string indicies if this is a text wave.
	OptionsSize1 : LongInt;					// Reserved. Write zero. Ignore on read.
	OptionsSize2 : LongInt;					// Reserved. Write zero. Ignore on read.
  end ;

TIGORWaveHeader2 = packed Record
	WaveType : SmallInt ;							// See types (e.g. NT_FP64) above. Zero for text waves.
  WavePointer : Pointer ;           // Used in memory only. Write zero. Ignore on read.
	bname : Array[0..MAX_WAVE_NAME2+2-1] of Char ;		// Name of wave plus trailing null.
	whVersion : SmallInt ;						// Write 0. Ignore on read.
	srcFldr : SmallInt ;							// Used in memory only. Write zero. Ignore on read.
	fileName : LongInt ;					// Used in memory only. Write zero. Ignore on read.
	dataUnits : Array[0..MAX_UNIT_CHARS+1-1] of Char ;	// Natural data units go here - null if none.
	xUnits : Array[0..MAX_UNIT_CHARS+1-1] of Char ;	            // Natural x-axis units go here - null if none.
	npnts : LongInt ;							// Number of data points in wave.
	aModified : SmallInt ;					// Used in memory only. Write zero. Ignore on read.
  hsA : Double ;                  // X value for point p = hsA*p + hsB
  hsB : Double ;
	wModified : SmallInt ;					// Used in memory only. Write zero. Ignore on read.
	swModified : SmallInt ;					// Used in memory only. Write zero. Ignore on read.
	fsValid : SmallInt ;						// True if full scale values have meaning.
	topFullScale : Double ;         // The min full scale value for wave.
  botFullScale : Double ;
	useBits : Char ;						// Used in memory only. Write zero. Ignore on read.
	kindBits : Char ;						// Reserved. Write zero. Ignore on read.
	pFormula : Pointer ;	  		// Used in memory only. Write zero. Ignore on read.
	depID: LongInt ;			  		// Used in memory only. Write zero. Ignore on read.
	creationDate : Cardinal ;			// DateTime of creation. Not used in version 1 files.
	wUnused : Array[0..1] of Char ;		// Reserved. Write zero. Ignore on read.
	modDate : Cardinal ;					// DateTime of last modification.
	waveNoteH : LongInt ;					// Used in memory only. Write zero. Ignore on read.
	wData : Array[0..3] of Single ;						// The start of the array of waveform data.
  end ;


TIGORWaveHeader5 = packed Record
	WaveHeader5 : Pointer ;			// link to next wave in linked list.
	creationDate : Cardinal ;			// DateTime of creation.
	modDate : Cardinal ;				// DateTime of last modification.
	npnts : LongInt ;							// Total number of points (multiply dimensions up to first zero).
	WaveType : SmallInt ;							// See types (e.g. NT_FP64) above. Zero for text waves.
	dLock : SmallInt ;							// Reserved. Write zero. Ignore on read.
	whpad1 : Array[0..5] of Char ;						// Reserved. Write zero. Ignore on read.
	whVersion : SmallInt ;						// Write 1. Ignore on read.
	bname : Array[0..MAX_WAVE_NAME5+1-1] of Char ;		// Name of wave plus trailing null.
	whpad2 : LongInt ;						// Reserved. Write zero. Ignore on read.
	pDataFolder : Pointer ;		// Used in memory only. Write zero. Ignore on read.
	// Dimensioning info. [0] == rows, [1] == cols etc
	nDim : Array[0..MAXDIMS-1] of LongInt ;					// Number of of items in a dimension -- 0 means no data.
	sfA : Array[0..MAXDIMS-1] of Double ;				// Index value for element e of dimension d = sfA[d]*e + sfB[d].
	sfB : Array[0..MAXDIMS-1] of Double ;
	// SI units
	dataUnits : Array[0..MAX_UNIT_CHARS+1-1] of Char ;	// Natural data units go here - null if none.
	dimUnits : Array[0..MAXDIMS-1,0..MAX_UNIT_CHARS+1-1] of Char ;     	// Natural dimension units go here - null if none.
	fsValid : SmallInt ;							// TRUE if full scale values have meaning.
	whpad3 : SmallInt ;							// Reserved. Write zero. Ignore on read.
	topFullScale : Double ;        // The max full scale value for wave.
  botFullScale : Double ;	       // The min full scale value for wave.

	dataEUnits : LongInt ;					// Used in memory only. Write zero. Ignore on read.
	dimEUnits : Array[0..MAXDIMS-1] of LongInt ;			// Used in memory only. Write zero. Ignore on read.
	dimLabels : Array[0..MAXDIMS-1] of LongInt ;				// Used in memory only. Write zero. Ignore on read.

	waveNoteH : LongInt ;					// Used in memory only. Write zero. Ignore on read.
	whUnused : Array[0..15] of LongInt ;					// Reserved. Write zero. Ignore on read.

	// The following stuff is considered private to Igor.

	aModified : SmallInt ;						// Used in memory only. Write zero. Ignore on read.
	wModified : SmallInt ;						// Used in memory only. Write zero. Ignore on read.
	swModified : SmallInt ;						// Used in memory only. Write zero. Ignore on read.

	useBits : Char ;						// Used in memory only. Write zero. Ignore on read.
	ckindBits : Char ;								// Reserved. Write zero. Ignore on read.
	formula : Pointer ;						// Used in memory only. Write zero. Ignore on read.
	depID : LongInt ;							// Used in memory only. Write zero. Ignore on read.

	whpad4 : SmallInt ;							// Reserved. Write zero. Ignore on read.
	srcFldr : SmallInt ;							// Used in memory only. Write zero. Ignore on read.
	fileName : LongInt ;					// Used in memory only. Write zero. Ignore on read.

	sIndices : Pointer ;					// Used in memory only. Write zero. Ignore on read.

	//float wData[1];						// The start of the array of data. Must be 64 bit aligned.
  end ;

TPONEMAHChannel = Packed Record
  SamplingRateDivisor : Word ;
  HighCalValue : Integer ;
  LowCalValue : Integer ;
  HighADCValue : SmallInt ;
  LowADCValue : SmallInt ;
  ScaleFactor : Integer ;
  IDText : Array[0..8] of Char ;
  end ;

TPONEMAHHeader = Packed Record
  ID : Integer ;
  Year : Word ;
  Month : Byte ;
  Day : Byte ;
  CentiSeconds : Byte ;
  Seconds : Byte ;
  Minutes : Byte ;
  Hours : Byte ;
  UserID : Integer ;
  UserName : Array[0..39] of Char ;
  SoftwareKey : Array[0..127] of Byte ;
  SamplingRate : Word ;
  ADSerialNum : Word ;
  CPSerialNum : Word ;
  NumGroups : Byte ;
  AlgorithmType : Byte ;
  DataPrecision : Byte ;
  Channels : Array[0..7] of TPONEMAHChannel ;
  end ;

TPONEMAHBlockHeader = Packed Record
  ElapsedTime : Integer ;
  SampleClock : Single ;
  BlockSize : Integer ;
  Group : Word ;
  ChanRate : Word ;
  FirstChan : Byte ;
  Unused : Byte ;
  end ;

TRIFFHeader = packed record
    ID : Array[0..3] of char ;
    ChunkSize : Cardinal ;
    Format  : Array[0..3] of char ;
    end ;

TWAVEFormatChunk = packed record
    ID : Array[0..3] of char ;
    ChunkSize : Cardinal ;
    AudioFormat : Word ;
    NumChannels : Word ;
    SampleRate : Cardinal ;
    ByteRate : Cardinal ;
    BlockAlign : Word ;
    BitsPerSample : Word ;
    end ;

TWAVEDataChunk = packed record
    ID : Array[0..3] of char ;
    ChunkSize : Cardinal ;
    end ;

  TADCDataFile = class(TComponent)
  private
    { Private declarations }
//    NewFile : Boolean ;             // TRUE if newly created file
    FFileType : TADCDataFileType ;         // Type of image file
    FVersion : Single ;             // File version number
    FIdentLine : String ;           // File ID text
    FileHandle : Integer ;         // File handle
    FFileName : String ;            // Name of data file
    FNumChannelsPerScan : Integer ; // No. of analogue channels per scan
    FNumBytesPerScan : Integer ;     // No. of byte in channel scan
    FNumBytesPerSample : Integer ;  // No. of bytes per A/D sample
    FNumScansPerRecord : Integer ;  // No. of channel scans per record
    FNumRecords : Integer ;         // No. of records in file
    FFloatingPointSamples : Boolean ; // True = floating point samples

    FNumHeaderBytes : Integer ;         // No. of bytes in file header
    FNumRecordDataBytes : Integer ;     // No. of A/D data bytes per record
    FNumRecordAnalysisBytes : Integer ; // No. of analysis bytes per record
    FNumRecordBytes : Integer ;         // No. of bytes per record

    FMaxADCValue : Integer ;        // Highest A/D sample value
    FMinADCValue : Integer ;        // Lowest A/D sample value
    FScanInterval : Single ;        // Time interval between A/D samples
    FADCVoltageRange : Single ;
    FWCPNumZeroAvg : Integer ;         // No. of A/D samples in zero average area
    FWCPRecordAccepted : Boolean ;             // True = Record accepted
    FWCPRecordType : String ;          // Type of record ;
    FWCPRecordTime : Single ;
    FWCPRecordNumber : Single ;

    FADCScale : Array[0..ChannelLimit] of Single ;
    FADCOffset : SmallInt ;

    UpdateHeader : Boolean ;        // TRUE = update of file header required

    FChannelName : Array[0..ChannelLimit] of String ;
    FChannelUnits : Array[0..ChannelLimit] of String ;
    FChannelOffset : Array[0..ChannelLimit] of Integer ;
    FChannelZero : Array[0..ChannelLimit] of Integer ;
    FChannelZeroAt : Array[0..ChannelLimit] of Integer ;
    FChannelScale : Array[0..ChannelLimit] of Single ;
    FChannelCalibrationFactor : Array[0..ChannelLimit] of Single ;
    FChannelGain : Array[0..ChannelLimit] of Single ;
    FChannelADCVoltageRange : Array[0..ChannelLimit] of Single ;

    FRecordNum : Integer ; // No. of currently selected record

    // EDR file parameters
    FEDREventDetectorChannel : Integer ;
    FEDREventDetectorRecordSize : Integer ;
    FEDREventDetectorYThreshold : Single ;
    FEDREventDetectorTThreshold : Single ;
    FEDREventDetectorDeadTime : Single ;
    FEDREventDetectorBaselineAverage : Single ;
    FEDREventDetectorPreTriggerPercentage : Single ;
    FEDREventDetectorAnalysisWindow  : Single ;

    FEDRVarianceRecordSize : Integer ;
    FEDRVarianceRecordOverlap : Integer ;
    FEDRVarianceTauRise : Single ;
    FEDRVarianceTauDecay : Single ;
    FEDRUnitCurrent : Single ;
    FEDRDwellTimesThreshold : Single ;
    FEDRWCPFileName : String ;
    FEDRBackedUp : Boolean ;

    FMarkerList : TStringList ;       // Event markers list

    WCPRecordHeader : TWCPRecordHeader ;

    // Axon ABF file data
    FABFAcquisitionMode : TABFAcquisitionMode ; // ftGapFree or ftEpisodic

    // CFS file data
    CFSFileHeader : TCFSFileHeader ;
    CFSChannelDef : Array[0..ChannelLimit] of TCFSChannelDef ;
    CFSChannel : Array[0..ChannelLimit] of Integer ;

    // ASCII file data
    TempFileName : String ;     // Temporary file for ASCII import
    TempHandle : Integer ;      // File handle for above
    FASCIISeparator : Char ;       // ASCII item separator character
    ASCTimeColumn : Integer ;      // ASCII table column contain time data
    FASCIITitleLines : Integer ;   // No. of title lines in file (to be skipped)
    FASCIITimeUnits : String ;      // ASCII time units ('s','ms','min')
    ASCScale : Array[0..ChannelLimit] of Single ;
    FASCIIFixedRecordSize : Boolean ; // Fixed record size flag

    UseTempFile : Boolean ;
    //InBuf : Array[0..64000] of SmallInt ;

    procedure WCPLoadFileHeader ;
    function WCPSaveFileHeader : Boolean ;
    function WCPNumAnalysisBytesPerRecord(
             NumChannels : Integer ) : Integer ;
    function WCPNumBytesInFileHeader(
             NumChannels : Integer ) : Integer ;

    function EDRLoadFileHeader : Boolean ;
    function EDRSaveFileHeader : Boolean ;
    function ABFSaveFileHeader : Boolean ;
    function IBWSaveFileHeader : Boolean ;
    function CHTSaveFileHeader : Boolean ;
    function WAVSaveFileHeader : Boolean ;
    function CFSSaveFileHeader : Boolean ;
    procedure CFSSaveDataHeader( RecordNum : Integer ) ;

    function CDRLoadFileHeader : Boolean ;
    function SPALoadFileHeader : Boolean ;
    function SCALoadFileHeader : Boolean ;
    function SCDLoadFileHeader : Boolean ;
    function WCDLoadFileHeader : Boolean ;
    function LDTLoadFileHeader : Boolean ;
    function ABFLoadFileHeader : Boolean ;
    function PClampV5LoadFileHeader : Boolean ;
    function CFSLoadFileHeader : Boolean ;

    function WFDBLoadFile : Boolean ;
    function PNMLoadFile : Boolean ;
    function CHTLoadFileHeader : Boolean ;
    function WAVLoadFileHeader : Boolean ;

    function ASCLoadFile : Boolean ;
    function ASCSaveFile : Boolean ;
    procedure ASCReadLine(
              FileHandle : Integer ;
              ItemSeparator : Char ;
              var Line : String ;
              var Items : Array of String ;
              var NumItems : Integer ;
              var EOF : Boolean ) ;

    function RawLoadHeader : Boolean ;
    function IBWLoadFileHeader : Boolean ;

    function HEKLoadFile : Boolean ;
    procedure HEKReadLine(
         FileHandle : Integer ;       // Handle of file being read
         ItemSeparator : Char ;       // Item separator character
         var Line : String ;          // Returns full line read
         var Items : Array of String ;// Returns items within line
         var NumItems : Integer ;      // Returns no. of items
         var EOF : Boolean ) ;        // Returns True if at end of file


    function CharacterArrayToString(
             Buf : Array of Char
             )  : String ;

    procedure StringToCharacterArray(
              Source : String ;
              var Dest : Array of Char
              ) ;

    function ADCScale( ch : Integer ) : Single ;
    function CalibFactor( ch : Integer ) : Single ;

    function GetChannelName( i : Integer ) : String ;
    function GetChannelUnits( i : Integer ) : String ;
    function GetChannelOffset( i : Integer ) : Integer ;
    function GetChannelZero( i : Integer ) : Integer ;
    function GetChannelZeroAt( i : Integer ) : Integer ;
    function GetChannelScale( i : Integer ) : Single ;
    function GetChannelCalibrationFactor( i : Integer ) : Single ;
    function GetChannelGain( i : Integer ) : Single ;
    function GetChannelADCVoltageRange( i : Integer ) : Single ;
    function GetScanInterval : Single ;
    function GetASCIITimeDataInCol0 : Boolean ;

    procedure SetChannelName( i : Integer ; Value : String ) ;
    procedure SetChannelUnits( i : Integer ; Value : String ) ;
    procedure SetChannelOffset( i : Integer ; Value : Integer ) ;
    procedure SetChannelZero( i : Integer ; Value : Integer ) ;
    procedure SetChannelZeroAt( i : Integer ; Value : Integer ) ;
    procedure SetChannelScale( i : Integer ; Value : Single ) ;
    procedure SetChannelCalibrationFactor( i : Integer ; Value : Single ) ;
    procedure SetChannelGain( i : Integer ; Value : Single ) ;
    procedure SetChannelADCVoltageRange( i : Integer ; Value : Single ) ;
    procedure SetRecordNum( Value : Integer ) ;
    procedure SetNumScansPerRecord( Value : Integer ) ;
    procedure SetNumChannelsPerScan( Value : Integer ) ;
    procedure SetNumBytesPerSample( Value : Integer ) ;
    procedure SetASCIITimeDataInCol0( Value : Boolean ) ;

    function SwapByteOrder(
             Buf : Array of Byte ;
             iStart : Integer ;
             NumBytes : Integer
             ) : Integer ;

    function FloatSwapByteOrder(
         Buf : Array of Byte ;
         iStart : Integer
         ) : Single ;


    procedure AppendFloat(
              var Dest : array of char;
              Keyword : string ;
              Value : Extended
              ) ;
    procedure ReadFloat(
              const Source : array of char;
              Keyword : string ;
              var Value : Single ) ;
    procedure AppendInt(
              var Dest : array of char;
              Keyword : string ;
              Value : Integer
              ) ;
    procedure ReadInt(
              const Source : array of char;
              Keyword : string ;
              var Value : Integer
              ) ;
    procedure AppendLogical(
              var Dest : array of char;
              Keyword : string ;
              Value : Boolean ) ;
    procedure ReadLogical(
              const Source : array of char;
              Keyword : string ;
              var Value : Boolean
              ) ;
    procedure AppendString(
              var Dest : Array of char;
              Keyword,
              Value : string
              ) ;
    procedure ReadString(
              const Source : Array of char;
              Keyword : string ;
              var Value : string
              ) ;

    procedure CopyStringToArray( var Dest : array of char ; Source : string ) ;
    procedure CopyArrayToString( var Dest : string ; var Source : array of char ) ;
    procedure FindParameter(
              const Source : array of char ;
              Keyword : string ;
              var Parameter : string ) ;
    function ExtractFloat ( CBuf : string ; Default : Single) : single ;
    function ExtractInt ( CBuf : string ) : Integer ;

    function ExtractItems(
             TextLine : String ;
             Separator : Char ;
             var Items : Array of String ) : Integer ;
    function CreateTempFileName : String ;

    procedure FillCharArray(
              InString : String ;
              var OutArray : Array of Char ;
              NullTerminate : Boolean
              ) ;

    function IGORChecksum(
             pData : Pointer ;
             OldCkSum : Integer ;
             NumBytes : Integer
             ) : Integer ;

    procedure ZeroMem(
              pBuf : Pointer ;
              NumBytes : Integer
              ) ;

  protected
    { Protected declarations }
  public
    { Public declarations }

   Constructor Create(AOwner : TComponent) ; override ;
   Destructor Destroy ; override ;

   function CreateDataFile( FileName : String ; FileType : TADCDataFileType ) : Boolean ;
   function OpenDataFile( FileName : String ; FileType : TADCDataFileType  ) : Boolean ;
   function FindFileType( FileName : String ) : TADCDataFileType ;

   procedure CloseDataFile ;

   function LoadADCBuffer(
         StartAtScan : Integer ;
         NumScans : Integer ;
         Var Buf : Array of SmallInt ) : Integer ;

   function SaveADCBuffer(
         StartAtScan : Integer ;
         NumScans : Integer ;
         Var Buf : Array of SmallInt ) : Integer ;

    function WCPLoadRecordHeader(
             var WCPRecordHeaderOut : TWCPRecordHeader
             ) : Boolean ;
    function WCPSaveRecordHeader(
             var WCPRecordHeaderIn : TWCPRecordHeader
             ) : Boolean ;

    property ChannelName[i:Integer] : String
             read GetChannelName Write SetChannelName ;
    property ChannelUnits[i:Integer] : String
             read GetChannelUnits Write SetChannelUnits ;
    property ChannelOffset[i:Integer] : Integer
             read GetChannelOffset Write SetChannelOffset ;
    property ChannelZero[i:Integer] : Integer
             read GetChannelZero Write SetChannelZero ;
    property ChannelZeroAt[i:Integer] : Integer
             read GetChannelZeroAt Write SetChannelZeroAt ;
    property ChannelScale[i:Integer] : Single
             read GetChannelScale Write SetChannelScale ;
    property ChannelCalibrationFactor[i:Integer] : Single
             read GetChannelCalibrationFactor Write SetChannelCalibrationFactor ;
    property ChannelGain[i:Integer] : Single
             read GetChannelGain Write SetChannelGain ;
    property ChannelADCVoltageRange[i:Integer] : Single
             read GetChannelADCVoltageRange Write SetChannelADCVoltageRange ;

  published
    { Published declarations }
    Property FileName : String Read FFileName ;
    Property FileType : TADCDataFileType Read FFileType ;
    Property NumChannelsPerScan : Integer Read FNumChannelsPerScan Write SetNumChannelsPerScan ;
    Property NumBytesPerSample : Integer Read FNumBytesPerSample Write SetNumBytesPerSample ;
    Property NumScansPerRecord : Integer Read FNumScansPerRecord Write SetNumScansPerRecord ;
    Property FloatingPointSamples : Boolean Read FFloatingPointSamples Write FFloatingPointSamples ;
    Property NumRecords : Integer Read FNumRecords ;
    Property MaxADCValue : Integer Read FMaxADCValue Write FMaxADCValue ;
    Property MinADCValue : Integer Read FMinADCValue Write FMinADCValue ;
    Property RecordNum : Integer Read FRecordNum Write SetRecordNum ;
    Property IdentLine : String Read FIdentLine Write FIdentLine ;
    Property ScanInterval : Single Read GetScanInterval Write FScanInterval ;
    Property NumFileHeaderBytes : Integer Read FNumHeaderBytes Write FNumHeaderBytes ;

    // WCP file properties
    Property WCPNumZeroAvg : Integer Read FWCPNumZeroAvg Write FWCPNumZeroAvg ;
    Property WCPRecordAccepted : Boolean Read FWCPRecordAccepted  Write FWCPRecordAccepted ;
    Property WCPRecordType : String Read FWCPRecordType  Write FWCPRecordType ;
    Property WCPRecordNumber : Single Read FWCPRecordNumber Write FWCPRecordNumber ;
    Property WCPRecordTime : Single Read FWCPRecordTime Write FWCPRecordTime ;

    Property ABFAcquisitionMode : TABFAcquisitionMode Read FABFAcquisitionMode Write FABFAcquisitionMode ;

    // EDR file properties
    Property EDREventDetectorChannel : Integer
             read FEDREventDetectorChannel write FEDREventDetectorChannel ;
    Property EDREventDetectorRecordSize : Integer
             read FEDREventDetectorRecordSize write FEDREventDetectorRecordSize ;
    Property EDREventDetectorYThreshold : Single
             read FEDREventDetectorYThreshold write FEDREventDetectorYThreshold ;
    Property EDREventDetectorTThreshold : Single
             read FEDREventDetectorTThreshold write FEDREventDetectorTThreshold ;
    Property EDREventDetectorDeadTime : Single
             read FEDREventDetectorDeadTime write FEDREventDetectorDeadTime ;
    Property EDREventDetectorBaselineAverage : Single
             read FEDREventDetectorBaselineAverage write FEDREventDetectorBaselineAverage ;
    Property EDREventDetectorPreTriggerPercentage : Single
             read FEDREventDetectorPreTriggerPercentage write FEDREventDetectorPreTriggerPercentage ;
    Property EDREventDetectorAnalysisWindow : Single
             read FEDREventDetectorAnalysisWindow write FEDREventDetectorAnalysisWindow ;

    Property EDRVarianceRecordSize : Integer
             read FEDRVarianceRecordSize write FEDRVarianceRecordSize ;
    Property EDRVarianceRecordOverlap : Integer
             read FEDRVarianceRecordOverlap write FEDRVarianceRecordOverlap ;
    Property EDRVarianceTauRise : Single
             read FEDRVarianceTauRise write FEDRVarianceTauRise ;
    Property EDRVarianceTauDecay : Single
             read FEDRVarianceTauDecay write FEDRVarianceTauDecay ;
    Property EDRUnitCurrent : Single
             read FEDRUnitCurrent write FEDRUnitCurrent ;
    Property EDRDwellTimesThreshold : Single
             read FEDRDwellTimesThreshold write FEDRDwellTimesThreshold ;
    Property EDRWCPFileName : String
             read FEDRWCPFileName write FEDRWCPFileName ;
    Property EDRBackedUp : Boolean
             read FEDRBackedUp write FEDRBackedUp ;

    Property ASCIISeparator : Char Read FASCIISeparator Write FASCIISeparator ;
    Property ASCIITimeDataInCol0 : Boolean
             Read GetASCIITimeDataInCol0 Write SetASCIITimeDataInCol0 ;
    Property ASCIITimeUnits : String Read FASCIITimeUnits Write FASCIITimeUnits ;
    Property ASCIITitleLines : Integer Read FASCIITitleLines Write FASCIITitleLines ;
    Property ASCIIFixedRecordSize : Boolean Read FASCIIFixedRecordSize Write FASCIIFixedRecordSize ;
  end;

procedure Register;

implementation



uses Dialogs, StrUtils ;

procedure Register;
begin
  RegisterComponents('Samples', [TADCDataFile]);
end;


constructor TADCDataFile.Create(AOwner : TComponent) ;
{ --------------------------------------------------
  Initialise component's internal objects and fields
  -------------------------------------------------- }
var
     ch : Integer ;
begin

     inherited Create(AOwner) ;

     FileHandle := -1 ;
     FFileName := '' ;
     FNumRecords := 0 ;
     FRecordNum := 0 ;
     FNumChannelsPerScan := 1 ;
     FNumBytesPerSample := 2 ;
     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
     FNumScansPerRecord := 512 ;
     FMinADCValue := -2048 ;
     FMaxADCValue := 2047 ;
     FFloatingPointSamples := False ;

     for ch := 0 to ChannelLimit do FADCScale[ch] := 1.0 ;
     FADCOffset := 0 ;

     FASCIISeparator := #9 ;  // Tab character
     ASCTimeColumn := 1 ;
     FASCIITitleLines := 2 ;
     FASCIITimeUnits := 's' ;
     FASCIIFixedRecordSize := False ;

     UseTempFile := False ;

     FMarkerList := TStringList.Create ;

     UpdateHeader := False ;

     end ;


destructor TADCDataFile.Destroy ;
{ ------------------------------------
   Tidy up when component is destroyed
   ----------------------------------- }
begin

     // Close file
     CloseDataFile ;

     FMarkerList.Free ;

     { Call inherited destructor }
     inherited Destroy ;

     end ;


function TADCDataFile.OpenDataFile(
         FileName : String ;           // File name
         FileType : TADCDataFileType   // Data file format
         ) : Boolean ;
// --------------
// Open data file
// --------------
begin

     Result := False ;

     if FileHandle >= 0 then begin
        ShowMessage( 'A file is aready open ' ) ;
        Exit ;
        end ;

     // Open file
     FFileName := FileName ;
     FileHandle := FileOpen( FFileName, fmOpenReadWrite ) ;
     if FileHandle < 0 then begin
        ShowMessage( 'TADCDataFile: Unable to open ' ) ;
        Exit ;
        end ;

     // Determine type of file if unknown
     if FileType = ftUnknown then begin
        FFileType := FindFileType( FFileName ) ;
        end
     else FFileType := FileType ;

     // Load header data
     Case FFileType of
          ftWCP : WCPLoadFileHeader ;
          ftEDR : EDRLoadFileHeader ;
          ftCDR : CDRLoadFileHeader ;
          ftSCD : SCDLoadFileHeader ;
          ftWCD : WCDLoadFileHeader ;
          ftSPA : SPALoadFileHeader ;
          ftSCA : SCALoadFileHeader ;
          ftAxonPClampV5 : PClampV5LoadFileHeader ;
          ftAxonABF : ABFLoadFileHeader ;
          ftCFS : CFSLoadFileHeader ;
          ftASC : ASCLoadFile ;
          ftWFDB : WFDBLoadFile ;
          ftRaw : RAWLoadHeader ;
          ftIBW : IBWLoadFileHeader ;
          ftPNM : PNMLoadFile ;
          ftCHT : CHTLoadFileHeader ;
          ftWAV : WAVLoadFileHeader ;
          ftHEK : HEKLoadFile ;
          end ;

     Result := True ;

     end ;


function TADCDataFile.FindFileType(
         FileName : String             // Name of file to be tested
         ) : TADCDataFileType ;        // File data format
// ------------------------
// Return type of data file
// ------------------------
var
    s : String ;
    IdentChar : Array[1..8] of Char ;
    IdentNumber : Single ;
    i : Integer ;
    TempFileOpen : Boolean ;
begin

     Result := ftUnknown ;

     // Open file if it is not already open
     if FileHandle < 0 then begin
        FileHandle := FileOpen( FileName, fmOpenRead ) ;
        if FileHandle < 0 then begin
           ShowMessage( 'Unable to open ' + FileName ) ;
           Exit ;
           end ;
        TempFileOpen := True ;
        end
      else TempFileOpen := False ;

     // Is it an Axon PClamp V6 or later data file?
     if Result = ftUnknown then begin
        FileSeek( FileHandle, 0, 0 ) ;
        if FileRead(FileHandle,IdentChar,Sizeof(IdentChar))
           = Sizeof(IdentChar) then begin
           s := '' ;
           for i := 1 to High(IdentChar) do s := s + IdentChar[i] ;
           if (Pos('ABF',s) > 0) or
              (Pos('CPLX',s) > 0) or
              (Pos('FTCX',s) > 0) then Result := ftAxonABF ;
           end ;
        end ;

      { Is it an Axon PClamp V5 data file? }
      if Result = ftUnknown then begin
         FileSeek( FileHandle, 0, 0 ) ;
         if FileRead(FileHandle,IdentNumber,Sizeof(IdentNumber))
            = Sizeof(IdentNumber) then begin
            if (IdentNumber = 1. ) or (IdentNumber = 10. ) then Result := ftAxonPClampV5 ;
            end ;
         end ;

      { Is it a CED Filing System data file? }
      if Result = ftUnknown then begin
         FileSeek( FileHandle, 0, 0 ) ;
         if FileRead(FileHandle,IdentChar,Sizeof(IdentChar))
            = Sizeof(IdentChar) then begin
            s := '' ;
            for i := 1 to High(IdentChar) do s := s + IdentChar[i] ;
            if (Pos('CEDFILE',s) > 0) then Result := ftCFS ;
            end ;
         end ;

      { Is it a WAV data file ? }
     if Result = ftUnknown then begin
        FileSeek( FileHandle, 0, 0 ) ;
        if FileRead(FileHandle,IdentChar,Sizeof(IdentChar))
           = Sizeof(IdentChar) then begin
           s := '' ;
           for i := 1 to High(IdentChar) do s := s + IdentChar[i] ;
           if (Pos('RIFF',s) > 0) then Result := ftWAV ;
           end ;
        end ;

      { Is it a CDR data file ? }
      if Result = ftUnknown then begin
         if ExtractFileExt(LowerCase(FileName)) = '.cdr' then Result := ftCDR ;
         end ;

        { Is it a Strathclyde DOS CDR data file? }
{        FileSeek( FileHandle, 0, 0 ) ;
        if FileRead(FileHandle,CDRHeader,Sizeof(CDRHeader))
           = Sizeof(CDRHeader) then begin
           if (CDRHeader.signature[0] = 'C') and
              (CDRHeader.signature[1] = 'D') and
              (CDRHeader.signature[2] = 'R') then FileType := CDR ;
           end ;}

      { Is it a WinWCP data file ? }
      if Result = ftUnknown then begin
         if ExtractFileExt(LowerCase(FileName)) = '.wcp' then Result := ftWCP ;
         end ;

      { Is it a PAT file }
      if Result = ftUnknown then begin
         if ExtractFileExt(LowerCase(FileName)) = '.scd' then Result := ftSCD ;
         end ;

      { Is it a WCD (WinCDR V2.X file) }
      if Result = ftUnknown then begin
         if ExtractFileExt(LowerCase(FileName)) = '.wcd' then Result := ftWCD ;
         end ;

      { Is it a SPAN data file ? }
      if Result = ftUnknown then begin
         if ExtractFileExt(LowerCase(FileName)) = '.spa' then Result := ftSPA ;
         end ;

      { Is it a SCAN data file ? }
      if Result = ftUnknown then begin
         if ExtractFileExt(LowerCase(FileName)) = '.sca' then Result := ftSCA ;
         end ;

      { Is it an ASCII text data file ? }
      if Result = ftUnknown then begin
         if (ExtractFileExt(LowerCase(FileName)) = '.txt') or
            (ExtractFileExt(LowerCase(FileName)) = '.dat')then Result := ftASC ;
         end ;

      { Is it an WFDB header file ? }
      if Result = ftUnknown then begin
         if (ExtractFileExt(LowerCase(FileName)) = '.hea') then Result := ftWFDB ;
         end ;

      { Is it an IGOR Binary Wave file ? }
      if Result = ftUnknown then begin
         if ExtractFileExt(LowerCase(FileName)) = '.ibw' then Result := ftIBW ;
         end ;

      { Is it a PoNeMah protocol file ? }
      if Result = ftUnknown then begin
         if ExtractFileExt(LowerCase(FileName)) = '.pro' then Result := ftPNM ;
         end ;

      { Is it a Strathclyde Chart data file ? }
      if Result = ftUnknown then begin
         if ExtractFileExt(LowerCase(FileName)) = '.cht' then Result := ftCHT ;
         end ;

      // Close file if this was only a
      if TempFileOpen then begin
         FileClose(FileHandle) ;
         FileHandle := -1 ;
         end ;

      end ;


function TADCDataFile.CreateDataFile(
         FileName : String ;
         FileType : TADCDataFileType
         ) : Boolean ;
// ----------------------
//   Create new data file
// ----------------------
const
     NumBytesPerSector = 512 ;
var
     ch : Integer ;
begin

     Result := False ;

     if FileHandle >= 0 then begin
        ShowMessage( 'TADCDataFile: A file is aready open ' ) ;
        Exit ;
        end ;

    for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
    FADCOffset := 0 ;


     // Set file name and type
     FFileName := FileName ;
     FFileType := FileType ;

     // Create data file (for file types which write directly to file)
     if FFileType <> ftASC then begin
        FileHandle := FileCreate( FFileName ) ;
        if FileHandle < 0 then begin
           ShowMessage( 'Unable to create ' + FileName ) ;
           Exit ;
           end ;
        end ;

     case FFileType of

        ftWCP : begin
           // WCP data file
           FNumBytesPerSample := 2 ;
           FNumHeaderBytes := 1024 ;
           FNumRecordAnalysisBytes := 1024 ;
           FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
           FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
           FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;
           FFloatingPointSamples := False ;
           end ;

        ftEDR : begin
           // EDR data file
           FNumBytesPerSample := 2 ;
           FNumHeaderBytes := EDRFileHeaderSize ;
           FNumRecordAnalysisBytes := 0 ;
           FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
           FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
           FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;
           FFloatingPointSamples := False ;
           end ;

        ftAxonABF : begin
           // ABF data file
           FNumBytesPerSample := 2 ;
           FNumHeaderBytes := ABFFileHeaderSize_V15 ;
           FNumRecordAnalysisBytes := 0 ;
           FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
           FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
           FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;
           FFloatingPointSamples := False ;
           end ;

        ftASC : Begin
           // ASCII format output file
           // ------------------------

           FNumBytesPerSample := 4 ;
           FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
           FNumScansPerRecord := 1 ;

           { Get byte offset of data section }
           FNumHeaderBytes :=  0 ;
           FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
           FNumRecordAnalysisBytes := 0 ;
           FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

           FADCVoltageRange := 10.0 ;
           FMaxADCValue := 32767 ;
           FMinADCValue := -FMaxADCValue - 1 ;
           for ch := 0 to ChannelLimit do FADCScale[ch] := 1.0 ;
           FADCOffset := 0 ;

           // Create a temporary file
           TempFileName := CreateTempFileName ;
           TempHandle := FileCreate( TempFileName ) ;

           end ;

        ftIBW : begin
           // IGOR Binary Wave (V5) data file
           FNumBytesPerSample := 4 ;
           FNumHeaderBytes := SizeOf(TIGORBinHeader5) + SizeOf(TIGORWaveHeader5) ;
           FNumRecordAnalysisBytes := 0 ;
           FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
           FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
           FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;
           FFloatingPointSamples := True ;
           end ;

        ftCHT : begin
           // Chart data file
           FNumBytesPerSample := 2 ;
           FNumHeaderBytes := CHTFileHeaderSize ;
           FNumRecordAnalysisBytes := 0 ;
           FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
           FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
           FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;
           FFloatingPointSamples := False ;
           end ;

        ftWAV : begin
           // WAV data file
           FNumBytesPerSample := 2 ;
           FNumHeaderBytes := SizeOf(TRIFFHeader) +
                              SizeOf(TWaveFormatChunk) +
                              SizeOf(TWaveDataChunk) ;
           FNumRecordAnalysisBytes := 0 ;
           FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
           FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
           FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;
           FFloatingPointSamples := False ;
           end ;

        ftCFS : begin
           // CFS data file
           FNumBytesPerSample := 2 ;
           FNumHeaderBytes := 4096 ;
           FNumRecordAnalysisBytes := 512 ;
           FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
           FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
           FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;
           FFloatingPointSamples := False ;
           end ;

        end ;

     FNumRecords := 0 ;
     FRecordNum := 0 ;

     UpdateHeader := True ;

     Result := True ;

     end ;


function TADCDataFile.CreateTempFileName : String ;
// --------------------------
// Create temporary file name
// --------------------------
var
     TempPath : Array[0..100] of Char ;
     TempName : Array[0..100] of Char ;
begin
     GetTempPath( High(TempPath), TempPath )  ;
     GetTempFilename( TempPath, PChar('TADCDataFile'), 0, TempName ) ;
     Result := String(TempName) ;
     end ;


procedure TADCDataFile.CloseDataFile ;
// -----------------
//   Close data file
// -----------------
begin

     if UpdateHeader then begin
        case FFileType of
             ftWCP : WCPSaveFileHeader ;
             ftEDR : EDRSaveFileHeader ;
             ftAxonABF : ABFSaveFileHeader ;
             ftIBW : IBWSaveFileHeader ;
             ftASC : ASCSaveFile ;
             ftCHT : CHTSaveFileHeader ;
             ftWAV : WAVSaveFileHeader ;
             ftCFS : CFSSaveFileHeader ;
             end ;
        UpdateHeader := False ;
        end ;

     // Close ASCII temporary file (if open)
     if  TempHandle >= 0 then begin
        FileClose( TempHandle ) ;
        TempHandle := -1 ;
        end ;

     if FileHandle < 0 then Exit ;

     // Close image file
     FileClose( FileHandle ) ;
     FileHandle := -1 ;

     end ;


function TADCDataFile.LoadADCBuffer(
         StartAtScan : Integer ; // Start at scan #
         NumScans : Integer ;    // No. of scans to load
         Var Buf : Array of SmallInt ) : Integer ;
// ----------------------------------------
// Load A/D samples from record into buffer
// ----------------------------------------
type
     TFPBuf = Array[0..9999999] of Single ;
     PFPBuf = ^TFPBuf ;
var
     FilePointer : Integer ;
     FileHandle1 : Integer ;
     NumBytesRead : Integer ;
     i,j : Integer ;
     ch : Integer ;
     CFSch : Integer ;
     DataPointer : Integer ;
     RecHeader : TCFSDataHeader ;
     ChannelInfo : Array[0..15] of TCFSChannelInfo ;
     FPBuf : PFPBuf ;
     YInt : SmallInt ;
     YInt4 : Integer ;
     YSng : Single ;
     YDbl : Double ;
begin

     if FNumRecords <= 0 then begin
        Result := 0 ;
        Exit ;
        end ;

      // Ensure record number is valid
      FRecordNum := Max(FRecordNum,1);

      if FFileType = ftCFS then begin

         // Load CFS file record
         // --------------------

         { Get pointer to start of data record #Rec }
         FileSeek( FileHandle,CFSFileHeader.TablePos + (FRecordNum-1)*4, 0 ) ;
         FileRead(FileHandle,DataPointer,SizeOf(DataPointer)) ;

         { Read record data header & channel info }
         FileSeek( FileHandle, DataPointer, 0 ) ;
         FileRead( FileHandle,RecHeader,SizeOf(RecHeader)) ;
         for ch := 0 to CFSFileHeader.DataChans-1 do
             FileRead( FileHandle,ChannelInfo[ch],SizeOf(TCFSChannelInfo)) ;

         // Copy each channel individually
         for ch := 0 to FNumChannelsPerScan-1 do begin

             CFSch := CFSChannel[ch] ;

             // Move to start of data
             FilePointer := RecHeader.DataSt
                            + ChannelInfo[CFSch].DataOffset
                            + StartAtScan*CFSChannelDef[CFSch].dSpacing ;
             // Copy data
             for i := 0 to NumScans-1 do begin
                 j := i*FNumChannelsPerScan + FChannelOffset[ch] ;
                 FileSeek( FileHandle, FilePointer, 0 ) ;
                 case CFSChannelDef[CFSch].dType of
                    2 : begin
                        FileRead( FileHandle, YInt, 2 ) ;
                        Buf[j] := YInt ;
                        end ;
                    4 : begin
                        FileRead( FileHandle, YInt4, 4 ) ;
                        Buf[j] := SmallInt(YInt4 div $10000)
                        end ;
                    5 : begin
                        FileRead( FileHandle, YSng, 4 ) ;
                        Buf[j] := Round( YSng / FChannelScale[ch] ) ;
                        end ;
                    6 : begin
                        FileRead( FileHandle, YDbl, 8 ) ;
                        Buf[j] := Round( YDbl / FChannelScale[ch] ) ;
                        end ;
                    end ;

                FilePointer := FilePointer + CFSChannelDef[CFSch].dSpacing ;
                end ;
             end ;
             Result := NumScans ;

         end
      else begin

        // Load other types of record
        // --------------------------

        // Load analysis block (if WCP file)
        if FFileType = ftWCP then WCPLoadRecordHeader( WCPRecordHeader ) ;

        if UseTempFile then FileHandle1 := TempHandle
                       else FileHandle1 := FileHandle ;

        // Move file pointer to start of data
        FilePointer := (FRecordNum - 1)*FNumRecordBytes
                       + FNumHeaderBytes
                       + FNumRecordAnalysisBytes
                       + StartAtScan*FNumBytesPerScan ;
        FileSeek( FileHandle1, FilePointer, 0 ) ;

        if FFloatingPointSamples then begin
           // Read A/D samples in floating point format
           GetMem( FPBuf, NumScans*FNumBytesPerScan ) ;
           NumBytesRead := FileRead( FileHandle1,
                                     FPBuf^,
                                     NumScans*FNumBytesPerScan ) ;
           ch := 0 ;
           for i := 0 to (NumBytesRead div FNumBytesPerSample)-1 do begin
               Buf[i] := Round((FPBuf^[i]-FADCOffset)*FADCScale[ch]) ;
               Inc(ch) ;
               if ch >= FNumChannelsPerScan then ch := 0 ;
               end ;
           FreeMem( FPBuf ) ;
           end
        else begin
           // Read A/D samples
           NumBytesRead := FileRead( FileHandle1,
                                     Buf,
                                     NumScans*FNumBytesPerScan ) ;

        //   for i := 0 to NumScans*FNumChannelsPerScan-1 do
       //        Buf[i] := (WBuf[i] div 2) ;
           // Scale/shift samples
           j := 0 ;
           for i := 0 to NumScans-1 do begin
               for ch := 0 to FNumChannelsPerScan-1 do begin
                   Buf[j] := Round((Buf[j] - FADCOffset)*FADCScale[ch]) ;
                   Inc(j) ;
                   end ;
               end ;
           end ;

        // Return no. scans read
        Result := NumBytesRead div FNumBytesPerScan ;

        end ;


     end ;


function TADCDataFile.SaveADCBuffer(
         StartAtScan : Integer ;      // Start at scan #
         NumScans : Integer ;         // No. of scans to save
         Var Buf : Array of SmallInt
         ) : Integer ;
// ----------------------------------------
// Save A/D samples from buffer to record
// ----------------------------------------
var
     FilePointer : Int64 ;
     FileHandle1 : Integer ;      // File handle selected for writing to
     NumBytesWritten : Integer ;
     i,j,ch : Integer ;
     OutBuf : PSmallIntArray ;
     Value : Single ;
begin

     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
     FNumScansPerRecord := Max(NumScans + StartAtScan,FNumScansPerRecord) ;
     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

     // Allocate output buffer
     GetMem( OutBuf, FNumRecordDataBytes ) ;

     // Update no. records in file
     FRecordNum := Max(FRecordNum,1);
     if FRecordNum > FNumRecords then FNumRecords := FRecordNum ;

     // Select O/P directly to data file or to temp. file
     if (FFileType = ftASC) or UseTempFile then FileHandle1 := TempHandle
                                           else FileHandle1 := FileHandle ;

     // Move file pointer to start of data
     FilePointer := (FRecordNum - 1)*FNumRecordBytes
                    + FNumHeaderBytes
                    + FNumRecordAnalysisBytes
                    + StartAtScan*FNumBytesPerScan ;
     FileSeek( FileHandle1, FilePointer, 0 ) ;

     if (FFileType = ftASC) or FFloatingPointSamples then begin
        // Write data in scaled floating point values
        j := 0 ;
        for i := 0 to NumScans-1 do begin
            for ch := 0 to FNumChannelsPerScan-1 do begin
                Value := (Buf[j]- FChannelZero[ch])*FChannelScale[ch] ;
                FileWrite(FileHandle1,Value,SizeOf(Value) ) ;
                Inc(j) ;
                end ;
            end ;

        // Return no. scans written
        Result := NumScans ;

        end
     else begin
        // Write as integer values
        j := 0 ;
        for i := 0 to NumScans-1 do begin
            for ch := 0 to FNumChannelsPerScan-1 do begin
                OutBuf^[j] := Round(Buf[j]/FADCScale[ch]) + FADCOffset ;
                Inc(j) ;
                end ;
            end ;

        // Write`A/D samples
        NumBytesWritten := FileWrite( FileHandle1,
                                      OutBuf^,
                                      NumScans*FNumBytesPerScan ) ;
        // Return no. scans written
        Result := NumBytesWritten div FNumBytesPerScan ;

        end ;

     // Save record header block
     case FFileType of
          ftWCP : WCPSaveRecordHeader( WCPRecordHeader ) ;
          ftCFS : CFSSaveDataHeader( FRecordNum ) ;
        end ;

     FreeMem( OutBuf ) ;

     UpdateHeader := True ;
     end ;


procedure TADCDataFile.WCPLoadFileHeader ;
// -------------------------------------------
// Read file header block from WCP data file,
// -------------------------------------------

const
     NumBytesPerSector = 512 ;
var
   Header : array[1..WCPMaxBytesInFileHeader] of char ;
   RecordStatusArray : array[0..3] of char ;
   RecordStatus : string ;
   i,NumBytesInFile,FilePointer,ch,RecordCounter : Integer ;
   Done : Boolean ;

begin

     { Determine size of file header }
     FilePointer := 0 ;
     RecordCounter := 0 ;
     Done := False ;
     while not Done do begin

         { Get WCP 8 byte data record status field }
         FileSeek( FileHandle, FilePointer, 0 ) ;
         FileRead( FileHandle, RecordStatusArray, 4 ) ;
         CopyArrayToString(RecordStatus,RecordStatusArray) ;

         { Is it a record status field }
         if (RecordStatus = 'ACCE') or
            (RecordStatus = 'REJE') or
            (RecordStatus = 'acce') or
            (RecordStatus = 'reje') then begin
            Inc(RecordCounter) ;
            if RecordCounter = 1 then begin
               FNumHeaderBytes := FilePointer
               end
            else if  RecordCounter = 2 then begin
               FNumRecordBytes := FilePointer - FNumHeaderBytes  ;
               Done := True ;
               end ;
            end ;
         { Exit if end of file reached }
         FilePointer := FilePointer + NumBytesPerSector ;
         if FilePointer > FileSeek(FileHandle,0,2) then Done := True ;
         end ;

     if RecordCounter = 0 then begin
        FNumHeaderBytes := 1024 ;
        FNumRecordAnalysisBytes := 1024 ;
        FNumRecordBytes := 0 ;
        end
     else if RecordCounter = 1 then begin
        FNumRecordBytes := FileSeek(FileHandle,0,2) - FNumHeaderBytes ;
        end ;

     { Read file header }
     FileSeek( FileHandle, 0, 0 ) ;
     for i := 0 to High(Header) do Header[i] := #0 ;

     if FileRead( FileHandle, Header, FNumHeaderBytes ) <> FNumHeaderBytes then begin
        ShowMessage( FFileName + ' : Error reading file header!' ) ;
        Exit ;
        end ;

     ReadFloat( Header, 'VER=',FVersion );

     FFloatingPointSamples := False ;
     FNumBytesPerSample := 2 ;

     // No. input channels scanned
     ReadInt( Header, 'NC=', FNumChannelsPerScan ) ;
     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;

     // A/D sample value range
     FMaxADCValue := 0 ;
     ReadInt( Header, 'ADCMAX=', FMaxADCValue ) ;
     if FMaxADCValue = 0 then FMaxADCValue := 2047 ;
     FMinADCValue := -FMaxADCValue - 1 ;

     // Size of data record
     ReadInt( Header, 'NBD=', FNumRecordDataBytes ) ;
     FNumRecordDataBytes := FNumRecordDataBytes*NumBytesPerSector ;

     { Compute other record size parameters, handling situation where
       overall record size is not known }
     if FNumRecordBytes > 0 then begin
        FNumRecordAnalysisBytes := FNumRecordBytes - FNumRecordDataBytes ;
        end
     else begin
        FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;
        end ;

     FNumScansPerRecord := FNumRecordDataBytes div FNumBytesPerScan ;

     ReadFloat( Header, 'AD=',FADCVoltageRange);

     // No. of records in file
     ReadInt( Header, 'NR=', FNumRecords ) ;

     { Fix files which accidentally lost their record count }
     if FNumRecords = 0 then begin
        NumBytesInFile := FileSeek( FileHandle, 0, 2 ) ;
        FNumRecords := (NumBytesInFile - SizeOf(Header)) div FNumRecordBytes ;
        end ;

     ReadFloat( Header, 'DT=', FScanInterval );

     ReadInt( Header, 'NZ=', FWCPNumZeroAvg ) ;

     { Read channel scaling data }

     for ch := 0 to FNumChannelsPerScan-1 do begin

         { Channels are mapped in ascending order by WCP for DOS (Version<6.0)
           and descending order by WinWCP. Data file Versions 6.1 and later
           have channel mapping explicitly saved in YO0= ... YO1 etc parameter}
         if (FVersion >= 6.0) or (FVersion = 0.0) then
            FChannelOffset[ch] := FNumChannelsPerScan - 1 - ch
         else FChannelOffset[ch] := ch ;

         ReadInt( Header, format('YO%d=',[ch]), FChannelOffset[ch] ) ;

         FChannelUnits[ch] := 'mV' ;
         ReadString( Header, format('YU%d=',[ch]) , FChannelUnits[ch] ) ;
         { Fix to avoid strings with #0 in them }
         if FChannelUnits[ch] = chr(0) then FChannelUnits[ch] := 'mV' ;

         FChannelName[ch] := format('ch%d',[ch]) ;
         ReadString( Header, format('YN%d=',[ch]), FChannelName[ch] ) ;
         { Fix to avoid strings with #0 in them }
         if FChannelName[ch] = chr(0) then FChannelName[ch] := '' ;

         ReadFloat( Header, format('YG%d=',[ch]), FChannelCalibrationFactor[ch]) ;

         FChannelGain[ch] := 1.0 ;
         //ReadFloat( Header, format('YAG%d=',[ch]), FChannelGain[ch]) ;

         { Zero level (in fixed mode) }
         FChannelZero[ch] := 0 ;
         ReadInt( Header, format('YZ%d=',[ch]), FChannelZero[ch]) ;
         { Start of zero level reference samples (-1 = fixed zero) }
         FChannelZeroAt[ch] := 0 ;
         ReadInt( Header, format('YR%d=',[ch]), FChannelZeroAt[ch]) ;

         { Special treatment for old WCP for DOS data files}
         if FVersion < 6.0 then begin
            { Remove 2048 offset from zero level }
            ChannelZero[ch] := FChannelZero[ch] {- 2048} ;
            { Decrement reference position because WinWCP samples start at 0}
            Dec(FChannelZeroAt[ch]) ;
            end ;
         end ;

     // Experiment identification line }
     ReadString( Header, 'ID=', FIdentLine ) ;

     for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
     FADCOffset := 0 ;
     UseTempFile := False ;

     end ;


function TADCDataFile.WCPSaveFileHeader : Boolean ;
// -------------------------------------------
// Save file header block to WCP data file,
// -------------------------------------------
const
     NumBytesPerSector = 512 ;
var
   Header : array[1..WCPMaxBytesInFileHeader] of char ;
   i,ch : Integer ;
   NumRecordDataSectors : Integer ;
begin

     Result := False ;
     if FileHandle < 0 then Exit ;

     for i := 1 to High(Header) do Header[i] := #0 ;

     // Size of header depends upon no. of channels in file
     FNumHeaderBytes := WCPNumBytesInFileHeader(FNumChannelsPerScan) ;

     FVersion := 9.0 ;
     AppendFloat( Header, 'VER=',FVersion );

     // No. input channels scanned
     AppendInt( Header, 'NC=', FNumChannelsPerScan ) ;

     // A/D sample value range
     AppendInt( Header, 'ADCMAX=', FMaxADCValue ) ;

     AppendInt( Header, 'NBH=', FNumHeaderBytes div NumBytesPerSector ) ;

     // Size of data record
     NumRecordDataSectors := FNumRecordDataBytes div NumBytesPerSector ;
     AppendInt( Header, 'NBD=', NumRecordDataSectors ) ;

     AppendFloat( Header, 'AD=',FADCVoltageRange);

     // No. of records in file
     AppendInt( Header, 'NR=', FNumRecords ) ;

     AppendFloat( Header, 'DT=', FScanInterval );

     AppendInt( Header, 'NZ=', FWCPNumZeroAvg ) ;

     { Save channel scaling data }
     for ch := 0 to FNumChannelsPerScan-1 do begin
         AppendInt( Header, format('YO%d=',[ch]), FChannelOffset[ch] ) ;
         AppendString( Header, format('YU%d=',[ch]) , FChannelUnits[ch] ) ;
         AppendString( Header, format('YN%d=',[ch]), FChannelName[ch] ) ;
         AppendFloat( Header, format('YG%d=',[ch]), FChannelCalibrationFactor[ch]) ;
       //  AppendFloat( Header, format('YAG%d=',[ch]), FChannelGain[ch]) ;
         AppendInt( Header, format('YZ%d=',[ch]), FChannelZero[ch]) ;
         AppendInt( Header, format('YR%d=',[ch]), FChannelZeroAt[ch]) ;
         end ;

     // Experiment identification line }
     AppendString( Header, 'ID=', FIdentLine ) ;

     FileSeek( FileHandle, 0, 0 ) ;
     if FileWrite( FileHandle, Header, FNumHeaderBytes ) <> FNumHeaderBytes then begin
        ShowMessage( ' File Header Write - Failed ' ) ;
        Exit ;
        end ;

     Result := True ;

     end ;


function TADCDataFile.WCPLoadRecordHeader(
         var WCPRecordHeaderOut : TWCPRecordHeader
         ) : Boolean ;
// --------------------------------------
// Load WCP data file record header block
// --------------------------------------
var
   FilePointer : Int64 ;
   cBuf : array[1..20] of char ;
   i,ch : Integer ;
   cRecID : array[0..WCPMaxRecordIdentChars-1] of char ;
   cRecType : Array[0..WCPMaxRecordTypeChars-1] of char ;
begin

     Result := True ;
     if FFileType <> ftWCP then Exit ;
     if FileHandle < 0 then Exit ;
     if (FRecordNum < 1) or (FRecordNum > FNumRecords) then Exit ;

     Result := False ;

     // Move file pointer to start of headet block
     FNumHeaderBytes := WCPNumBytesInFileHeader(FNumChannelsPerScan) ;
     FNumRecordBytes := WCPNumAnalysisBytesPerRecord(FNumChannelsPerScan)
                        + FNumChannelsPerScan*FNumScansPerRecord*2 ;
     FilePointer := (FRecordNum - 1)*FNumRecordBytes + FNumHeaderBytes ;
     FileSeek( FileHandle, FilePointer, 0 ) ;

     // Record status
     FileRead( FileHandle, cBuf, 8 );
     WCPRecordHeader.Status := '' ;
     for i := 1 to 8 do WCPRecordHeader.Status := WCPRecordHeader.Status + cBuf[i] ;
     if UpperCase(WCPRecordHeader.Status) <> 'REJECTED' then FWCPRecordAccepted := True
                                                        else FWCPRecordAccepted := False ;

     // Record type
     FileRead( FileHandle, cRecType, SizeOf(cRecType) ) ;
     WCPRecordHeader.RecType := cRecType ;
     FWCPRecordType := WCPRecordHeader.RecType ;

     // Group #
     FileRead( FileHandle, WCPRecordHeader.Number, sizeof(WCPRecordHeader.Number) ) ;
     FWCPRecordNumber := WCPRecordHeader.Number ;

     // Acquisition time
     FileRead( FileHandle, WCPRecordHeader.Time, sizeof(WCPRecordHeader.Time) ) ;
     FWCPRecordTime := WCPRecordHeader.Time ;

     // Scan interval
     FileRead( FileHandle, WCPRecordHeader.dt, sizeof(WCPRecordHeader.dt) ) ;
     FScanInterval := WCPRecordHeader.dt ;

     { Read channel A/D converter voltage range }
     FileRead(FileHandle,WCPRecordHeader.ADCVoltageRange,sizeof(WCPRecordHeader.ADCVoltageRange) ) ;
     for ch := 0 to FNumChannelsPerScan-1 do begin
         if (FVersion < 6.0) or (WCPRecordHeader.ADCVoltageRange[ch]=0.0) then
            WCPRecordHeader.ADCVoltageRange[ch] := WCPRecordHeader.ADCVoltageRange[0] ;
         FChannelADCVoltageRange[ch] := WCPRecordHeader.ADCVoltageRange[0] ;
         FChannelGain[ch] := FChannelADCVoltageRange[0] /
                             WCPRecordHeader.ADCVoltageRange[ch] ;
         FChannelScale[ch] := ADCScale( ch ) ;
         end ;

     { Read record ident text }
     FileRead( FileHandle, cRecID, SizeOf(cRecID) );
     WCPRecordHeader.Ident := cRecID ;

     { Read Analysis block }
     FileRead( FileHandle,
               WCPRecordHeader.Value,
               sizeof(single)*Max(FNumChannelsPerScan,8)*WCPMaxAnalysisVariables ) ;

     if WCPRecordHeader.Value[0] > 0.0 then WCPRecordHeader.AnalysisAvailable := True
                                       else WCPRecordHeader.AnalysisAvailable := False ;

     // Get type of fitted equation
     WCPRecordHeader.EqnType := TEqnType(Round(WCPRecordHeader.Value[WCPvFitEquation])) ;
     WCPRecordHeader.FitCursor0 := Round(WCPRecordHeader.Value[WCPvFitCursor0]) ;
     WCPRecordHeader.FitCursor1 := Round(WCPRecordHeader.Value[WCPvFitCursor1]) ;
     WCPRecordHeader.FitCursor2 := Round(WCPRecordHeader.Value[WCPvFitCursor2]) ;
     WCPRecordHeader.FitChan := Round(WCPRecordHeader.Value[WCPvFitChan]) ;

     // Copy record details in values array
     WCPRecordHeader.Value[WCPvRecord] := RecordNum ;
     WCPRecordHeader.Value[WCPvGroup] := WCPRecordHeader.Number ;
     WCPRecordHeader.Value[WCPvTime] := WCPRecordHeader.Time ;

     WCPRecordHeaderOut := WCPRecordHeader ;

     Result := True ;

     end ;


function TADCDataFile.WCPSaveRecordHeader(
         var WCPRecordHeaderIn : TWCPRecordHeader
         ) : Boolean ;
{ -------------------------------------------------------
  Write a WCP format digital signal record header to file
  -------------------------------------------------------}
var
   cRecID : Array[0..WCPMaxRecordIdentChars] of char ;
   cStatus : Array[0..WCPMaxRecordStatusChars] of char ;
   cRecType : Array[0..WCPMaxRecordTypeChars] of char ;
   ch,FilePointer : Integer ;
begin

     // Update internal record header
     WCPRecordHeader := WCPRecordHeaderIn ;

     // Move file pointer to start of headet block
     FNumHeaderBytes := WCPNumBytesInFileHeader(FNumChannelsPerScan) ;
     FNumRecordBytes := WCPNumAnalysisBytesPerRecord(FNumChannelsPerScan)
                        + FNumChannelsPerScan*FNumScansPerRecord*2 ;
     FilePointer := (FRecordNum - 1)*FNumRecordBytes + FNumHeaderBytes ;
     FileSeek( FileHandle, FilePointer, 0 ) ;

    // Copy record details in values array
    WCPRecordHeader.Value[WCPvRecord] := FRecordNum ;

     // Copy equation data to values table
    WCPRecordHeader.Value[WCPvFitEquation] := Integer(WCPRecordHeader.EqnType) ;
    WCPRecordHeader.Value[WCPvFitCursor0] := WCPRecordHeader.FitCursor0 ;
    WCPRecordHeader.Value[WCPvFitCursor1] := WCPRecordHeader.FitCursor1 ;
    WCPRecordHeader.Value[WCPvFitCursor2] := WCPRecordHeader.FitCursor2 ;
    WCPRecordHeader.Value[WCPvFitChan] := WCPRecordHeader.FitChan ;

     { Write record header block to file }
     FileSeek( FileHandle,
               (RecordNum-1)*FNumRecordBytes + FNumHeaderBytes,
               0 ) ;

     // Record ACCEPTED/REJECTED status string (8 chars)
     if FWCPRecordAccepted then WCPRecordHeader.Status :=  'ACCEPTED'
                           else WCPRecordHeader.Status :=  'REJECTED' ;
     StrCopy(cStatus,PChar(LeftStr(WCPRecordHeader.Status,WCPMaxRecordStatusChars))) ;
     FileWrite( FileHandle, cStatus, WCPMaxRecordStatusChars ) ;

     // Record type string (4 chars)
     StrCopy(cRecType,PChar(LeftStr(WCPRecordHeader.RecType,WCPMaxRecordTypeChars))) ;
     FileWrite( FileHandle, cRecType, WCPMaxRecordTypeChars ) ;

     // Group #
     WCPRecordHeader.Number :=  FWCPRecordNumber ;
     WCPRecordHeader.Value[WCPvGroup] := WCPRecordHeader.Number ;
     FileWrite( FileHandle, WCPRecordHeader.Number, sizeof(WCPRecordHeader.Number) ) ;

     // record acquisition time
     WCPRecordHeader.Time := FWCPRecordTime ;
     WCPRecordHeader.Value[WCPvTime] := WCPRecordHeader.Time ;
     FileWrite( FileHandle, WCPRecordHeader.Time, sizeof(WCPRecordHeader.Time) ) ;

     // Sampling interval
     WCPRecordHeader.dt := FScanInterval ;
     FileWrite( FileHandle, WCPRecordHeader.dt, sizeof(WCPRecordHeader.dt) ) ;

     { Write A/D voltage range for each channel }
     // Note this voltage range is scaled by current setting of FChannelGain
     // This means that records can have different ADCVoltageRange values
     for ch := 0 to FNumChannelsPerScan-1 do begin
         WCPRecordHeader.ADCVoltageRange[ch] := FChannelADCVoltageRange[ch] / FChannelGain[ch] ;
         end ;
     FileWrite( FileHandle,WCPRecordHeader.ADCVoltageRange,sizeof(single)*FNumChannelsPerScan) ;

     { Write record ident line }
     StrCopy(cRecID,PChar(LeftStr(WCPRecordHeader.Ident,WCPMaxRecordIdentChars))) ;
     FileWrite( FileHandle, cRecID, WCPMaxRecordIdentChars ) ;

     { Write Analysis variables }
     FileWrite( FileHandle, WCPRecordHeader.Value,sizeof(single)*Max(FNumChannelsPerScan,8)*WCPMaxAnalysisVariables ) ;

     Result := True ;

     end ;


function TADCDataFile.WCPNumAnalysisBytesPerRecord(
         NumChannels : Integer ) : Integer ;
//
// Return no. of bytes in analysis block
// --------------------------------------
begin
     Result := (((NumChannels-1) div 8)+1)*1024 ;
     end ;

function TADCDataFile.WCPNumBytesInFileHeader(
         NumChannels : Integer ) : Integer ;
//
// Return no. of bytes in header block
// --------------------------------------
begin
     Result := (((NumChannels-1) div 8)+1)*1024 ;
     end ;


function TADCDataFile.CDRLoadFileHeader : Boolean ;
// -------------------------------------------
// Read file header block from CDR data file,
// -------------------------------------------
const
   NumSamplesPerCDRRecord = 512 ;
   NumCDRFileHeaderBytes = 1024 ;
   msToSecs = 0.001 ;

type

    TCDRHeader = packed record         { DOS CDR data file header }
            Nrecords : SmallInt ;
            MaxRecords : SmallInt ;
            RecordingTime : single ;
            Cell : array[0..77] of char ;
            FileName : array[0..11] of char ;
            dt : single ;
            BitCurrent : single ;
            RangeVolts : single ;
            YUnits : array[0..1] of char ;
            TUnits : array[0..1] of char ;
            CalCurrent : single ;
            CalTime : single ;
            iCalCurrent : SmallInt ;
            iCalRecord : SmallInt ;
            iCalCursor : SmallInt ;
            GainCurrent : single ;
            iZeroLevel : SmallInt ;
            TriggerLevel : single ;
            TriggerTime : single ;
            DeadTime : single ;
            RunningMean : single ;
            nEvents : SmallInt ;
            TypeList : array[0..29] of char ;
            nTypes : SmallInt ;
            InterfaceCard : SmallInt ;
            Signature : array[0..3] of char ;
            end ;

var
   CDRHeader : TCDRHeader ;
   ch,i : Integer ;
begin

     Result := False ;

     FileSeek( FileHandle, 0, 0 ) ;
     if FileRead(FileHandle,CDRHeader,Sizeof(CDRHeader))
        <> Sizeof(CDRHeader) then begin
        ShowMessage( FileName + ' - CDR Header unreadable' ) ;
        Exit ;
        end ;

     FNumChannelsPerScan := 1 ;
     FFloatingPointSamples := False ;
     FNumBytesPerSample := 2 ;

     FNumScansPerRecord := CDRHeader.nRecords*NumSamplesPerCDRRecord ;
     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
     FNumRecords := 1 ;

     // A/D sample value range
     FMaxADCValue := 2047 ;
     FMinADCValue := -FMaxADCValue - 1 ;

     FNumHeaderBytes := NumCDRFileHeaderBytes ;
     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordAnalysisBytes := 0 ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

     FScanInterval := CDRHeader.dt * msToSecs ;
     FADCVoltageRange := CDRHeader.RangeVolts ;

     { Experiment ID }
     FIdentLine := '' ;
     for i := 0 to High(CDRHeader.Cell) do FIdentLine := FIdentLine + CDRHeader.Cell[i] ;

     { Channel units and scaling factors }
     FChannelName[0] := 'Ch0' ;
     FChannelZero[0] := Max(Min(CDRHeader.iZeroLevel - 2048,FMaxADCValue),FMinADCValue) ;
     FChannelZeroAt[0] := -1 ;
     FChannelScale[0] := CDRHeader.BitCurrent ;
     FChannelCalibrationFactor[0] := FADCVoltageRange /
                                      ( FChannelScale[0] * (FMaxADCValue+1) ) ;
     FChannelGain[0] := 1. ;
     FChannelADCVoltageRange[0] := FADCVoltageRange ;

        { Signal units }
     FChannelUnits[0] := '' ;
     for i := 0 to High(CDRHeader.YUnits) do
         FChannelUnits[0] := FChannelUnits[0] + CDRHeader.YUnits[i] ;

     for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
     FADCOffset := 2048 ;
     UseTempFile := False ;

     Result := True ;

     end ;


function TADCDataFile.SPALoadFileHeader : Boolean ;
// -------------------------------------------
// Read file header block from SPAN (.SPA) data file,
// -------------------------------------------
const
   NumSpanFileHeaderBytes = 512*19 ;
   msToSecs = 0.001 ;
var
   SPANHeader : Array[0..511] of Char ;
   Header : Array[0..1023] of Char ;
   i,j,ch : Integer ;
   Value : Single ;
   YUnits : String ;
begin

     Result := False ;

     // Load SPAN file header data
     FileSeek( FileHandle, 0, 0 ) ;
     if FileRead( FileHandle, SPANHeader, SizeOf(SPANHeader) )
        <> SizeOf(SPANHeader) then Exit ;

     // Convert to a format that can be handled by new ReadInt() etc...
     j := 0 ;
     for i:= 0 to High(Header) do Header[i] := #0 ;
     for i := 0 to High(SPANHeader) do begin
         if SPANHeader[i] = '\' then begin
            Header[j] := #13 ;
            Inc(j) ;
            Header[j] := #10 ;
            Inc(j) ;
            end
         else begin
            Header[j] := SPANHeader[i] ;
            Inc(j) ;
            end ;
         end ;

     { Get default size of file header }
     FNumHeaderBytes := NumSpanFileHeaderBytes ;

     FMaxADCValue := 2047 ;
     FMinADCValue := -FMaxADCValue - 1 ;

     FNumChannelsPerScan := 2 ;
     FFloatingPointSamples := False ;
     FNumBytesPerSample := 2 ;
     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;

     ReadFloat( Header, 'NR=', Value ) ;
     FNumRecords := Round(Value) ;

     ReadFloat( Header, 'NPR=', Value ) ;
     FNumScansPerRecord := Round(Value) ;

     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordAnalysisBytes := 0 ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

     ReadFloat( Header, 'DT=', FScanInterval ) ;
     FScanInterval := FScanInterval*msToSecs ;
     ReadFloat( Header, 'AD=', FADCVoltageRange ) ;

     for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
     FADCOffset := 2048 ;
     UseTempFile := False ;

     ReadString( Header, 'YU1=', YUnits) ;
     FChannelName[0] := 'AC' ;
     FChannelName[1] := 'DC' ;
     for ch := 0 to 1 do begin
         FChannelOffset[ch] := ch ;
         FChannelUnits[ch] := YUnits ;
         ReadFloat( Header, format('YS%d=',[ch+1]) , FChannelScale[ch] ) ;
         FChannelGain[ch] := 1.0 ;
         ReadFloat( Header, format('IY%d=',[ch+1]), Value ) ;
         FChannelZero[ch] := Round(Value) - FADCOffset ;
         FChannelZeroAt[ch] := -1 ;
         FChannelADCVoltageRange[ch] :=  FADCVoltageRange ;
         FChannelCalibrationFactor[ch] := CalibFactor( ch ) ;
         end ;

     ReadString( Header, 'ID=', FIdentLine ) ;

     { Clear Marker list }
     FMarkerList.Clear ;


     Result := True ;

     end ;


function TADCDataFile.SCALoadFileHeader : Boolean ;
// -------------------------------------------
// Read file header block from SCAN (.SCA) data file,
// -------------------------------------------
const
   NumScanFileHeaderBytes = 512 ;
   msToSecs = 0.001 ;
var
   SCANHeader : Array[0..511] of Char ;
   Header : Array[0..1023] of Char ;
   i,j,ch : Integer ;
   Value : Single ;
begin

     Result := False ;

     // Load SCAN file header data
     FileSeek( FileHandle, 0, 0 ) ;
     if FileRead( FileHandle, SCANHeader, SizeOf(SCANHeader) )
        <> SizeOf(SCANHeader) then Exit ;

     // Convert to a format that can be handled by new ReadInt() etc...
     j := 0 ;
     for i:= 0 to High(Header) do Header[i] := #0 ;
     for i := 0 to High(SCANHeader) do begin
         if SCANHeader[i] = '\' then begin
            Header[j] := #13 ;
            Inc(j) ;
            Header[j] := #10 ;
            Inc(j) ;
            end
         else begin
            Header[j] := SCANHeader[i] ;
            Inc(j) ;
            end ;
         end ;

     { Get default size of file header }
     FNumHeaderBytes := NumScanFileHeaderBytes ;

     FMaxADCValue := 2047 ;
     FMinADCValue := -FMaxADCValue - 1 ;

     FNumChannelsPerScan := 1 ;
     FFloatingPointSamples := False ;
     FNumBytesPerSample := 2 ;
     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;

     ReadFloat( Header, 'NF=', Value ) ;
     FNumRecords := Round(Value) ;

     ReadFloat( Header, 'NBD=', Value ) ;
     FNumScansPerRecord := Round(Value)*256 ;

     ReadFloat( Header, 'NBA=', Value ) ;
     FNumRecordAnalysisBytes := Round(Value)*512 ;
     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

     ReadFloat( Header, 'DT=', FScanInterval ) ;
     FScanInterval := FScanInterval*msToSecs ;
     ReadFloat( Header, 'AD=', FADCVoltageRange ) ;

     for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
     FADCOffset := 2048 ;
     UseTempFile := False ;

     ReadString( Header, 'CU=', FChannelUnits[0]) ;
     FChannelName[0] := 'Ch0' ;
     FChannelOffset[0] := 0 ;
     ReadFloat( Header, 'BC=' , FChannelScale[0] ) ;
     FChannelGain[0] := 1.0 ;
     ReadFloat( Header, 'IZ=', Value ) ;
     FChannelZero[0] := Round(Value) - FADCOffset ;
     FChannelZeroAt[0] := -1 ;
     FChannelADCVoltageRange[0] :=  FADCVoltageRange ;
     FChannelCalibrationFactor[0] := CalibFactor( 0 ) ;

     ReadString( Header, 'ID=', FIdentLine ) ;

     { Clear Marker list }
     FMarkerList.Clear ;

     Result := True ;

     end ;


function TADCDataFile.EDRLoadFileHeader : Boolean ;
// -------------------------------------------
// Read file header block from EDR data file
// -------------------------------------------
var
   Header : array[1..EDRFileHeaderSize] of char ;
   i,ch : Integer ;
   NumSamplesInFile : Integer ;
   NumMarkers : Integer ;
   MarkerTime : Single ;
   MarkerText : String ;
begin

     Result := False ;

     // Load file header data
     FileSeek( FileHandle, 0, 0 ) ;
     if FileRead( FileHandle, Header, Sizeof(Header) )<> Sizeof(Header) then Exit ;

     { Get default size of file header }
     FNumHeaderBytes := EDRFileHeaderSize ;
     { Get size of file header for this file }
     ReadInt( Header, 'NBH=', FNumHeaderBytes ) ;
     if FNumHeaderBytes <> EDRFileHeaderSize then begin
        ShowMessage( 'File header size mismatch' ) ;
        end ;

     ReadFloat( Header, 'VER=',FVersion );

     FMaxADCValue := 0 ;
     ReadInt( Header, 'ADCMAX=', FMaxADCValue ) ;
     if MaxADCValue = 0 then FMaxADCValue := 2047 ;
     FMinADCValue := -FMaxADCValue - 1 ;

     ReadInt( Header, 'NC=', FNumChannelsPerScan ) ;
     FFloatingPointSamples := False ;
     FNumBytesPerSample := 2 ;
     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;

     ReadInt( Header, 'NP=', NumSamplesInFile ) ;
     FNumScansPerRecord := NumSamplesInFile div FNumChannelsPerScan ;
     FNumRecords := 1 ;
     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordAnalysisBytes := 0 ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

     ReadFloat( Header, 'AD=',FADCVoltageRange);

     ReadFloat( Header, 'DT=', FScanInterval );

     for ch := 0 to FNumChannelsPerScan-1 do begin

         ReadInt( Header, format('YO%d=',[ch]), FChannelOffset[ch]) ;

         FChannelUnits[ch] := '' ;
         ReadString( Header, format('YU%d=',[ch]) , FChannelUnits[ch] ) ;
         { Fix to avoid strings with #0 in them }
         if FChannelUnits[ch] = chr(0) then FChannelUnits[ch] := '' ;

         FChannelName[ch] := 'Ch' + IntToStr(ch) ;
         ReadString( Header, format('YN%d=',[ch]), FChannelName[ch] ) ;
         { Fix to avoid strings with #0 in them }
         if FChannelName[ch] = chr(0) then FChannelName[ch] := '' ;

         ReadFloat( Header, format('YCF%d=',[ch]), FChannelCalibrationFactor[ch]) ;
         ReadFloat( Header, format('YAG%d=',[ch]), FChannelGain[ch]) ;
         FChannelADCVoltageRange[ch] := FADCVoltageRange ;
         FChannelScale[ch] := ADCScale( ch ) ;

         ReadInt( Header, format('YZ%d=',[ch]), FChannelZero[ch]) ;
         ReadInt( Header, format('YR%d=',[ch]), FChannelZeroAt[ch]) ;
         end ;

     { Experiment identification line }
     ReadString( Header, 'ID=', FIdentLine ) ;

     { Read Markers }
     NumMarkers := 0 ;
     ReadInt( Header, 'MKN=', NumMarkers ) ;
     FMarkerList.Clear ;
     for i := 0 to NumMarkers-1 do begin
         ReadFloat( Header, format('MKTIM%d=',[i]), MarkerTime ) ;
         ReadString( Header, format('MKTXT%d=',[i]), MarkerText ) ;
         FMarkerList.AddObject( MarkerText, TObject(MarkerTime) ) ;
         end ;

    { Event detector parameters }
    ReadInt( Header, 'DETCH=', FEDREventDetectorChannel ) ;
    ReadInt( Header, 'DETRS=', FEDREventDetectorRecordSize ) ;
    ReadFloat( Header, 'DETYT=', FEDREventDetectorYThreshold ) ;
    ReadFloat( Header, 'DETTT=', FEDREventDetectorTThreshold ) ;
    ReadFloat( Header, 'DETDD=', FEDREventDetectorDeadTime ) ;
    ReadFloat( Header, 'DETBA=', FEDREventDetectorBaselineAverage ) ;
    ReadFloat( Header, 'DETPT=', FEDREventDetectorPreTriggerPercentage ) ;
    ReadFloat( Header, 'DETAW=', FEDREventDetectorAnalysisWindow ) ;

    ReadInt( Header, 'VARRS=', FEDRVarianceRecordSize ) ;
    ReadInt( Header, 'VAROV=', FEDRVarianceRecordOverlap ) ;
    ReadFloat( Header, 'VARTR=', FEDRVarianceTauRise ) ;
    ReadFloat( Header, 'VARTD=', FEDRVarianceTauDecay ) ;

    ReadFloat( Header, 'UNITC=', FEDRUnitCurrent ) ;
    ReadFloat( Header, 'DWTTH=', FEDRDwellTimesThreshold ) ;

    { Name of any associated WCP data file }
    FEDRWCPFileName := '' ;
    ReadString( Header, 'WCPFNAM=', FEDRWCPFileName ) ;

    { Save the original file backed up flag }
    ReadLogical( Header, 'BAK=', FEDRBackedUp ) ;

    for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
    FADCOffset := 0 ;
    UseTempFile := False ;

    Result := True ;
    end ;


function TADCDataFile.EDRSaveFileHeader : Boolean ;
// -------------------------------------------
// Write file header block to EDR data file
// -------------------------------------------
var
   Header : array[1..EDRFileHeaderSize] of char ;
   i,ch : Integer ;
   NumSamplesInFile : Integer ;
   MarkerTime : Single ;
   MarkerText : String ;
begin

     Result := False ;
     if FileHandle < 0 then Exit ;

     for i := 1 to High(Header) do Header[i] := #0 ;

     FNumHeaderBytes := EDRFileHeaderSize ;
     AppendInt( Header, 'NBH=', FNumHeaderBytes ) ;

     AppendFloat( Header, 'VER=',FVersion );

     AppendInt( Header, 'ADCMAX=', FMaxADCValue ) ;

     AppendInt( Header, 'NC=', FNumChannelsPerScan ) ;

     NumSamplesInFile := FNumScansPerRecord * FNumChannelsPerScan ; ;
     AppendInt( Header, 'NP=', NumSamplesInFile ) ;

     AppendFloat( Header, 'AD=',FADCVoltageRange);

     AppendFloat( Header, 'DT=', FScanInterval );

     for ch := 0 to FNumChannelsPerScan-1 do begin
         AppendInt( Header, format('YO%d=',[ch]), FChannelOffset[ch]) ;
         AppendString( Header, format('YU%d=',[ch]) , FChannelUnits[ch] ) ;
         AppendString( Header, format('YN%d=',[ch]), FChannelName[ch] ) ;
         AppendFloat( Header, format('YCF%d=',[ch]), FChannelCalibrationFactor[ch]) ;
         AppendFloat( Header, format('YAG%d=',[ch]), FChannelGain[ch]) ;
         AppendFloat( Header, format('YS%d=',[ch]), FChannelScale[ch] ) ;
         AppendInt( Header, format('YZ%d=',[ch]), FChannelZero[ch]) ;
         AppendInt( Header, format('YR%d=',[ch]), FChannelZeroAt[ch]) ;
         end ;

     { Experiment identification line }
     AppendString( Header, 'ID=', FIdentLine ) ;

     { Read Markers }
     AppendInt( Header, 'MKN=', FMarkerList.Count ) ;
     FMarkerList.Clear ;
     for i := 0 to FMarkerList.Count-1 do begin
         MarkerTime := Single(FMarkerList.Objects[i]) ;
         MarkerText := FMarkerList.Strings[i] ;
         AppendFloat( Header, format('MKTIM%d=',[i]), MarkerTime ) ;
         AppendString( Header, format('MKTXT%d=',[i]), MarkerText ) ;
         end ;

    { Event detector parameters }
    AppendInt( Header, 'DETCH=', FEDREventDetectorChannel ) ;
    AppendInt( Header, 'DETRS=', FEDREventDetectorRecordSize ) ;
    AppendFloat( Header, 'DETYT=', FEDREventDetectorYThreshold ) ;
    AppendFloat( Header, 'DETTT=', FEDREventDetectorTThreshold ) ;
    AppendFloat( Header, 'DETDD=', FEDREventDetectorDeadTime ) ;
    AppendFloat( Header, 'DETBA=', FEDREventDetectorBaselineAverage ) ;
    AppendFloat( Header, 'DETPT=', FEDREventDetectorPreTriggerPercentage ) ;
    AppendFloat( Header, 'DETAW=', FEDREventDetectorAnalysisWindow ) ;

    AppendInt( Header, 'VARRS=', FEDRVarianceRecordSize ) ;
    AppendInt( Header, 'VAROV=', FEDRVarianceRecordOverlap ) ;
    AppendFloat( Header, 'VARTR=', FEDRVarianceTauRise ) ;
    AppendFloat( Header, 'VARTD=', FEDRVarianceTauDecay ) ;

    AppendFloat( Header, 'UNITC=', FEDRUnitCurrent ) ;
    AppendFloat( Header, 'DWTTH=', FEDRDwellTimesThreshold ) ;

    { Name of any associated WCP data file }
    AppendString( Header, 'WCPFNAM=', FEDRWCPFileName ) ;

    { Save the original file backed up flag }
    AppendLogical( Header, 'BAK=', FEDRBackedUp ) ;

    FileSeek( FileHandle, 0, 0 ) ;
    if FileWrite( FileHandle, Header, Sizeof(Header) )
       <> Sizeof(Header) then begin
       ShowMessage( FFileName + ' File Header Write - Failed ' ) ;
       Exit ;
       end ;

    for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
    FADCOffset := 0 ;
    UseTempFile := False ;

    Result := True ;

    end ;


function TADCDataFile.SCDLoadFileHeader : Boolean ;
// -------------------------------------------
// Read file header block from SCD data file
// -------------------------------------------
const
     NumSamplesPerSCDRecord = 256 ;
     NumSCDFileHeaderBytes = 8192 ;
var
   Header : Array[0..511] of char ;
   ch,i : Integer ;
begin

     { Read file header }
     for i := 0 to High(Header) do Header[i] := #0 ;
     FileSeek( FileHandle, 0, 0 ) ;
     if FileRead( FileHandle, Header, SizeOf(Header) ) <> SizeOf(Header) then begin
        ShowMessage( FFileName + ' : Error reading file header!' ) ;
        Result := False ;
        Exit ;
        end ;

     // A/D sample value range
     FMaxADCValue := 2047 ;
     FMinADCValue := -FMaxADCValue - 1 ;

     FNumChannelsPerScan := 1 ;
     FFloatingPointSamples := False ;
     FNumBytesPerSample := 2 ;

     ReadInt( Header, 'NP=', FNumScansPerRecord ) ;
     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
     FNumRecords := 1 ;

     ReadFloat( Header, 'AD=', FADCVoltageRange ) ;

     FNumHeaderBytes := NumSCDFileHeaderBytes ;
     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordAnalysisBytes := 0 ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

     { Sampling interval (note conversion ms->s) }
     ReadFloat( Header, 'DT=', FScanInterval ) ;
     FScanInterval := FScanInterval*0.001 ;

     { Experiment ID }
     ReadString( Header, 'ID=', FIdentLine ) ;

     { Channel units and scaling factors }
     FChannelName[0] := 'Im' ;
     FChannelUnits[0] := 'pA' ;
     { Zero level }
     ReadInt( Header, 'YZ0=', FChannelZero[0] ) ;
     FChannelZero[0] := FChannelZero[0] - 2048 ;
     { Scaling factor }
     ReadFloat( Header, 'YS0', FChannelScale[0] ) ;
     FChannelADCVoltageRange[0] := FADCVoltageRange ;
     FChannelCalibrationFactor[0] := FADCVoltageRange / (FChannelScale[0] * (FMaxADCValue+1)) ;
     ChannelGain[0] := 1. ;

     for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
     FADCOffset := 2048 ;
     UseTempFile := False ;

     Result := True ;

     end ;


function TADCDataFile.WCDLoadFileHeader : Boolean ;
// -------------------------------------------
// Read file header block from WinCDR V2.X WCD file
// -------------------------------------------

const
     NumBytesPerSector = 512 ;
     NumWCDFileHeaderBytes = 512 ;
var
   Header : array[1..NumWCDFileHeaderBytes] of char ;
   i,ch : Integer ;
   NumSamplesInFile : Integer ;

begin

     Result := False ;

     FNumHeaderBytes := NumWCDFileHeaderBytes ;

     { Read file header }
     FileSeek( FileHandle, 0, 0 ) ;
     for i := 1 to High(Header) do Header[i] := #0 ;
     if FileRead( FileHandle, Header, FNumHeaderBytes ) <> FNumHeaderBytes then begin
        ShowMessage( FFileName + ' : Error reading file header!' ) ;
        Exit ;
        end ;

     ReadInt( Header, 'NC=', FNumChannelsPerScan ) ;
     ReadInt( Header, 'NP=', NumSamplesInFile ) ;
     FFloatingPointSamples := False ;
     FNumBytesPerSample := 2 ;

     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
     FNumScansPerRecord := NumSamplesInFile div FNumChannelsPerScan ;
     FNumRecords := 1 ;

     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordAnalysisBytes := 0 ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

     { Sampling interval (note conversion ms->s) }
     ReadFloat( Header, 'DT=', FScanInterval ) ;
     FScanInterval := FScanInterval*0.001 ;

     ReadFloat( Header, 'AD=',FADCVoltageRange);

     ReadFloat( Header, 'VER=',FVersion );

     // A/D sample value range
     FMaxADCValue := 0 ;
     ReadInt( Header, 'ADCMAX=', FMaxADCValue ) ;
     if FMaxADCValue = 0 then FMaxADCValue := 2047 ;
     FMinADCValue := -FMaxADCValue - 1 ;

     for ch := 0 to FNumChannelsPerScan-1 do begin
         ReadInt( Header, format('YO%d=',[ch]), FChannelOffset[ch]) ;
         ReadString( Header, format('YU%d=',[ch]) , FChannelUnits[ch] ) ;
         ReadString( Header, format('YN%d=',[ch]), FChannelName[ch] ) ;
         ReadFloat( Header, format('YG%d=',[ch]), FChannelCalibrationFactor[ch]) ;
         ReadFloat( Header, format('YAG%d=',[ch]), FChannelGain[ch]) ;
         FChannelCalibrationFactor[ch] := FChannelCalibrationFactor[ch] /
                                          (FChannelGain[ch]*1000. ) ;
         FChannelScale[ch] := ADCScale( ch ) ;
         ReadInt( Header, format('YZ%d=',[ch]), FChannelZero[ch]) ;
         ReadInt( Header, format('YR%d=',[ch]), FChannelZeroAt[ch]) ;
         FChannelADCVoltageRange[ch] := FADCVoltageRange ;
         end ;

     // Experiment identification line }
     ReadString( Header, 'ID=', FIdentLine ) ;

     for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
     FADCOffset := 0 ;
     UseTempFile := False ;

     Result := True ;

     end ;


function TADCDataFile.LDTLoadFileHeader : Boolean ;
// -------------------------------------------
// Read file header block from QuB LDT file
// -------------------------------------------
const
     usToSecs = 1E-6 ;
var
     Done : Boolean ;
     SegmentPointer : Integer ;
     LDTFileHeader : TLDTFileHeader ;
     LDTSegmentHeader : TLDTSegmentHeader ;
begin

     Result := False ;

     // Load file header
     FileSeek( FileHandle, 0, 0 ) ;
     if FileRead(FileHandle,LDTFileHeader,Sizeof(LDTFileHeader))
        <> Sizeof(LDTFileHeader) then begin
        ShowMessage( FileName + ' - Header unreadable' ) ;
        Exit ;
        end ;

     FNumChannelsPerScan := 1 ;
     FNumBytesPerSample := 0 ;
     FFloatingPointSamples := False ;
     FNumBytesPerSample := 0 ;


     FScanInterval := LDTFileHeader.SamplingInterval * usToSecs ;
     FADCVoltageRange := 10.0 ;

     { Experiment ID }
     FIdentLine := '' ;

     { Channel units and scaling factors }
     FChannelName[0] := 'Im' ;
     FChannelZero[0] := 0 ;
     FChannelScale[0] := 100.0/LDTFileHeader.Scaling ;
     FChannelGain[0] := 1. ;
     FChannelADCVoltageRange[0] := FADCVoltageRange ;
     FChannelCalibrationFactor[0] := CalibFactor(0) ;
     FChannelUnits[0] := 'pA' ;

     Done := False ;
     FNumRecords := 0 ;
     SegmentPointer := FileSeek( FileHandle, SizeOf(LDTFileHeader), 0 ) ;
     while not Done do begin

         // Read segment header
         if FileRead(FileHandle,LDTSegmentHeader,SizeOf(LDTSegmentHeader))
            <> SizeOf(LDTSegmentHeader) then Done := True ;
         if LDTSegmentHeader.NumSamples <= 0 then Done := True ;

         if not Done then begin
              Inc(FNumRecords) ;
              SegmentPointer := SegmentPointer
                                + SizeOf(LDTSegmentHeader)
                                + LDTSegmentHeader.NumSamples*FNumBytesPerSample ;
              end ;
         end ;
     end ;


function TADCDataFile.ABFLoadFileHeader : Boolean ;
// -------------------------------------------
// Read file header block from Axon ABF file
// -------------------------------------------
Const
    ABFV18HeaderSize = 6144 ;
var
     pc6Header : TABF ;
     FileType : String ;
     i : Integer ;
     ch : Integer ;
     pcChan : Integer ;
     NumDataBytes : Integer ;
     MaxValue : Array[0..ChannelLimit] of Single ;
     FPValue : Single ;
begin

    // Read header block as ABF file header (PClamp V6 and later)
    FileSeek( FileHandle, 0, 0 ) ;
    outputdebugString(PChar(format('%d',[Sizeof(pc6Header)]))) ;

    if FileRead(FileHandle,pc6Header,Sizeof(pc6Header)) < 2048 then begin
       ShowMessage('File size too small (<2048 bytes) to be an ABF file!') ;
       Exit ;
       end ;

    { Check file type }
    FileType := '' ;
    for i := 1 to 4 do FileType := FileType + pc6Header.FileType[i] ;

    if pc6Header.OperationMode = 3 then FABFAcquisitionMode := ftGapFree
                                   else FABFAcquisitionMode := ftEpisodic ;

    { pClamp V6 data file }
    FNumChannelsPerScan := Max(pc6Header.ADCNumChannels,1) ;
    FNumBytesPerSample := 2 ;
    FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;

    FScanInterval := pc6Header.ADCSampleInterval*1E-6*FNumChannelsPerScan ;
    FADCVoltageRange := pc6Header.ADCRange ;

    //FADCScale := (2.*pc6Header.ADCResolution)/((FMaxADCValue+1)*2.0) ;
    FMaxADCValue := pc6Header.ADCResolution - 1 ;
    FMinADCValue := -pc6Header.ADCResolution ;

    FIdentLine := '' ;
    for i := 1 to 56 do FIdentLine := FIdentLine + pc6Header.FileComment[i] ;

    { Channel scaling/units information }
    for ch := 0 to FNumChannelsPerScan-1 do begin

        pcChan := pc6Header.ADCSamplingSeq[ch] ;
        FChannelOffset[ch] := ch ;

        FChannelCalibrationFactor[ch] := pc6Header.InstrumentScaleFactor[pcChan]
                                         * pc6Header.SignalGain[pcChan]
                                         * pc6Header.ProgrammableGain[pcChan] ;

        { Add "AddIt" gain if in use for this channel }
        if pc6Header.FileVersionNumber > 1.5 then begin
           // Use V1.8 telegraph data
           if pc6Header.nTelegraphEnable[pcChan] <> 0 then begin
              FChannelCalibrationFactor[ch] := FChannelCalibrationFactor[ch]
                                               * pc6Header.fTelegraphAddItGain[pcChan]
              end ;
           end
        else begin
           // V1.5 or earlier
           if (pc6Header.AutoSampleADCNum = pcChan) and
              (pc6Header.AutosampleAdditGain <> 0) then begin
              FChannelCalibrationFactor[ch] := FChannelCalibrationFactor[ch]
                                               * pc6Header.AutosampleAdditGain ;
              end ;
           end ;

        if FChannelCalibrationFactor[ch] = 0. then FChannelCalibrationFactor[ch] := 1. ;

        FChannelGain[ch] := 1. ;
        FChannelADCVoltageRange[ch] := FADCVoltageRange ;

        FChannelScale[ch] := ADCScale( ch ) ;

	      FChannelZero[ch] := 0 ;
        FChannelUnits[ch] := '' ;
        for i := 1 to 4 do FChannelUnits[ch] := FChannelUnits[ch] +
                                                pc6Header.ADCUnits[pcChan,i] ;
        FChannelName[ch] := '' ;
        for i := 1 to 4 do FChannelName[ch] := FChannelName[ch] +
                                               pc6Header.ADCChannelName[pcChan,i] ;
        end ;

    { Get byte offset of data section }
     FNumHeaderBytes :=  pc6Header.DataSectionPtr*512 ;
     FNumScansPerRecord := pc6Header.NumSamplesPerEpisode div FNumChannelsPerScan ;
     FNumRecords := pc6Header.ActualAcqLength div pc6Header.NumSamplesPerEpisode ;

     { Determine whether data is integer or floating point }
     NumDataBytes := FileSeek( FileHandle, 0, 2 ) - FNumHeaderBytes ;
     if NumDataBytes >= (pc6Header.ActualAcqLength*4) then begin
        // Special processing for floating point samples
        FFloatingPointSamples := True ;
        FNumBytesPerSample := 4 ;

        // Determine absolute limits of each channel
        for ch := 0 to FNumChannelsPerScan-1 do MaxValue[ch] := 0.0 ;
        FileSeek( FileHandle, FNumHeaderBytes, 0 ) ;
        for i := 1 to pc6Header.ActualAcqLength div FNumChannelsPerScan do begin
            for ch := 0 to FNumChannelsPerScan-1 do begin
                FileRead(FileHandle,FPValue,Sizeof(FPValue)) ;
                if Abs(FPValue) > MaxValue[ch] then MaxValue[ch] := Abs(FPValue) ;
                end ;
            end ;

        // Compute scaling factors
        for ch := 0 to FNumChannelsPerScan-1 do begin
            MaxValue[ch] := MaxValue[ch]*1.1 ;
            if MaxValue[ch] = 0.0 then MaxValue[ch] := 1.0 ;
            FADCScale[ch] := FMaxADCValue / MaxValue[ch] ;
            FChannelScale[ch] := 1.0 / FADCScale[ch] ;
            FChannelCalibrationFactor[ch] := CalibFactor(ch) ;
            end ;
        FADCOffset := 0 ;
        end
     else begin
        // Integer samples
        FFloatingPointSamples := False ;
        FNumBytesPerSample := 2 ;
        for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
        FADCOffset := 0 ;
        end ;

     FNumBytesPerScan := FNumBytesPerSample*FNumChannelsPerScan ;
     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordAnalysisBytes := 0 ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

     UseTempFile := False ;

     Result := True ;

     end ;


function TADCDataFile.PClampV5LoadFileHeader : Boolean ;
// -------------------------------------------
// Read file header block from Axon PClamp V5 file
// -------------------------------------------
var
    pc5Header : TPClampV5 ;
    i : Integer ;
    ch : Integer ;
    pcChan : Integer ;
    ChannelIncrement : Integer ;
begin

    { Read header block as pClamp 5 file }
    FileSeek( FileHandle, 0, 0 ) ;
    if FileRead(FileHandle,pc5Header,Sizeof(pc5Header))
       <> Sizeof(pc5Header) then begin
       Result := False ;
       Exit ;
       end ;

    if pc5Header.par[0] = 1. then FABFAcquisitionMode := ftEpisodic
    else if pc5Header.par[0] = 10. then FABFAcquisitionMode := ftGapFree ;

    FNumChannelsPerScan := Max(Round(pc5Header.par[1]),1) ;
    FFloatingPointSamples := False ;
    FNumBytesPerSample := 2 ;

    FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;

    FNumScansPerRecord := Trunc(pc5Header.par[2]) div FNumChannelsPerScan ;
    FNumRecords := Round(pc5Header.par[3]) ;

    { Get byte offset of data section }
    FNumHeaderBytes :=  1024 ;
    FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
    FNumRecordAnalysisBytes := 0 ;
    FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

	  FScanInterval := pc5Header.par[4]*1E-6*FNumChannelsPerScan ;
    FADCVoltageRange := pc5Header.par[52] ;

    FMaxADCValue := Round(Power(2.,pc5Header.par[54]-1)) - 1 ;
    FMinADCValue := -MaxADCValue - 1 ;

    FIdentLine := '' ;

    { Channel scaling/units information }
    pcChan := Round ( pc5Header.par[31] ) {- 1} ;

    { Determine whether channels increment or decrement }
    if FNumChannelsPerScan > 1 then begin
       pcChan := pcChan - 1 ;
       if pcChan < 0 then pcChan := FNumChannelsPerScan-1 ;
       if pc5Header.par[30] = 1.0 then ChannelIncrement := -1
                                  else ChannelIncrement := 1 ;
       end
    else ChannelIncrement := 0 ;

    for ch := 0 to FNumChannelsPerScan-1 do begin

        FChannelOffset[ch] := ch ;
        FChannelGain[ch] := 1. ;
        FChannelCalibrationFactor[ch] := pc5Header.ADCGain[pcChan] ;
        FChannelADCVoltageRange[ch] :=  FADCVoltageRange ;
        FChannelScale[ch] := ADCScale( ch ) ;
	      FChannelZero[ch] := 0 ;
        FChannelUnits[ch] := '' ;
        for i := 1 to 4 do FChannelUnits[ch] := FChannelUnits[ch]
                                                + pc5Header.Units[pcChan,i] ;

        { Read Analog channel name (Fetchex only) }
        if FABFAcquisitionMode = ftGapFree then begin
           FChannelName[ch] := '' ;
           for i := 1 to 10 do FChannelName[ch] := FChannelName[ch]
                               + pc5Header.ChannelNames[pcChan,i] ;
           end
        else FChannelName[ch] := Format( 'Ch.%d', [ch] ) ;

        pcChan := pcChan + ChannelIncrement ;
        if pcChan < 0 then pcChan := FNumChannelsPerScan-1 ;
        if pcChan >= FNumChannelsPerScan then pcChan := 0 ;
        end ;

    for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
    FADCOffset := 0 ;

    UseTempFile := False ;

    Result := True ;
    end ;


function TADCDataFile.ABFSaveFileHeader : Boolean ;
// -------------------------------------------
// Save file header block to Axon ABF file
// -------------------------------------------
// File saved as V1.5 ABF
var
     pc6Header : TABF ;
     i : Integer ;
     ch : Integer ;
     s : string ;
     Day,Month,Year,Min,Hour,Sec,Msec : Word ;
     lDay,lMonth,lYear,lMin,lHour,lSec : LongInt ;

begin

    pc6header.FileType[1] := 'A' ;
    pc6header.FileType[2] := 'B' ;
    pc6header.FileType[3] := 'F' ;
    pc6header.FileType[4] := ' ' ;

    pc6header.FileVersionNumber := 1.5 ;

    // Set acquisition mode
    if FABFAcquisitionMode = ftGapFree then pc6Header.OperationMode := 3
                                       else pc6Header.OperationMode := 5 ;

    pc6header.NumPointsIgnored := 0 ;

    DecodeDate( Now, Year, Month, Day ) ;
    lDay := Day ;
    lMonth := Month ;
    lYear := Year ;
    pc6header.FileStartDate := lDay + 100*lMonth + 10000*lYear ;
    DecodeTime( Now, Hour, Min, Sec, MSec ) ;
    lHour := Hour ;
    lMin := Min ;
    lSec := Sec ;
    pc6header.FileStartTime := lHour*3600 + lMin*60 + lSec ;

    pc6header.StopwatchTime := 0 ;
    pc6header.HeaderVersionNumber := pc6header.FileVersionNumber ;
    pc6header.nFileType := 1 ;
    pc6header.MSBinFormat := 0 ;

    pc6header.DataSectionPtr := ABFFileHeaderSize_V15 div 512 ;
    pc6header.TagSectionPtr := 0 ;
    pc6header.NumTagEntries := 0 ;
    pc6header.ScopeConfigPtr := 0 ;
    pc6header.NumScopes := 0 ;
    pc6header.DACFilePtr := 0 ;
    pc6header.DACFileNumEpisodes := 0 ;
    pc6header.DeltaArrayPtr := 0 ;
    pc6header.NumDeltas := 0 ;
    pc6header.VoiceTagPtr := 0 ;
    pc6header.VoiceTagEntries := 0 ;
    pc6header.SynchArrayPtr := 0 ;
    pc6header.SynchArraySize := 0 ;
    pc6header.DataFormat := 0 ;
    pc6header.SimultaneousScan := 0 ;
    pc6header.StatisticsConfigPtr := 0 ;

    pc6header.AnnotationSectionPtr := 0 ;
    pc6header.NumAnnotations := 0 ;
    pc6header.ChannelCountAcquired := 0 ;

    pc6header.ADCNumChannels := FNumChannelsPerScan ;
    pc6header.ADCSampleInterval := (FScanInterval*1E6)/FNumChannelsPerScan ; {in microsecs}
    pc6header.ADCSecondSampleInterval := 0. ;
    pc6header.SynchTimeUnit := 0. ;
    pc6header.SecondsPerRun := 0 ;

    pc6header.NumSamplesPerEpisode := FNumScansPerRecord*FNumChannelsPerScan ;
    pc6header.PreTriggerSamples := 50 ;
    pc6header.EpisodesPerRun := 1 ;
    pc6header.RunsPerTrial := 1 ;
    pc6header.NumberofTrials := 1 ;
    pc6header.AveragingMode := 0 ;
    pc6header.UndoRunCount := -1 ;
    pc6header.FirstEpisodeInRun := 1 ;
    pc6header.TriggerThreshold := 100 ;
    pc6header.TriggerSource := -2 ;
    pc6header.TriggerAction := 0 ;
    pc6header.TriggerPolarity := 0 ;
    pc6header.ScopeOutputInterval := 0. ;
    pc6header.EpisodeStartToStart := 1. ;
    pc6header.RunStartToStart := 1. ;
    pc6header.TrialStartToStart := 1. ;
    pc6header.AverageCount := 1 ;
    pc6header.ClockChange := 0 ;
    pc6header.AutoTriggerStrategy := 0 ;

    pc6header.DrawingStrategy := 1 ;
    pc6header.TiledDisplay := 0 ;
    pc6header.DataDisplayMode := 1 ;
    pc6header.DisplayAverageUpdate := -1 ;
    pc6header.ChannelStatsStrategy := 1 ;
    pc6header.CalculationPeriod := 16384 ;
    pc6header.SamplesPerTrace := 512 ;
    pc6header.StartDisplayNum := 1 ;
    pc6header.FinishDisplayNum := 0 ;
    pc6header.MultiColor := 1 ;
    pc6header.ShowPNRawData := 0 ;
    pc6header.StatisticsPeriod := 0 ;
    pc6header.StatisticsMeasurements := 0 ;
    pc6header.StatisticsSaveStrategy := 0 ;

    pc6header.ADCRange := FADCVoltageRange ;
    pc6header.DACRange := 10.24 ;
    pc6header.ADCResolution := FMaxADCValue+1 ;
    pc6header.DACResolution := FMaxADCValue+1 ;
    pc6header.AutoSampleEnable := 0 ;
    pc6header.AutoSampleAddItGain := 1. ;
    pc6header.AutoSampleADCNum := 0 ;

    pc6header.ExperimentType := 0 ;
    pc6header.AutoSampleEnable := 0 ;
    pc6header.AutoSampleADCNum := 0 ;
    pc6header.AutoSampleInstrument := 0 ;
    pc6header.AutoSampleAddItGain := 1. ;
    pc6header.AutoSampleFilter := 100000. ;
    pc6header.AutoSampleMembraneCap := 1. ;

    pc6header.ManualInfoStrategy := 0 ;
    pc6header.CellID1 := 1. ;
    pc6header.CellID2 := 2. ;
    pc6header.CellID3 := 3. ;

    for i := 1 to 16 do pc6header.CreatorInfo[i] := ' ' ;

    { Experiment ident information }
    for i := 1 to High(pc6header.FileComment) do begin
        pc6header.FileComment[i] := ' ' ;
        if i < Length(FIdentLine) then begin
           pc6header.FileComment[i] := FIdentLine[i];
           if i < High(pc6header.FileComment) then
              pc6header.FileComment[i] := FIdentLine[i];
           end ;
        end ;

    pc6header.FileStartMillisecs := 0 ;
    pc6header.CommentEnabled := 0 ;

    { Name of program which created file }
    s := 'WinEDR' ;
    for i := 1 to High(pc6header.CreatorInfo) do begin
        pc6header.CreatorInfo[i] := ' ' ;
        if i < Length(s) then pc6header.CreatorInfo[i] := s[i];
        end ;

    { Analog input channel settings }
    for ch := 0 to 15 do begin

	      pc6header.ADCPToLChannelMap[ch] := ch ;
	      pc6header.ADCSamplingSeq[ch] := -1 ;

        for i := 1 to 10 do pc6header.ADCChannelName[ch,i] := ' ' ;
        s := format( 'Ch%d ',[ch] ) ;
        for i := 1 to 4 do pc6header.ADCChannelName[ch,i] := s[i] ;
        for i := 1 to 8 do pc6header.ADCUnits[ch,i] := ' ' ;
	      pc6header.ADCUnits[ch,1] := 'm' ;
        pc6header.ADCUnits[ch,2] := 'V' ;

	      pc6header.ProgrammableGain[ch] := 1. ;
	      pc6header.DisplayAmplification[ch] := 1. ;
	      pc6header.DisplayOffset[ch] := 0. ;
	      pc6header.InstrumentScaleFactor[ch] := 1. ;
	      pc6header.InstrumentOffset[ch] := 0. ;
	      pc6header.SignalGain[ch] := 1. ;
	      pc6header.SignalOffset[ch] := 0. ;
	      pc6header.SignalLowpassFilter[ch] := 100000. ;
	      pc6header.SignalHighpassFilter[ch] := 0. ;
        end ;

    { Analog output channel settings }
    for ch := 0 to 3 do begin
        for i := 1 to 10 do pc6header.DACChannelName[ch,i] := ' ' ;
        for i := 1 to 8 do pc6header.DACChannelUnits[ch,i] := ' ' ;
        pc6header.DACScaleFactor[ch] := 1. ;
        pc6header.DACHoldingLevel[ch] := 0. ;
        end ;

    pc6header.SignalType := 0 ;

    pc6header.OutEnable := 0 ;
    pc6header.SampleNumberOUT1 := 0 ;
    pc6header.SampleNumberOUT2 := 0 ;
    pc6header.FirstEpisodeOUT := 0 ;
    pc6header.LastEpisodeOut := 0 ;
    pc6header.PulseSamplesOUT1 := 0 ;
    pc6header.PulseSamplesOUT2 := 0 ;

    pc6header.DigitalEnable := 0 ;
    pc6header.WaveformSource := 0 ;
    pc6header.ActiveDACChannel := 0 ;
    pc6header.InterEpisodeLevel := 0 ;
    for i := 0 to High(pc6header.EpochType) do begin
        pc6header.EpochType[i] := 0 ;
        pc6header.EpochInitLevel[i] := 0. ;
        pc6header.EpochLevelInc[i] := 0. ;
        pc6header.EpochInitDuration[i] := 0 ;
        pc6header.EpochDurationInc[i] := 0 ;
        end ;
    pc6header.DigitalHolding := 0 ;
    pc6header.DigitalInterEpisode := 0 ;
    for i := 0 to High(pc6header.DigitalValue) do
        pc6header.DigitalValue[i] := 0 ;
    pc6header.DigitalDACChannel := 0 ;

    pc6header.DACFileStatus := 1. ;
    pc6header.DACFileOffset := 0. ;
    pc6header.DACFileEpisodeNum := 0 ;
    pc6header.DACFileADCNum := 0 ;
    for i := 1 to High(pc6header.DACFilePath) do
        pc6header.DACFilePath[i] := ' ' ;

    pc6header.ConditEnable := 0 ;
    pc6header.ConditChannel := 0 ;
    pc6header.ConditNumPulses := 0 ;
    pc6header.BaselineDuration := 1. ;
    pc6header.BaselineLevel := 0. ;
    pc6header.StepDuration := 1. ;
    pc6header.StepLevel := 0. ;
    pc6header.PostTrainPeriod := 1. ;
    pc6header.PostTrainLevel := 1. ;

    pc6header.ParamToVary := 0 ;
    for i := 1 to High(pc6header.ParamValueList) do
        pc6header.ParamValueList[i] := ' ' ;

    pc6header.AutoPeakEnable := 0 ;
    pc6header.AutoPeakPolarity := 0 ;
    pc6header.AutoPeakADCNum := 0 ;
    pc6header.AutoPeakSearchMode := 0 ;
    pc6header.AutoPeakStart := 0 ;
    pc6header.AutoPeakEnd := 0 ;
    pc6header.AutoPeakSmoothing := 1 ;
    pc6header.AutoPeakBaseline := -2 ;
    pc6header.AutoPeakAverage := 0 ;

    pc6header.ArithmeticEnable := 0 ;
    pc6header.ArithmeticUpperLimit := 1. ;
    pc6header.ArithmeticLowerLimit := 0. ;
    pc6header.ArithmeticADCNumA := 0 ;
    pc6header.ArithmeticADCNumB := 0 ;
    pc6header.ArithmeticK1 := 1. ;
    pc6header.ArithmeticK2 := 2. ;
    pc6header.ArithmeticK3 := 3. ;
    pc6header.ArithmeticK4 := 4. ;
    pc6header.ArithmeticOperator[1] := '+' ;
    pc6header.ArithmeticOperator[2] := ' ' ;
    for i := 1 to High(pc6header.ArithmeticUnits) do
        pc6header.ArithmeticUnits[i] := ' ' ;
    pc6header.ArithmeticK5 := 5. ;
    pc6header.ArithmeticK6 := 6. ;
    pc6header.ArithmeticExpression := 0 ;

    pc6header.PNEnable := 0 ;
    pc6header.PNPosition := 0 ;
    pc6header.PNPolarity := 1 ;
    pc6header.PNNumPulses := 4 ;
    pc6header.PNADCNum := 0 ;
    pc6header.PNHoldingLevel := 0. ;
    pc6header.PNSettlingTime := 100. ;
    pc6header.PNInterPulse := 100. ;

    pc6header.ListEnable := 0 ;

    for i := 0 to 1 do begin
      pc6header.BellEnable[i] := 0 ;
      pc6header.BellLocation[i] := 0 ;
      pc6header.BellRepetitions[i] := 0 ;
      end ;

    pc6header.LevelHysteresis := 0 ;
    pc6header.TimeHysteresis := 0 ;
    pc6header.AllowExternalTags := 0 ;

    for i := 0 to 15 do begin
      pc6header.LowpassFilterType[i] := #0 ;
      pc6header.HighpassFilterType[i] := #0 ;
      end ;

    pc6header.AverageAlgorithm := 0 ;
    pc6header.AverageWeighting := 0 ;
    pc6header.UndoPromptStrategy := 0 ;
    pc6header.TrialTriggerSource := 0 ;
    pc6header.StatisticsDisplayStrategy := 0 ;
    pc6header.ExternalTagType := 0 ;

    pc6header.HeaderSize := ABFFileHeaderSize_V15 ;
    pc6header.FileDuration := 0 ;
    pc6header.StatisticsClearStrategy := 0 ;

    { Update header with number of records written }
    pc6Header.ActualAcqLength := (FileSeek(FileHandle,0,2) - ABFFileHeaderSize_V15 )
                                 div FNumBytesPerSample ;

    pc6Header.ActualEpisodes := FNumRecords ;

    { Channel scaling/units information }
    for ch := 0 to FNumChannelsPerScan-1 do begin
        pc6Header.ADCSamplingSeq[ch] := FChannelOffset[ch] ;
        pc6Header.SignalGain[ch] := 1. ;
        pc6Header.InstrumentScaleFactor[ch] := FChannelCalibrationFactor[ch] *
                                               FChannelGain[ch] ;

        for i := 1 to 8 do if i <= Length(FChannelUnits[ch]) then
            pc6Header.ADCUnits[ch,i] := FChannelUnits[ch][i] ;

        for i := 1 to 10 do if i <= Length(FChannelName[ch]) then
            pc6Header.ADCChannelName[ch,i] := FChannelName[ch][i] ;

        end ;

    { Experiment ident information }
    for i := 1 to High(pc6header.FileComment) do begin
        pc6header.FileComment[i] := ' ' ;
        if i < Length(FIdentLine) then begin
           pc6header.FileComment[i] := FIdentLine[i];
           if i < High(pc6header.FileComment) then
              pc6header.FileComment[i] := FIdentLine[i];
           end ;
        end ;

    { Write header block }
    FileSeek( FileHandle, 0, 0 ) ;
    if FileWrite(FileHandle,pc6Header,ABFFileHeaderSize_V15)
       <> ABFFileHeaderSize_V15 then
       ShowMessage( 'Error writing ABF file header to ' + FileName ) ;

    UseTempFile := False ;
    Result := True ;
    
    end ;


function TADCDataFile.CFSLoadFileHeader : Boolean ;
// ----------------------------------
// Load CED Filing System file header
// ----------------------------------
var
     i : Integer ;
     ch : Integer ;
     s : String ;
     TimeUnits : String ;
     TScale : Single ;
     DataPointer : Integer ;
     RecHeader : TCFSDataHeader ;
     ChannelInfo : Array[0..ChannelLimit] of TCFSChannelInfo ;
     CFSch : Integer ;
     FilePointer : Integer ;
     Y,YMin,YMax : Single ;
     DblY : Double ;
begin

     Result := False ;

     {  Read CFS file header block }
     FileSeek( FileHandle, 0, 0 ) ;
     if FileRead(FileHandle,CFSFileHeader,Sizeof(CFSFileHeader))
        <> Sizeof(CFSFileHeader) then begin
        ShowMessage( FileName + ' - CFS Header unreadable' ) ;
        Exit ;
        end ;

     s := '' ;
     for i := 1 to High(CFSFileHeader.Marker) do s := s + CFSFileHeader.Marker[i] ;
     if Pos('CEDFILE',s) = 0 then begin
        ShowMessage( FileName + ' : Not a CFS data file' ) ;
        Exit ;
        end ;

     { No. of analog input channels held in file }
     if CFSFileHeader.DataChans > (ChannelLimit+1) then
        ShowMessage( format('Input channels 7-%d ignored',
                    [CFSFileHeader.DataChans-1]) ) ;

     { Get experiment identification text }
     FIdentLine := CFSFileHeader.CommentStr ;

     { A/D converter input voltage range }
	   FADCVoltageRange := 5.0 ;
     FMaxADCValue := 32767 ;
     FMinADCValue := -FMaxADCValue -1 ;

     FNumRecords := CFSFileHeader.DataSecs ;

     // Read Channel definition records
     // and determine number of analogue sample channels

	   for CFSCh := 0 to CFSFileHeader.DataChans-1 do begin

          { Read signal channel definition record }
          if FileRead(FileHandle,CFSChannelDef[CFSCh],Sizeof(TCFSChannelDef))
             <> Sizeof(TCFSChannelDef) then Break ;

          end ;

      { Get pointer to start of data record for Rec #1}
      FileSeek( FileHandle,CFSFileHeader.TablePos, 0 ) ;
      FileRead(FileHandle,DataPointer,SizeOf(DataPointer)) ;

      { Read record data header and channel information for 1st record }
      FileSeek( FileHandle, DataPointer, 0 ) ;
      FileRead(FileHandle,RecHeader,SizeOf(RecHeader)) ;
      for CFSCh := 0 to CFSFileHeader.DataChans-1 do
          FileRead(FileHandle,ChannelInfo[CFSCh],SizeOf(TCFSChannelInfo)) ;

      // Get ADCDataFile channel scaling info
      FNumScansPerRecord := 0 ;
      FNumChannelsPerScan := 0 ;
      FScanInterval := 1.0 ;
      //TScale := 1.0 ;
      for CFSCh := 0 to CFSFileHeader.DataChans-1 do begin

          if ChannelInfo[CFSCh].DataPoints <= 0 then Continue ;

          CFSChannel[FNumChannelsPerScan] := CFSCh ;

          { Name of signal channel }
          FChannelName[FNumChannelsPerScan] := CFSChannelDef[CFSCh].ChanName ;

          { Units of signal channel }
          FChannelUnits[FNumChannelsPerScan] := CFSChannelDef[CFSCh].UnitsY ;

          FNumScansPerRecord := Max(ChannelInfo[CFSCh].DataPoints,FNumScansPerRecord) ;

          { Offset into groups of A/D samples for this channel }
          FChannelOffset[FNumChannelsPerScan] := FNumChannelsPerScan ;

          FChannelGain[FNumChannelsPerScan] := 1. ;
          FChannelADCVoltageRange[FNumChannelsPerScan] := 5.0 ;

          // Only use analogue data channels containing samples
          case CFSChannelDef[CFSCh].dType of

              2 : begin // Integer data
                 FChannelScale[FNumChannelsPerScan] := ChannelInfo[CFSCh].ScaleY ;
                 FChannelCalibrationFactor[FNumChannelsPerScan] := CalibFactor( FNumChannelsPerScan ) ;
                 end ;

              4 : begin // Integer data
                 FChannelScale[FNumChannelsPerScan] := ChannelInfo[CFSCh].ScaleY*$10000 ;
                 FChannelCalibrationFactor[FNumChannelsPerScan] := CalibFactor( FNumChannelsPerScan ) ;
                 end ;

              5 : begin // 4 byte floating point data
                 FilePointer := RecHeader.DataSt + ChannelInfo[CFSch].DataOffset ;
                 YMin := 1E30 ;
                 YMax := -YMin ;
                 for i :=  0 to ChannelInfo[CFSCh].DataPoints-1 do begin
                     FileSeek( FileHandle, FilePointer, 0 ) ;
                     FileRead( FileHandle,Y,4) ;
                     FilePointer := FilePointer + CFSChannelDef[CFSch].dSpacing ;
                     if Y > YMax then YMax := Y ;
                     if Y < YMin then YMin := Y ;
                     end ;

                 FChannelScale[FNumChannelsPerScan] := ChannelInfo[CFSCh].ScaleY*
                 (Max(Abs(YMax),Abs(YMin))/32767.0) ;
                 FChannelCalibrationFactor[FNumChannelsPerScan] := CalibFactor( FNumChannelsPerScan ) ;
                 end ;

              6 : begin // 8 byte floating point data
                 FilePointer := RecHeader.DataSt + ChannelInfo[CFSch].DataOffset ;
                 YMin := 1E30 ;
                 YMax := -YMin ;
                 for i :=  0 to ChannelInfo[CFSCh].DataPoints-1 do begin
                     FileSeek( FileHandle, FilePointer, 0 ) ;
                     FileRead( FileHandle,DblY,8) ;
                     Y := DblY ;
                     FilePointer := FilePointer + CFSChannelDef[CFSch].dSpacing ;
                     if Y > YMax then YMax := Y ;
                     if Y < YMin then YMin := Y ;
                     end ;
                 FChannelScale[FNumChannelsPerScan] := ChannelInfo[CFSCh].ScaleY*
                                                      ((Max(Abs(YMax),Abs(YMin))*1.1)/32767.0) ;
                 FChannelCalibrationFactor[FNumChannelsPerScan] := CalibFactor( FNumChannelsPerScan ) ;
                 end ;
             end ;

          // Get sampling interval
          case CFSChannelDef[CFSCh].dType of
              2,4,5,6 : begin
                  TimeUnits := CFSChannelDef[CFSCh].UnitsX ;
                  if Pos( 'us', TimeUnits ) > 0 then TScale := 1E-6
                  else if Pos( 'ms', TimeUnits ) > 0 then TScale := 1E-3
                  else TScale := 1. ;
                  FScanInterval := ChannelInfo[CFSCh].scaleX*TScale ;
                  end ;
              end ;

          Inc(FNumChannelsPerScan) ;

          end ;

      FFloatingPointSamples := False ;
      FNumBytesPerSample := 2 ;

      FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;

      for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
      FADCOffset := 0 ;
      UseTempFile := False ;

      end ;


function TADCDataFile.CFSSaveFileHeader : Boolean ;
// -------------------------------------------
// Save file header block to CFS data file,
// -------------------------------------------
var
     i : Integer ;
     ch : Integer ;
     CFSDataHeader : TCFSDataHeader ;
     CFSChannelDef : TCFSChannelDef ;
     CFSChannelInfo : TCFSChannelInfo ;
     DataSectionPointer,TablePointer : Integer ;

begin

     Result := False ;
     if FileHandle < 0 then Exit ;


    // Create and save channel definition records
    // (appended to end of common file header)

    FileSeek( FileHandle, SizeOf(CFSFileHeader), 0 ) ;
    for ch := 0 to FNumChannelsPerScan-1 do begin

        CFSChannelDef.ChanName := FChannelName[ch] ;
        CFSChannelDef.UnitsY := FChannelUnits[ch] ;
        CFSChannelDef.UnitsX := 's' ;
        CFSChannelDef.dType := 2 ;
        CFSChannelDef.dKind := 0 ;
        CFSChannelDef.dSpacing := FNumChannelsPerScan*2 ;
        CFSChannelDef.OtherChan := 0 ;

        FileWrite( FileHandle, CFSChannelDef, Sizeof(CFSChannelDef)) ;

        end ;

    // Create and save data section pointer table
    // (appended to end of data sections)

    TablePointer := FNumHeaderBytes + FNumRecords*FNumRecordBytes ;
    FileSeek( FileHandle, TablePointer, 0 ) ;
    for i := 0 to FNumRecords-1 do begin
        DataSectionPointer := FNumHeaderBytes + i*FNumRecordBytes ;
        FileWrite( FileHandle, DataSectionPointer, SizeOf(DataSectionPointer)) ;
        end ;

    // Create and save file header (at beginning of file)

    CFSFileHeader.Marker := 'CEDFILE"' ;
    StringToCharacterArray( ExtractFileName(FFileName), CFSFileHeader.Name ) ;
	  CFSFileHeader.FileSz := FileSeek( FileHandle, 0, 2 ) ;
    StringToCharacterArray( TimeToStr(Time), CFSFileHeader.TimeStr ) ;
	  StringToCharacterArray( DateToStr(Time), CFSFileHeader.DateStr ) ;
	  CFSFileHeader.DataChans := FNumChannelsPerScan ;
	  CFSFileHeader.FilVars := 0 ;
	  CFSFileHeader.DatVars := 0 ;
	  CFSFileHeader.fileHeadSz := SizeOf(CFSFileHeader) +
                                FNumChannelsPerScan*Sizeof(CFSChannelDef)  ;
	  CFSFileHeader.DataHeadSz := SizeOf(CFSDataHeader) +
                                FNumChannelsPerScan*Sizeof(CFSChannelInfo)  ;
	  CFSFileHeader.EndPnt := FNumHeaderBytes + (FNumRecords-1)*FNumRecordBytes ;
	  CFSFileHeader.DataSecs := FNumRecords ;
	  CFSFileHeader.DiskBlkSize := 1 ;
	  StringToCharacterArray( FIDentLine, CFSFileHeader.CommentStr ) ;

	  CFSFileHeader.TablePos := TablePointer ;

     FileSeek( FileHandle, 0, 0 ) ;
     FileWrite( FileHandle, CFSFileHeader, Sizeof(CFSFileHeader) ) ;

     Result := True ;

     end ;

procedure TADCDataFile.CFSSaveDataHeader(
          RecordNum : Integer ) ;
// --------------------------------
// Save data section header to file
// --------------------------------
var
     CFSDataHeader : TCFSDataHeader ;
     CFSChannelInfo : TCFSChannelInfo ;
     ch,FilePointer : Integer ;
begin

    // Write data header
    if RecordNum > 1 then CFSDataHeader.lastDS := FNumHeaderBytes
                                                  + (RecordNum-2)*FNumRecordBytes
                     else CFSDataHeader.lastDS := 0 ;

	  CFSDataHeader.dataSt := FNumHeaderBytes
                            + (RecordNum-1)*FNumRecordBytes
                            + FNumRecordAnalysisBytes ;

	  CFSDataHeader.dataSz := FNumChannelsPerScan*FNumScansPerRecord*2 ;

	  CFSDataHeader.Flags := 0 ;

    FilePointer := FNumHeaderBytes + (RecordNum-1)*FNumRecordBytes ;
    FileSeek( FileHandle, FilePointer, 0 ) ;
    FileWrite( FileHandle, CFSDataHeader, Sizeof(CFSDataHeader)) ;

    // Write Data header channel info
    for ch := 0 to FNumChannelsPerScan-1 do begin
        CFSChannelInfo.DataOffset := FChannelOffset[ch]*2 ; {offset to first point}
        CFSChannelInfo.DataPoints := FNumScansPerRecord ;
        CFSChannelInfo.scaleY := FChannelScale[ch] ;
        CFSChannelInfo.OffsetY := 0.0 ;
        CFSChannelInfo.scaleX := FScanInterval ;
        CFSChannelInfo.offsetX := 0.0  ;
        FileWrite( FileHandle, CFSChannelInfo, Sizeof(CFSChannelInfo)) ;
        end ;

    end ;


function TADCDataFile.ASCLoadFile : Boolean ;
// -----------------------------------
// Read ASCII text file into temp file
// -----------------------------------
const
     MaxColumns = ChannelLimit+2 ;
     MaxLines = 20 ;
var
     NumItems : Integer ;
     MaxItems : Integer ;
     Line : String ;
     NumLines : Integer ;
     NumLinesPerRecord : Integer ;
     EndOfRecord : Boolean ;
     Done : Boolean ;
     EOF : Boolean ;
     i : Integer ;
     Items : Array[0..MaxColumns-1] of String ;
     Value : Single ;
     TValue : Single ;
     LastTValue : Single ;
     MaxValue : Array[0..MaxColumns-1] of Single ;
     dt : Single ;
     ch : Integer ;
begin

     Result := False ;

     // Go to start of file
     FileSeek( FileHandle, 0, 0 ) ;

     // Skip requested number of initial lines
     for i := 1 to FASCIITitleLines do
         ASCReadLine( FileHandle, FASCIISeparator, Line, Items, NumItems, EOF ) ;

     MaxItems := 0 ;
     for i := 1 to MaxLines do begin
         ASCReadLine( FileHandle, FASCIISeparator, Line, Items, NumItems, EOF ) ;
         if NumItems > MaxItems then MaxItems := NumItems ;
         if EOF then Break ;
         end ;

     // Create a temporary file
     TempFileName := CreateTempFileName ;
     TempHandle := FileCreate( TempFileName ) ;

    // Can't use column 1 for time if only one column ...
    if (MaxItems = 1) and (ASCTimeColumn = 1) then begin
       ShowMessage( 'Single column data table. Cannot use first column as time!' ) ;
       ASCTimeColumn := 0 ;
       end ;

     // Convert from ASCII data to floating point and store in temporary file

     // Skip requested number of initial lines
     FileSeek( FileHandle, 0, 0 ) ;
     for i := 1 to FASCIITitleLines do
         ASCReadLine( FileHandle, FASCIISeparator, Line, Items, NumItems, EOF ) ;

     NumLines := 0 ;
     NumLinesPerRecord := 0 ;
     EndOfRecord := False ;
     LastTValue := 0.0 ;
     for ch := 0 to MaxItems-1 do MaxValue[ch] := 0.0 ;

     Done := False ;
     dt := 1.0 ;
     While not Done do begin

        // Read line of items from file
        ASCReadLine( FileHandle, FASCIISeparator, Line, Items, NumItems, Done ) ;

        if (NumItems = MaxItems) and (Length(Line) > 0) then begin

           // Write items to temp. file
           ch := 0 ;
           for i := 0 to NumItems-1 do begin
               Value := ExtractFloat( Items[i],0.0 ) ;
               if ( i > 0) or (ASCTimeColumn <> 1) then begin
                  if Abs(Value) > MaxValue[ch] then MaxValue[ch] := Abs(Value) ;
                  FileWrite( TempHandle, Value, SizeOf(Value) ) ;
                  Inc(ch) ;
                  end ;
               end ;

           // Calculate sampling interval and record length
           TValue := ExtractFloat( Items[0],0.0 ) ;
           if NumLines > 1 then begin
              if TValue > LastTValue then begin
                 dt := TValue - LastTValue ;
                 end
              else begin
                 EndOfRecord := True ;
                 end ;
              end ;
           if not EndOfRecord then Inc(NumLinesPerRecord) ;
           LastTValue := TValue ;
           Inc(NumLines) ;
           end
        else Done := True ;

        end ;

    if ASCTimeColumn = 1 then begin
       // Sampling times available
       if (not FASCIIFixedRecordSize) then FNumScansPerRecord := NumLinesPerRecord ;

       FNumChannelsPerScan := MaxItems - 1 ;
       //FNumRecords := Max(NumLines div FNumScansPerRecord,1) ;
       if LowerCase(FASCIITimeUnits) = 's' then FScanInterval := dt
       else if LowerCase(FASCIITimeUnits) = 'ms' then FScanInterval := dt*0.001
       else FScanInterval := dt*60.0 ;
       end
    else begin
       // No sample times
       FNumChannelsPerScan := MaxItems ;
       if (not FASCIIFixedRecordSize) then FNumScansPerRecord := NumLines ;
       //FNumRecords := 1 ;
       end ;

    if FScanInterval <= 0.0 then FScanInterval := 1.0 ;
    FNumScansPerRecord := Max(FNumScansPerRecord,1) ;
    FNumRecords := Max(NumLines div FNumScansPerRecord,1) ;
    if NumLines > (FNumRecords*FNumScansPerRecord) then Inc(FNumRecords) ;

    FFloatingPointSamples := True ;

    FNumBytesPerSample := 4 ;
    FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;

    { Get byte offset of data section }
    FNumHeaderBytes :=  0 ;
    FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
    FNumRecordAnalysisBytes := 0 ;
    FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

    FADCVoltageRange := 10.0 ;
    FMaxADCValue := 32767 ;
    FMinADCValue := -FMaxADCValue - 1 ;
    for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
    FADCOffset := 0 ;
    UseTempFile := True ;

    for ch := 0 to FNumChannelsPerScan-1 do begin

        // Scaling and offset factors
        if MaxValue[ch] > 0.0 then
           FADCScale[ch] := FMaxADCValue / (1.1*MaxValue[ch])
        else FADCScale[ch] := 1.0 ;

        FChannelScale[ch] := 1.0 / FADCScale[ch] ;
          { Calculate calibration factors }
        FChannelGain[ch] := 1. ;
        FChannelADCVoltageRange[ch] := 10.0 ;
        FChannelCalibrationFactor[ch] := CalibFactor( ch ) ;
        FChannelZero[ch] := 0 ;

        { Offset into groups of A/D samples for this channel }
        FChannelOffset[ch] := ch ;

        end ;
    FIdentLine := '' ;

     end ;


procedure TADCDataFile.ASCReadLine(
         FileHandle : Integer ;       // Handle of file being read
         ItemSeparator : Char ;       // Item separator character
         var Line : String ;          // Returns full line read
         var Items : Array of String ;// Returns items within line
         var NumItems : Integer ;      // Returns no. of items
         var EOF : Boolean ) ;        // Returns True if at end of file
var
    Done : Boolean ;
    InChar : Char ;
    i : Integer ;
begin

    Done := False ;
    EOF := False ;
    NumItems := 0 ;
    Line := '' ;
    for i := 0 to High(Items) do Items[i] := '' ;

    while not Done do begin

        // Read character
        if FileRead( FileHandle, InChar, 1 ) <> 1 then begin
           EOF := True ;
           Break ;
           end ;

        if InChar = ItemSeparator then begin
           // Item separator - increment to next item
           if Length(Items[NumItems]) > 0 then Inc(NumItems) ;
           end
        else if (InChar = #10) then begin
           // Line ended by LF
           Done := True ;
           end
        else if (InChar = #13) then begin
           // Line ended by CR
           // Discard LF (if one exists)
           if FileRead(FileHandle,InChar,1) = 1 then begin
              if InChar <> #10 then FileSeek( FileHandle, -1, 1 ) ;
              end ;
           Done := True ;
           end
        else begin
           // Add to line and items
           Line := Line + InChar ;
           Items[NumItems] := Items[NumItems] + InChar ;
           end ;
        end ;

    // Add last item to count
    if Length(Items[NumItems]) > 0 then Inc(NumItems) ;

    end ;


function TADCDataFile.ASCSaveFile : Boolean ;
// ------------------------------------
// Save data in temp file to ASCII file
// ------------------------------------
var
    OutFile : TextFile ;
    s : String ;
    t : Single ;
    Value : Single ;
    NumLines : Cardinal ;     // No. of scans in file
    LineCounter : Cardinal ;  // Line counter
    i,ch : Integer ;
begin

    // Create ASCII output file
    AssignFile( OutFile, FFileName ) ;
    Rewrite( OutFile ) ;

    // Determine number of scans in temp file
    NumLines :=  FileSeek(TempHandle, 0, 2) div FNumBytesPerScan ;

    // Copy data from temporary file to output file
    FileSeek( TempHandle, 0, 0 ) ;
    LineCounter := 0 ;
    for i := 0 to NumLines-1 do begin
        t :=  LineCounter*FScanInterval ;
        s := format('%.7g',[t]) ;
        for ch := 0 to FNumChannelsPerScan-1 do begin
            FileRead( TempHandle, Value, SizeOf(Value)) ;
            s := s + format('%s%.7g',[#9,Value]) ;
            end ;
        WriteLn( OutFile, s ) ;
        Inc(LineCounter) ;
        if LineCounter >= FNumScansPerRecord then LineCounter := 0 ;
        end ;

    // Close ASCII file
    CloseFile( OutFile ) ;

    Result := True ;
    end ;


function TADCDataFile.WFDBLoadFile : Boolean ;
// ------------------------------------------------------
// Read file header block from WFBD (Physionet) data file
// ------------------------------------------------------
const
   MaxLines = 100 ;
   MaxItems = 20 ;
   NumScansPerBuf = 256 ;
var
   // Header file and related variables
   F : TextFile ;
   Header : array[0..MaxLines-1] of String ;
   Items : Array[0..MaxItems-1] of String ;
   NumItems : Integer ;
   i,ch : Integer ;
   iLine : Integer ;
   NumLines : Integer ;

   NumSamplesInFile : Integer ;
   PackingFormat : Integer ;

   SamplingFrequency : Single ;
   ADCLevelsPermV : Single ;
   ADCResolution : Integer ;
   DataFileName : String ;

   // Buffers and related variables
   NumSamplesPerBuf : Integer ;
   NumBytesPerBuf : Integer ;
   NumBytesToCopy : Integer ;
   NumBytesRead : Integer ;
   NumSamplesRead : Integer ;
   NumNibblesPerSample : Integer ;
   iIn, iOut : Integer ;
   InBuf : Array[0..(2*(ChannelLimit+1)*NumScansPerBuf)-1] of Byte ;
   OutBuf : Array[0..((ChannelLimit+1)*NumScansPerBuf)-1] of SmallInt ;
   Byte0, Byte1, Byte2,Sample0,Sample1 : SmallInt ;

   Done : Boolean ;
begin

     Result := False ;

     // Close WFDB header file
     if FileHandle >= 0 then begin
        FileClose( FileHandle ) ;
        FileHandle := -1 ;
        end ;

     // Read WFDB header file
     AssignFile(F, FFileName); { File selected in dialog }
     Reset(F);
     NumLines := 0 ;
     While not EOF(F) do begin
          Readln(F, Header[NumLines]);
          Inc(NumLines) ;
          end ;
     CloseFile(F) ;
     if NumLines <= 0 then begin
        ShowMessage( 'TADCDataFile: No data in WFDB file header!' ) ;
        Exit ;
        end ;

     // Find first non-comment line
     iLine := 0 ;
     While (Header[iLine][1] = '#') and (iLine < High(Header)) do Inc(iLine) ;

     // Read items from first line
     NumItems := ExtractItems( Header[iLine], ' ', Items ) ;
     if NumItems < 4 then begin
        ShowMessage(
        format('Not enough information in header line (%s)!',
               [Header[iLine]]) ) ;
        Exit ;
        end ;

     // No. of signals channels
     if Items[1] <> '' then begin
        FNumChannelsPerScan := ExtractInt(Items[1]) ;
        end
     else FNumChannelsPerScan := 1 ;

     // No. of multi-channel scans in file
     FNumRecords := 1 ;
     if Items[3] <> '' then begin
        FNumScansPerRecord := ExtractInt(Items[3]) ;
        end
     else FNumScansPerRecord := 0 ;

     // Get multi-channel scan interval
     if Items[2] <> '' then begin
        SamplingFrequency := ExtractFloat(Items[2],0.0) ;
        if SamplingFrequency > 0.0 then FScanInterval := 1.0/SamplingFrequency
                                   else FScanInterval := 1.0 ;
        end
     else FScanInterval := 1.0 ;


     Inc(iLine) ;
     NumItems := ExtractItems( Header[iLine], ' ', Items ) ;

     // Get name of file containing binary data
     DataFileName := ExtractFilePath(FFileName) + Items[0] ;

     PackingFormat := ExtractInt(Items[1]) ;
     if PackingFormat = 212 then NumNibblesPerSample := 3
     else if PackingFormat = 16 then NumNibblesPerSample := 4 ;

     ADCLevelsPermV := ExtractInt(Items[2]) ;
     if ADCLevelsPermV = 0 then ADCLevelsPermV := 200.0 ;

     ADCResolution := ExtractInt(Items[3]) ;
     FMaxADCValue := 1 ;
     for i := 1 to ADCResolution-1 do FMaxADCValue := FMaxADCValue*2 ;
     if FMaxADCValue = 1 then FMaxADCValue := 32767 ;
     FMinADCValue := -FMaxADCValue - 1 ;

     FADCVoltageRange := (0.001*FMaxADCValue) / ADCLevelsPermV ;

     for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
     FADCOffset:= ExtractInt(Items[4]) ;

     for ch := 0 to FNumChannelsPerScan-1 do begin
         FChannelOffset[ch] := ch ;
         FChannelUnits[ch] := 'mV' ;
         FChannelName[ch] := format('Ch%d',[ch]) ;
         FChannelGain[ch] := 1.0 ;
         FChannelScale[ch] := 1.0 / ADCLevelsPermV ;
         FChannelADCVoltageRange[ch] :=  FADCVoltageRange ;
         FChannelCalibrationFactor[ch] := CalibFactor( ch ) ;
         FChannelZero[ch] := 0  ;
         FChannelZeroAt[ch] := -1 ;
         end ;

     { Experiment identification line }
     FIdentLine := '' ;

     // Open binary data file
     FileHandle := FileOpen( DataFileName, fmOpenRead ) ;

     // Create a temporary file
     TempFileName := CreateTempFileName ;
     TempHandle := FileCreate( TempFileName ) ;

     // Convert from packed to 2byte binary format
     // and copy to temporary file
     FileSeek( FileHandle, 0, 0 ) ;
     Done := False ;
     NumSamplesPerBuf := NumScansPerBuf*FNumChannelsPerScan ;
     NumBytesPerBuf := (NumSamplesPerBuf*NumNibblesPerSample) div 2 ;
     NumBytesToCopy := (FNumScansPerRecord*FNumChannelsPerScan*NumNibblesPerSample)
                       div 2  ;
     While not Done do begin
           // Read samples from WHDB file
           NumBytesRead := FileRead( FileHandle, InBuf, NumBytesPerBuf ) ;
           NumSamplesRead := (NumBytesRead*2) div NumNibblesPerSample  ;
           if NumBytesRead <= 1 then Break ;

           // Expand packed bytes
           iIn := 0 ;
           iOut := 0 ;
           While iOut < (NumSamplesRead-1) do begin
               Byte0 := InBuf[iIn] ;
               Byte1 := InBuf[iIn+1] ;
               Byte2 := InBuf[iIn+2] ;
               Sample0 := Byte0 or ((Byte1 and $F) shl 8) ;
               if Sample0 > 2047 then Sample0 := Sample0 - 4096 ;
               Sample1 := Byte2 or (((Byte1 shr 4) and $F) shl 8) ;
               if Sample1 > 2047 then Sample1 := Sample1 - 4096 ;
               OutBuf[iOut] := Sample0 ;
               OutBuf[iOut+1] := Sample1 ;
               iIn := iIn + 3 ;
               iOut := iOut + 2 ;
               end ;

          // Write to temporary file
          FileWrite( TempHandle, OutBuf, NumSamplesRead*2 ) ;
          NumBytesToCopy := NumBytesToCopy - NumBytesRead ;
          if NumBytesToCopy <= 0 then Done := True ;

          end ;

    FFloatingPointSamples := False ;
    UseTempFile := True ;
    FNumHeaderBytes := 0 ;
    FNumBytesPerSample := 2 ;
    FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;

    FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
    FNumRecordAnalysisBytes := 0 ;
    FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

    Result := True ;
    end ;


function TADCDataFile.RAWLoadHeader : Boolean ;
// -------------------------
// Initialise RAW data file
// -------------------------
var
   i,ch : Integer ;
   NumDataBytesInFile : Integer ;
   Buf : Array[1..512] of Char ;
   iEnd : Integer ;
   s : String ;
begin

     Result := False ;

     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;

     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordAnalysisBytes := 0 ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

     // Determine no. of records in file
     NumDataBytesInFile := FileSeek( FileHandle, 0, 2 ) - FNumHeaderBytes ;
     FNumRecords := NumDataBytesInFile div FNumRecordBytes ;
     if (FNumRecords*FNumRecordBytes) < NumDataBytesInFile then Inc(FNumRecords) ;

     for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
     FADCOffset := 0 ;
     UseTempFile := False ;

     FADCVoltageRange := FChannelADCVoltageRange[0] ;
     if FADCVoltageRange = 0.0 then FADCVoltageRange := 1.0 ;

     for ch := 0 to FNumChannelsPerScan-1 do begin
         if FChannelScale[ch] = 0.0 then FChannelScale[ch] := 1.0 ;
         FChannelZero[ch] := 0 ;
         FChannelZeroAt[ch] := -1 ;
         FChannelGain[ch] := 1.0 ;
         FChannelOffset[ch] := ch ;
         if FChannelADCVoltageRange[ch] = 0.0 then
            FChannelADCVoltageRange[ch] := FADCVoltageRange ;
         FChannelCalibrationFactor[ch] := CalibFactor( ch ) ;
         end ;

     FIdentLine := '' ;

     FileSeek( FileHandle, 0,0) ;
     fileRead( FileHandle, Buf, 512 ) ;

     s := '' ;
     for i := 1 to 512 do s := s + Buf[i] ;
     IEnd := Pos( '001', s ) + 3  ;
     ShowMessage( format('%d',[iend]) ) ;
     Result := True ;

     end ;


function TADCDataFile.IBWLoadFileHeader : Boolean ;
// -------------------------------------------------
// Read file header block from IGOR binary wave file
// -------------------------------------------------
var
     IGORBinHeader1 : TIGORBinHeader1 ;
     IGORBinHeader2 : TIGORBinHeader2 ;
     IGORBinHeader3 : TIGORBinHeader3 ;
     IGORBinHeader5 : TIGORBinHeader5 ;
     IGORWaveHeader2 : TIGORWaveHeader2 ;
     IGORWaveHeader5 : TIGORWaveHeader5 ;

     i : Integer ;
     ch : Integer ;
     //NumDataBytes : Integer ;
     VersionNum : SmallInt ;
     Value : Single ;
     MaxValue : Array[0..MAXDIMS-1] of Single ;
     //OK : Boolean ;
begin
    Result := False ;
    // Read first 2 bytes to determine IBW file version number
    FileSeek( FileHandle, 0, 0 ) ;
    if FileRead(FileHandle,VersionNum,Sizeof(VersionNum))
       <> Sizeof(VersionNum) then begin
       Exit ;
       end ;

    // Read binary file header

    FileSeek( FileHandle, 0, 0 ) ;
    case VersionNum of
         1 : begin
             FileRead(FileHandle,IGORBinHeader1,Sizeof(IGORBinHeader1)) ;
             if FileRead(FileHandle,IGORWaveHeader2,Sizeof(IGORWaveHeader2))
             <> Sizeof(IGORWaveHeader2) then Exit ;
             end ;
         2 : begin
             FileRead(FileHandle,IGORBinHeader2,Sizeof(IGORBinHeader2)) ;
             if FileRead(FileHandle,IGORWaveHeader2,Sizeof(IGORWaveHeader2))
             <> Sizeof(IGORWaveHeader2) then Exit ;
             end ;
         3 : begin
             FileRead(FileHandle,IGORBinHeader3,Sizeof(IGORBinHeader3)) ;
             if FileRead(FileHandle,IGORWaveHeader2,Sizeof(IGORWaveHeader2))
             <> Sizeof(IGORWaveHeader2) then Exit ;
             end ;
         5 : begin
             FileRead(FileHandle,IGORBinHeader5,Sizeof(IGORBinHeader5)) ;
             if FileRead(FileHandle,IGORWaveHeader5,Sizeof(IGORWaveHeader5))
             <> Sizeof(IGORWaveHeader5) then Exit ;
             end ;
          end ;

    // Determine size of file header from current file pointer position
    FNumHeaderBytes :=  FileSeek( FileHandle, 0,1 ) ;

    if VersionNum < 5 then begin

       // IBW file Versions 1-4
       Case IGORWaveHeader2.WaveType of
            NT_I8 : begin
                  FNumBytesPerSample := 1 ;
                  FMaxADCValue := 127 ;
                  FFloatingPointSamples := False ;
                  end ;
            NT_I16 : begin
                  FNumBytesPerSample := 2 ;
                  FMaxADCValue := 32767 ;
                  FFloatingPointSamples := False ;
                  end ;
            NT_I32 : begin
                  FNumBytesPerSample := 4 ;
                  FMaxADCValue := 32767 ;
                  FFloatingPointSamples := False ;
                  end ;
            NT_FP32 : begin
                  FNumBytesPerSample := 4 ;
                  FMaxADCValue := 32767 ;
                  FFloatingPointSamples := True ;
                  end ;
            end ;
       FADCVoltageRange := 1.0 ;
       FNumChannelsPerScan := 1 ;
       FScanInterval := IGORWaveHeader2.hsA ;
       FNumScansPerRecord := IGORWaveHeader2.npnts ;
       FNumRecords := 1 ;
       FChannelOffset[0] := 0 ;
       FChannelGain[0] := 1. ;
       FChannelADCVoltageRange[0] := FADCVoltageRange ;
	     FChannelZero[0] := 0 ;
       FChannelUnits[0] := String(IGORWaveHeader2.dataUnits) ;
       FChannelName[0] := 'Ch0' ;
       if IGORWaveHeader2.fsValid <> 0 then
          FChannelScale[0] := IGORWaveHeader2.topFullScale / (FMaxADCValue+1)
       else FChannelScale[0] := 1.0 ;
       FChannelCalibrationFactor[0] := CalibFactor( 0 ) ;
       end
    else begin
       // IBW file Version 5
       // (1-4 signal channels per file)
       Case IGORWaveHeader5.WaveType of
            NT_I8 : begin
                  FNumBytesPerSample := 1 ;
                  FMaxADCValue := 127 ;
                  FFloatingPointSamples := False ;
                  end ;
            NT_I16 : begin
                  FNumBytesPerSample := 2 ;
                  FMaxADCValue := 32767 ;
                  FFloatingPointSamples := False ;
                  end ;
            NT_I32 : begin
                  FNumBytesPerSample := 4 ;
                  FMaxADCValue := 32767 ;
                  FFloatingPointSamples := False ;
                  end ;
            NT_FP32 : begin
                  FNumBytesPerSample := 4 ;
                  FFloatingPointSamples := True ;
                  end ;
            end ;

       // Determine number of channels and scans per channel
       FNumChannelsPerScan := 1 ;
       FNumScansPerRecord := IGORWaveHeader5.nDim[0] ;

       FADCVoltageRange := 1.0 ;
       FScanInterval := IGORWaveHeader5.sFa[0] ;
       FChannelOffset[0] := 0 ;
       FChannelGain[0] := 1. ;
       FChannelADCVoltageRange[0] := FADCVoltageRange ;
       FChannelZero[0] := 0 ;
       FChannelUnits[0] := String(IGORWaveHeader5.dataUnits) ;
       FChannelName[0] := 'Ch.0' ;
       FChannelScale[0] := IGORWaveHeader5.topFullScale / (FMaxADCValue+1) ;
       FChannelCalibrationFactor[0] := CalibFactor( 0 ) ;
       end ;

   // If data in floating point format, establish FP-integer scale factor
   if FFloatingPointSamples then begin
      for ch := 0 to FNumChannelsPerScan-1 do MaxValue[ch] := 0.0 ;
      for i := 0 to FNumScansPerRecord do begin
          for ch := 0 to FNumChannelsPerScan-1 do begin
              FileRead( FileHandle, Value, SizeOf(Value) ) ;
              Value := Abs(Value) ;
              if Value >= MaxValue[ch] then MaxValue[ch] := Value ;
              end ;
          end ;

      for ch := 0 to FNumChannelsPerScan-1 do begin
          if MaxValue[ch] = 0.0 then MaxValue[ch] := FMaxADCValue+1 ;
          FChannelScale[ch] := (MaxValue[ch]*1.2) / (FMaxADCValue+1) ;
          FChannelCalibrationFactor[ch] := CalibFactor( ch ) ;
          FADCScale[ch] := 1.0 / FChannelScale[ch] ;
          end ;

      end ;

    FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;

    FIdentLine := '' ;

    FNumRecords := 1 ;
    FNumBytesPerScan := FNumBytesPerSample*FNumChannelsPerScan ;
    FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
    FNumRecordAnalysisBytes := 0 ;
    FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

    UseTempFile := False ;

    Result := True ;

    end ;


function TADCDataFile.IBWSaveFileHeader : Boolean ;
// -----------------------------------------------
// Save file header block to IGOR Binary Wave file
// -----------------------------------------------
var
     IGORBinHeader5 : TIGORBinHeader5 ;
     IGORWaveHeader5 : TIGORWaveHeader5 ;
     //i : Integer ;
     //ch : Integer ;
     //s : string ;
     CheckSum : Integer ;
begin

    // Set allocated memory to zero
    ZeroMem( @IGORBinHeader5, SizeOf(IGORBinHeader5) ) ;

	  IGORBinHeader5.Version := 5  ;// Version number
	  IGORBinHeader5.WfmSize := SizeOf(IGORWaveHeader5)
                              + FNumScansPerRecord*FNumRecords*4 ;

    // Set allocated memory to zero
    ZeroMem( @IGORWaveHeader5, SizeOf(IGORWaveHeader5) ) ;

    // Save as 32 bit floating point
 	  IGORWaveHeader5.WaveType := NT_FP32 ;

    // Create wave name
    FillCharArray( ANSIReplaceSTR(ExtractFileName(FFileName),'.ibw',''),
                   IGORWaveHeader5.bname,
                   True) ;

	  IGORWaveHeader5.npnts := FNumScansPerRecord*FNumRecords ;

    // Row dimension ((no. of sample time points)
    IGORWaveHeader5.nDim[0] := FNumScansPerRecord*FNumRecords ;

    // Inter-sample interval (s)
    IGORWaveHeader5.sFA[0] := FScanInterval ;
    IGORWaveHeader5.sFB[0] := 0.0 ;
    IGORWaveHeader5.dimUnits[0,0] := 's' ;

    // Data units
    FillCharArray( FChannelUnits[0], IGORWaveHeader5.dataUnits, True ) ;

    // Calculate checksum

    Checksum := 0 ;
    Checksum := IGORChecksum( @IGORBinHeader5,
                              Checksum,
                              Sizeof(IGORBinHeader5)) ;

    Checksum := IGORChecksum( @IGORWaveHeader5,
                                Checksum,
                                Sizeof(IGORWaveHeader5));

    IGORBinHeader5.Checksum := -Checksum ;

    { Write header block }
    FileSeek( FileHandle, 0, 0 ) ;
    FileWrite(FileHandle,IGORBinHeader5,Sizeof(IGORBinHeader5)) ;
    if FileWrite(FileHandle,IGORWaveHeader5,Sizeof(IGORWaveHeader5))
       <> Sizeof(IGORWaveHeader5) then
       ShowMessage( 'Error writing header to ' + FileName ) ;

    UseTempFile := False ;

    end ;


function TADCDataFile.IGORChecksum(
         pData : Pointer ;
         OldCkSum : Integer ;
         NumBytes : Integer
         ) : Integer ;
// 	Returns shortwise simpleminded checksum over the data.
//	ASSUMES data starts on an even boundary.
type
    TSmallIntArray = Array[0..99999999] of SmallInt ;
    PSmallIntArray = ^TSmallIntArray ;
var
    i : Integer ;
begin
  NumBytes := NumBytes div 2 ;
  for i := 0 to NumBytes-1 do OldCkSum := OldCkSum + PSmallIntArray(pData)^[i] ;
  Result := OldCkSum and $ffff ;
  end ;


function TADCDataFile.PNMLoadFile : Boolean ;
// -------------------------------------------
// Load PoNeMah data file
type
    TJumpRecord = packed record
        ID : byte ;
        ElapsedTime : Single ;
        FilePosition : Single ;
        end ;
    TSingleArray = Array[0..1] of Single ;
const
    MaxBlockSize = 65536 ;
    OutBufSize = 256 ;
var
    PNMHeader : TPoNeMahHeader ;
    PNMBlockHeader : TPoNeMahBlockHeader ;
    i, j, iIn, iOut : Integer ;
    ch,InCh,OutCh : Integer ;
    Items : Array[0..15] of String ;
    NumItems : Integer ;
    Key : String ;
    NumChannels : Integer ;
    ix  : Integer ;
    Chan : Integer ;
    Done : Boolean ;
    EOF : Boolean ;
    ChannelEnabled : Boolean ;
    s : String ;
    MaxDivideFactor  : Integer ;
    DivideFactor : Array[0..ChannelLimit] of Integer ;
    ChannelList : Array[0..511] of Integer ;
    EndOfChannelList : Integer ;
    LatestValue : Array[0..ChannelLimit] of SmallInt ;
    InBuf : Array[0..MaxBlockSize-1] of Byte ;
    OutBuf : Array[0..(MaxBlockSize*2)-1] of SmallInt ;
    JumpList : Array[0..19999] of TJumpRecord ;
    bbuf : array[0..65535] of Byte ;
    NumBlocks : Integer ;
    NumBytes : Integer ;
    iBlock  : Integer ;
    iStart  : Integer ;
    NumScans  : Array[0..ChannelLimit] of Integer ;
    ChannelSign  : Array[0..ChannelLimit] of Integer ;
    MaxScans  : Integer ;
    iList : Integer ;
    Temp : Byte ;
    NumScansInFile : Integer ;
    iKeepList : Integer ;
    DivideCounter : Integer ;
    ChannelCounter : Integer ;
    PreviousElapsedTime : Integer ;
    FilePointer : Integer ;
    NumBytesInFile : Integer ;
    CalValueHi : Single ;
    CalValueLo  : Single ;
    ADCValueHi : Single ;
    ADCValueLo : Single ;
    NumSamplesInList : Integer ;
    NumSamplesTotal : Integer ;
    iNewKeepList  : Integer ;
    Start : Boolean ;

    ii : Array[0..1] of Integer ;

begin

    // Open file as text file
    FileSeek( FileHandle, 0, 0 ) ;

    // Find number of channels in protocol file

    Key := 'NUMBERCHANNELS:' ;
    Done := False ;
    While not Done do begin
        ASCReadLine( FileHandle,' ',s,Items,NumItems,EOF) ;
        ix := Pos( Key, s ) ;
        if ix > 0 then begin
           NumChannels := StrToInt(MidStr( s, ix + Length(Key), 1 )) ;
           Done := True ;
           end ;
        end ;

    FNumChannelsPerScan := 0 ;
    for Chan := 1 to NumChannels do begin

        // Find start of channel description
        Key := format( 'CHANNEL:%d', [Chan] ) ;
        Repeat
            ASCReadLine( FileHandle,' ',s,Items,NumItems,EOF) ;
            until Pos( Key, s ) > 0 ;

        // Determine if channel enabled
        ASCReadLine( FileHandle,' ',s,Items,NumItems,EOF) ;
        if StrToInt(Items[0]) > 0 then ChannelEnabled := True
                                  else ChannelEnabled := False ;

        // ?
        ASCReadLine( FileHandle,' ',s,Items,NumItems,EOF) ;

        // Sampling rate divisor
        ASCReadLine( FileHandle,' ',s,Items,NumItems,EOF) ;
        DivideFactor[FNumChannelsPerScan] := StrToInt(Items[1]) ;

        // Channel name
        ASCReadLine( FileHandle,' ',FChannelName[FNumChannelsPerScan],Items,NumItems,EOF) ;

        // Channel units
        ASCReadLine( FileHandle,' ',FChannelUnits[FNumChannelsPerScan],Items,NumItems,EOF) ;

        // Read calibration value
        ASCReadLine( FileHandle,' ',s,Items,NumItems,EOF) ;
        CalValueLo := StrToFloat(s) ;
        ASCReadLine( FileHandle,' ',s,Items,NumItems,EOF) ;
        CalValueHi := StrToFloat(s) ;
        ASCReadLine( FileHandle,' ',s,Items,NumItems,EOF) ;
        ADCValueLo := StrToFloat(Items[0]) ;
        ADCValueHi := StrToFloat(Items[1]) ;

        // Calculate channel scaling factor
        if ADCValueHi <> ADCValueLo then begin
           FChannelScale[FNumChannelsPerScan] := (CalValueHi - CalValueLo) /
                                                 (ADCValueHi - ADCValueLo) ;
           // Invert channel if negative scaling factor
           if FChannelScale[FNumChannelsPerScan] < 0.0 then begin
              ChannelSign[FNumChannelsPerScan] := -1 ;
              FChannelScale[FNumChannelsPerScan] := -FChannelScale[FNumChannelsPerScan] ;
              end
           else ChannelSign[FNumChannelsPerScan] := 1 ;
           end
        else begin
           FChannelScale[FNumChannelsPerScan] := 1.0 ;
           ChannelSign[FNumChannelsPerScan] := 1 ;
           end ;
           
        FChannelOffset[FNumChannelsPerScan] := FNumChannelsPerScan ;
        FChannelGain[FNumChannelsPerScan] := 1. ;
        FADCVoltageRange := 10.0 ;
        FChannelADCVoltageRange[FNumChannelsPerScan] :=  FADCVoltageRange ;

        FChannelCalibrationFactor[FNumChannelsPerScan] := CalibFactor(FNumChannelsPerScan) ;
	      FChannelZero[FNumChannelsPerScan] := 0 ;
        FChannelOffset[FNumChannelsPerScan] := FNumChannelsPerScan ;

        if ChannelEnabled then Inc(FNumChannelsPerScan) ;

        end ;

    // Find maximum divide factor
    MaxDivideFactor := 1 ;
    for ch := 0 to FNumChannelsPerScan-1 do
        if MaxDivideFactor < DivideFactor[ch] then MaxDivideFactor := DivideFactor[ch] ;

    // Set up channel scanning sequence list
    iList := 0 ;
    for j := 1 to MaxDivideFactor do begin
        for ch := 0 to FNumChannelsPerScan-1 do begin
            if (DivideFactor[ch] = 1) or
               (j = MaxDivideFactor) then begin
               ChannelList[iList] := ch ;
               Inc(iList) ;
               end ;
            end ;
        end ;
    NumSamplesInList :=  iList ;
    EndOfChannelList := NumSamplesInList-1 ;

    FNumBytesPerSample := 2 ;
    FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;

    // Load JMP list
    FileClose( FileHandle ) ;
    FileHandle := FileOpen( ChangeFileExt( FFileName, '.jmp' ), fmOpenRead ) ;
    NumBytes := FileSeek( FileHandle, 0, 2 ) ;
    NumBlocks := NumBytes div SizeOf(TJumpRecord) ;

    FileSeek( FileHandle, 0, 0 ) ;
    FileRead( FileHandle, bbuf, NumBytes ) ;
    for i := 0 to NumBlocks-1 do begin
        iStart := i*SizeOf(TJumpRecord) ;
        JumpList[i].ID := BBuf[iStart] ;
        JumpList[i].ElapsedTime := SwapByteOrder( bbuf, iStart+1, 4 ) ;
        JumpList[i].FilePosition := SwapByteOrder( bbuf, iStart+5, 4 ) ;
        end ;
    FileClose( FileHandle ) ;

    FileHandle := FileOpen( ChangeFileExt( FFileName, '.raw' ), fmOpenRead ) ;
    FileSeek( FileHandle, 0, 0 ) ;

    // Create a temporary file
    TempFileName := CreateTempFileName ;
    TempHandle := FileCreate( TempFileName ) ;
    FileSeek( TempHandle, 0, 0 ) ;

    // Read file header
    FileSeek( FileHandle, 0, 0 ) ;
    FileRead( FileHandle, PNMHeader, SizeOf(PNMHeader) ) ;

    NumScansInFile := 0 ;
    iKeepList := 0 ;
    DivideCounter := 0 ;
    ChannelCounter := 0 ;
    PreviousElapsedTime := -1 ;
    NumBytesInFile := FileSeek( FileHandle, 0, 2 ) ;
    FilePointer :=  423 ;
    NumSamplesTotal := 0 ;
    Done := False ;
    Start := False ;
    while not Done do begin

         // Read data header block
         //FileSeek( FileHandle, Round(JumpList[iBlock].FilePosition), 0 ) ;
         FileSeek( FileHandle, FilePointer, 0 ) ;
         if FileRead( FileHandle, bbuf, SizeOf(PNMBlockHeader)) <> SizeOf(PNMBlockHeader) then Break ;
         PNMBlockHeader.ElapsedTime := SwapByteOrder( bbuf, 0, 4 ) ;
         PNMBlockHeader.SampleClock := FloatSwapByteOrder( bbuf, 4 ) ;
         PNMBlockHeader.BlockSize := SwapByteOrder( bbuf, 8, 4 ) ;
         PNMBlockHeader.Group := SwapByteOrder( bbuf, 12,2 ) ;
         PNMBlockHeader.ChanRate := SwapByteOrder( bbuf, 14, 2 ) ;
         PNMBlockHeader.FirstChan := bbuf[17] ;

         //iKeepList := (NumSamplesTotal mod NumSamplesInList) ;
         outputdebugString(PChar(format('%d %d %d %d',[PNMBlockHeader.ElapsedTime,PNMBlockHeader.BlockSize,
                                 PNMBlockHeader.FirstChan,
                                 iKeepList])));

         NumSamplesTotal := NumSamplesTotal + PNMBlockHeader.BlockSize div 2 ;

         if (PNMBlockHeader.ElapsedTime - PreviousElapsedTime) > 5  then begin
            //if iKeepList < 6 then iKeepList := 0
            //else if iKeepList < 10 then iKeepList := 6
            //else if iKeepList < 14 then iKeepList := 10
            //else iKeepList := 14 ;
            iKeepList := 0 ;

            if Pos('a138.pro',LowerCase(FFileName)) > 0 then iKeepList := 0 ;
            if Pos('a138.pro',LowerCase(FFileName)) > 0 then iKeepList := 12 ;
            if Pos('a147.pro',LowerCase(FFileName)) > 0 then iKeepList := 4 ;
            if Pos('a148.pro',LowerCase(FFileName)) > 0 then iKeepList := 8 ;
            if Pos('a149.pro',LowerCase(FFileName)) > 0 then iKeepList := 4 ;
            if Pos('a150.pro',LowerCase(FFileName)) > 0 then iKeepList := 4 ;
            if Pos('a151.pro',LowerCase(FFileName)) > 0 then iKeepList := 0 ;
            if Pos('a152.pro',LowerCase(FFileName)) > 0 then iKeepList := 4 ;
            if Pos('a155.pro',LowerCase(FFileName)) > 0 then iKeepList := 0 ;
            if Pos('a159.pro',LowerCase(FFileName)) > 0 then iKeepList := 0 ;

            if Pos('a164.pro',LowerCase(FFileName)) > 0 then iKeepList := 4 ;
            if Pos('a165.pro',LowerCase(FFileName)) > 0 then iKeepList := 4 ;
            if Pos('a166.pro',LowerCase(FFileName)) > 0 then iKeepList := 4 ;
            if Pos('a167.pro',LowerCase(FFileName)) > 0 then iKeepList := 4 ;
            if Pos('a168.pro',LowerCase(FFileName)) > 0 then iKeepList := 8 ;
            if Pos('a169.pro',LowerCase(FFileName)) > 0 then iKeepList := 10 ;
            if Pos('a170.pro',LowerCase(FFileName)) > 0 then iKeepList := 12 ;
            if Pos('a171.pro',LowerCase(FFileName)) > 0 then iKeepList := 12 ;
            end ;


         PreviousElapsedTime := PNMBlockHeader.ElapsedTime ;

         // Read data
         FileSeek( FileHandle, 12, 1 ) ;
         FileRead( FileHandle, InBuf, PNMBlockHeader.BlockSize ) ;

         // Swap lo-hi bytes
         for i := 0 to PNMBlockHeader.BlockSize div 2 do begin
             j := i*2 ;
             Temp := InBuf[j] ;
             InBuf[j] := InBuf[j+1] ;
             InBuf[j+1] := Temp ;
             end ;

      {   iIn := 0 ;
         iOut := 0 ;
         ChannelCounter := 0 ;
         while iIn < PNMBlockHeader.BlockSize do begin
            if (DivideCounter = 0) or
               (DivideFactor[ChannelCounter] = 1) then begin
               OutBuf[iOut] := InBuf[iIn] ;
               OutBuf[iOut] := OutBuf[iOut] or (InBuf[iIn + 1] shl 8) ;
               LatestValue[ChannelCounter] := OutBuf[iOut] ;
               iIn := iIn + 2 ;
               end
            else begin
               OutBuf[iOut] := LatestValue[ChannelCounter] ;
               end ;
            Inc(iOut) ;
            Inc(ChannelCounter) ;
            if ChannelCounter >= FNumChannelsPerScan then begin
               ChannelCounter := 0 ;
               Inc(DivideCounter) ;
               if DivideCounter >= MaxDivideFactor then DivideCounter := 0 ;
               end ;
            end ;

         MaxScans := iOut div FNumChannelsPerScan ;}

         for ch := 0 to FNumChannelsPerScan-1 do begin
             iIn := 0 ;
             iOut := ch ;
             NumScans[ch] := 0 ;
             iList := iKeepList ;
             while iIn < (PNMBlockHeader.BlockSize div 2) do begin
                 if ChannelList[iList] = ch then begin
                    OutBuf[iOut] := InBuf[iIn*2] ;
                    OutBuf[iOut] := OutBuf[iOut] or (InBuf[iIn*2 + 1] shl 8) ;
                    OutBuf[iOut] := ChannelSign[ch]*OutBuf[iOut] ;
                    iOut := iOut + FNumChannelsPerScan*DivideFactor[ch] ;
                    LatestValue[ch] := OutBuf[iOut] ;
                    Inc(NumScans[ch]) ;
                    end ;
                 Inc(iList) ;
                 Inc(iIn) ;
                 if iList > EndOfChannelList then iList := 0 ;
                 end ;

             for i := 0 to FNumChannelsPerScan-1 do  begin
                 OutBuf[i+FNumChannelsPerScan*DivideFactor[ch]] :=
                     OutBuf[i+2*FNumChannelsPerScan*DivideFactor[ch]] ;
                 OutBuf[i] := OutBuf[i+FNumChannelsPerScan*DivideFactor[ch]] ;
                 end ;

             for i := 0 to NumScans[ch]-1 do begin
                 iOut := i*FNumChannelsPerScan*DivideFactor[ch] + ch ;
                 for j := 0 to DivideFactor[ch] - 1 do begin
                    OutBuf[iOut + j*FNumChannelsPerScan] := OutBuf[iOut] ;
                    end ;
                 end ;


             end ;

         MaxScans := High(MaxScans) ;
         for ch := 0 to FNumChannelsPerScan-1 do
            if DivideFactor[ch] = 1 then begin
             if MaxScans > NumScans[ch] then MaxScans := NumScans[ch] ;
             end ;

         iKeepList := iList ;
         //iKeepList := iNewKeepList ;

         FileWrite( TempHandle, OutBuf, (MaxScans)*FNumChannelsPerScan*2 ) ;

         for i := 0 to FNumChannelsPerScan-1 do  begin
             OutBuf[i] := LatestValue[i] ;
             end ;

         NumScansInFile := NumScansInFile + (MaxScans) ;

         FilePointer := FilePointer + PNMBlockHeader.BlockSize + 30 ;

         if FilePointer >= NumBytesInFile then Done := True ;

         end ;

    FFloatingPointSamples := False ;
    UseTempFile := True ;
    FNumHeaderBytes := 0 ;
    FNumBytesPerSample := 2 ;
    FNumScansPerRecord := 256 ;
    FNumRecords := NumScansInFile div  FNumScansPerRecord ;

    FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
    FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
    FNumRecordAnalysisBytes := 0 ;
    FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

	  FScanInterval := 0.001 ;
    FADCVoltageRange := 10.0 ;

    FMaxADCValue := 2047 ;
    FMinADCValue := -MaxADCValue - 1 ;

    FIdentLine := '' ;

    for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
    FADCOffset := 0 ;

    Result := True ;
    end ;


function TADCDataFile.HEKLoadFile : Boolean ;
// -------------------------------------------------
// Read ASCII data containing HEKA data to temp file
// -------------------------------------------------
const
     MaxColumns = ChannelLimit+2 ;
var
     NumItems : Integer ;
     Line : String ;
     NumScans : Integer ;
     Done : Boolean ;
     i : Integer ;
     Items : Array[0..MaxColumns-1] of String ;
     Value : Single ;
     TValue : Single ;
     LastTValue : Single ;
     MaxValue : Array[0..MaxColumns-1] of Single ;
     ch : Integer ;
     SepChar : Char ;
begin

     Result := False ;

     // Read 4th line in file (first line of data)
     FileSeek( FileHandle, 0, 0 ) ;
     for i := 1 to 4 do
         HEKReadLine( FileHandle, ' ', Line, Items, NumItems, Done ) ;

     // Determine item separator character
     if ANSIContainsText( Line, #9 ) then SepChar := #9
     else if ANSIContainsText( Line, ',' ) then SepChar := ','
     else SepChar := ' ' ;

     // Create a temporary file
     TempFileName := CreateTempFileName ;
     TempHandle := FileCreate( TempFileName ) ;

     // Convert from ASCII data to floating point and store in temporary file

     FileSeek( FileHandle, 0, 0 ) ;
     NumScans := 0 ;
     LastTValue := 0.0 ;
     for ch := 0 to MaxColumns-1 do MaxValue[ch] := 0.0 ;
     Done := False ;
     While not Done do begin

        // Read line of items from file
        HEKReadLine( FileHandle, SepChar, Line, Items, NumItems, Done ) ;
        if Done then Break ;

        // Process sweep header lines
        if ANSIContainsText(Line,'sweep') then begin
           // Get no. of time points per sweep
           HEKReadLine( FileHandle, ' ', Line, Items, NumItems, Done ) ;
           FNumScansPerRecord := ExtractInt( Items[0] ) ;
           // Get no. of channels and units
           HEKReadLine( FileHandle, ',', Line, Items, NumItems, Done ) ;
           FNumChannelsPerScan := NumItems-1 ;
           for ch := 0 to FNumChannelsPerScan-1 do begin
               if ANSIContainsText(Items[ch+1],'[a]') then FChannelUnits[ch] := 'A'
               else if ANSIContainsText(Items[ch+1],'[a]') then FChannelUnits[ch] := 'A'
               else if ANSIContainsText(Items[ch+1],'[v]') then FChannelUnits[ch] := 'V'
               else if ANSIContainsText(Items[ch+1],'[mv]') then FChannelUnits[ch] := 'mV' ;
               end ;
           end
        else if NumItems > 1 then begin
           // Write time point data to temp. file
           //ch := 0 ;
           for ch := 0 to FNumChannelsPerScan-1 do begin
               Value := ExtractFloat( Items[ch+1],0.0 ) ;
               if Abs(Value) > MaxValue[ch] then MaxValue[ch] := Abs(Value) ;
               FileWrite( TempHandle, Value, SizeOf(Value) ) ;
               end ;

           // Calculate sampling interval and record length
           TValue := ExtractFloat( Items[0],0.0 ) ;
           if TValue > LastTValue then FScanInterval := TValue - LastTValue ;
           LastTValue := TValue ;
           Inc(NumScans) ;
           end ;

        end ;

     FNumRecords := Max(NumScans div FNumScansPerRecord,1) ;

     FFloatingPointSamples := True ;

     FNumBytesPerSample := 4 ;
     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;

     { Get byte offset of data section }
     FNumHeaderBytes :=  0 ;
     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordAnalysisBytes := 0 ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

     FADCVoltageRange := 10.0 ;
     FMaxADCValue := 32767 ;
     FMinADCValue := -FMaxADCValue - 1 ;
     for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
     FADCOffset := 0 ;
     UseTempFile := True ;

     for ch := 0 to FNumChannelsPerScan-1 do begin

        // Scaling and offset factors
        if MaxValue[ch] > 0.0 then
           FADCScale[ch] := FMaxADCValue / (1.1*MaxValue[ch])
        else FADCScale[ch] := 1.0 ;

        FChannelName[ch] := format('Ch.%d',[ch]) ;
        FChannelScale[ch] := 1.0 / FADCScale[ch] ;
          { Calculate calibration factors }
        FChannelGain[ch] := 1. ;
        FChannelADCVoltageRange[ch] := 10.0 ;
        FChannelCalibrationFactor[ch] := CalibFactor( ch ) ;
        FChannelZero[ch] := 0 ;

        { Offset into groups of A/D samples for this channel }
        FChannelOffset[ch] := ch ;

        end ;
     FIdentLine := '' ;

     end ;


procedure TADCDataFile.HEKReadLine(
         FileHandle : Integer ;       // Handle of file being read
         ItemSeparator : Char ;       // Item separator character
         var Line : String ;          // Returns full line read
         var Items : Array of String ;// Returns items within line
         var NumItems : Integer ;      // Returns no. of items
         var EOF : Boolean ) ;        // Returns True if at end of file
// ----------------------------------------------------------
// Read and extract data from a line in a HEKA text data file
// ----------------------------------------------------------
var
    Done : Boolean ;
    InChar : Char ;
    i : Integer ;
    s : String ;
begin

    //Done := False ;
    EOF := False ;
    NumItems := 0 ;
    Line := '' ;
    for i := 0 to High(Items) do Items[i] := '' ;

    // Read line from file
    // -------------------

    Done := False ;
    while not Done do begin

        // Read character
        if FileRead( FileHandle, InChar, 1 ) <> 1 then begin
           EOF := True ;
           Break ;
           end ;

        if InChar = #10 then Done := True  // Line ended by LF
        else if InChar = #13 then begin
           // Line ended by CR
           // Discard LF (if one exists)
           if FileRead(FileHandle,InChar,1) = 1 then begin
              if InChar <> #10 then FileSeek( FileHandle, -1, 1 ) ;
              end ;
           Done := True ;
           end
        else Line := Line + InChar ;

        end ;

    // Remove all instances of multiple separators
    s := ItemSeparator + ItemSeparator ;
    While ANSIContainsText( Line, s ) do
        Line := ANSIReplaceText(Line, s,ItemSeparator) ;

    NumItems := 0 ;
    for i := 1 to Length(Line) do begin

        if Line[i] = ItemSeparator then begin
           // Item separator - increment to next item
           if Length(Items[NumItems]) > 0 then Inc(NumItems) ;
           end
        else begin
           Items[NumItems] := Items[NumItems] + Line[i] ;
           end ;
        end ;

    // Add last item to count
    if Length(Items[NumItems]) > 0 then Inc(NumItems) ;

    end ;




function TADCDataFile.SwapByteOrder(
         Buf : Array of Byte ;
         iStart : Integer ;
         NumBytes : Integer
         ) : Integer ;
var
  i : SmallInt ;
begin
    if NumBytes = 4 then begin
       Result := Buf[iStart+3] +
                 (Buf[iStart+2] shl 8) +
                 (Buf[iStart+1] shl 16) +
                 (Buf[iStart] shl 24) ;
       end
    else begin
       i := Buf[iStart+1] ;
       i := i or (Buf[iStart] shl 8) ;
       //if i > 2047 then i := 2047 - i ;
       //if i > 127 then i := 127 - i ;
       Result := Integer(i) ;
       end
    end ;


function TADCDataFile.FloatSwapByteOrder(
         Buf : Array of Byte ;
         iStart : Integer
         ) : Single ;
var
  //i : SmallInt ;
  pBuf : Pointer ;
begin

    GetMem( pBuf, 4 ) ;
    pByteArray(pBuf)[0] := Buf[iStart+3] ;
    pByteArray(pBuf)[1] := Buf[iStart+2] ;
    pByteArray(pBuf)[2] := Buf[iStart+1] ;
    pByteArray(pBuf)[3] := Buf[iStart] ;
    Result := PSingle(pBuf)^ ;
    FreeMem( pBuf ) ;

    end ;



function TADCDataFile.ExtractItems(
         TextLine : String ;
         Separator : Char ;
         var Items : Array of String ) : Integer ;
// ------------------------------------------------------------------------
// Extract list of items separated by <Separator> character from <TextLine>
// ------------------------------------------------------------------------
var
     NumItems : Integer ;
     iC,i : Integer ;
begin

     NumItems := 0 ;
     iC := 1 ;
     for i := 0 to High(Items) do Items[i] := '' ;
     While iC < Length(TextLine) do begin
          if TextLine[iC] <> ' ' then begin
             Items[NumItems] := Items[NumItems] + TextLine[iC] ;
             end
          else Inc(NumItems) ;
          Inc(iC) ;
          end ;
     Result := NumItems + 1 ;
     end ;


function TADCDataFile.CHTLoadFileHeader : Boolean ;
// -------------------------------------------
// Read file header block from CHT data file
// -------------------------------------------
var
   Header : array[1..CHTFileHeaderSize] of char ;
   i,ch : Integer ;
   NumSamplesInFile : Integer ;
   NumMarkers : Integer ;
   MarkerTime : Single ;
   MarkerText : String ;
begin

     Result := False ;

     // Load file header data
     FileSeek( FileHandle, 0, 0 ) ;
     if FileRead( FileHandle, Header, Sizeof(Header) )<> Sizeof(Header) then Exit ;

     { Get default size of file header }
     FNumHeaderBytes := CHTFileHeaderSize ;

     ReadInt( Header, 'NC=', FNumChannelsPerScan ) ;

     FMaxADCValue := 0 ;
     ReadInt( Header, 'ADCMAX=', FMaxADCValue ) ;
     if MaxADCValue = 0 then FMaxADCValue := 2047 ;
     FMinADCValue := -FMaxADCValue - 1 ;

     { Calculate number of samples in file from file length }

     ReadInt( Header, 'NC=', FNumChannelsPerScan ) ;
     FFloatingPointSamples := False ;
     FNumBytesPerSample := 2 ;
     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;

     ReadInt( Header, 'NS=', NumSamplesInFile ) ;
     FNumScansPerRecord := NumSamplesInFile div FNumChannelsPerScan ;
     FNumRecords := 1 ;
     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordAnalysisBytes := 0 ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

     ReadFloat( Header, 'AD=',FADCVoltageRange);

     ReadFloat( Header, 'DT=', FScanInterval );

     for ch := 0 to FNumChannelsPerScan-1 do begin

         ReadInt( Header, format('YO%d=',[ch]), FChannelOffset[ch]) ;

         FChannelUnits[ch] := '' ;
         ReadString( Header, format('YU%d=',[ch]) , FChannelUnits[ch] ) ;
         { Fix to avoid strings with #0 in them }
         if FChannelUnits[ch] = #0 then FChannelUnits[ch] := '' ;

         FChannelName[ch] := 'Ch' + IntToStr(ch) ;
         ReadString( Header, format('YN%d=',[ch]), FChannelName[ch] ) ;
         { Fix to avoid strings with #0 in them }
         if FChannelName[ch] = chr(0) then FChannelName[ch] := '' ;

         // Offset for A/D sample within multi-channel scan
         FChannelOffset[ch] := FNumChannelsPerScan - ch - 1 ;
         ReadInt( Header, format('YO%d=',[ch]), FChannelOffset[ch] ) ;

         // Channel scaling factor
         ReadFloat( Header, format('YS%d=',[ch]), FChannelScale[ch]) ;

         FChannelGain[ch] := 1.0 ;
         // Channel voltage range
         FChannelADCVoltageRange[ch] := 0.0 ;
         ReadFloat( Header, format('YC%d=',[ch]), FChannelADCVoltageRange[ch]) ;
         if FChannelADCVoltageRange[ch] = 0.0 then FChannelADCVoltageRange[ch] := FADCVoltageRange ;

         // Calculate calib factor from scale factor
         FChannelCalibrationFactor[ch] := CalibFactor( ch ) ;

         ReadInt( Header, format('YZ%d=',[ch]), FChannelZero[ch]) ;

         FChannelZeroAt[ch] := -1 ;
         end ;

     { Experiment identification line }
     ReadString( Header, 'ID=', FIdentLine ) ;

     { Read Markers }
     NumMarkers := 0 ;
     ReadInt( Header, 'MKN=', NumMarkers ) ;
     FMarkerList.Clear ;
     for i := 0 to NumMarkers-1 do begin
         ReadFloat( Header, format('MKTIM%d=',[i]), MarkerTime ) ;
         ReadString( Header, format('MKTXT%d=',[i]), MarkerText ) ;
         FMarkerList.AddObject( MarkerText, TObject(MarkerTime) ) ;
         end ;

    { Event detector parameters }
    FEDREventDetectorChannel := 0 ;
    FEDREventDetectorRecordSize := 512 ;
    FEDREventDetectorYThreshold := 100 ;
    FEDREventDetectorTThreshold := 0.1 ;
    FEDREventDetectorDeadTime := 1.0 ;
    FEDREventDetectorBaselineAverage := 512 ;
    FEDREventDetectorPreTriggerPercentage := 25.0 ;

    FEDRVarianceRecordSize := 512 ;
    FEDRVarianceRecordOverlap := 0 ;
    FEDRVarianceTauRise := 1E-3 ;
    FEDRVarianceTauDecay := 1E-2 ;

    FEDRUnitCurrent := 1.0 ;
    FEDRDwellTimesThreshold := 0.5 ;

    { Name of any associated WCP data file }
    FEDRWCPFileName := '' ;

    { Save the original file backed up flag }
    FEDRBackedUp := False ;

    for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
    FADCOffset := 0 ;
    UseTempFile := False ;

    Result := True ;
    end ;


function TADCDataFile.CHTSaveFileHeader : Boolean ;
// -------------------------------------------
// Write file header block to CHT data file
// -------------------------------------------
var
   Header : array[1..EDRFileHeaderSize] of char ;
   i,ch : Integer ;
   NumSamplesInFile : Integer ;
   MarkerTime : Single ;
   MarkerText : String ;
   CHTVoltageRange : Single ;
   CHTCalibFactor : Single ;
begin

     Result := False ;
     if FileHandle < 0 then Exit ;

     for i := 1 to High(Header) do Header[i] := #0 ;

     AppendFloat( Header, 'VER=',7.0);

     // Upper/lower limits of A/D sample integer value range
     AppendInt( Header, 'ADCMAX=', FMaxADCValue ) ;
     AppendInt( Header, 'ADCMin=', -FMaxADCValue-1 ) ;
     // Upper/lower limits of D/A integer value range
     AppendInt( Header, 'DACMAX=', FMaxADCValue ) ;
     AppendInt( Header, 'DACMIN=', -FMaxADCValue-1 ) ;

     AppendInt( Header, 'NC=', FNumChannelsPerScan ) ;

     NumSamplesInFile := FNumScansPerRecord * FNumChannelsPerScan ; ;
     AppendInt( Header, 'NS=', NumSamplesInFile ) ;

     AppendFloat( Header, 'AD=',FADCVoltageRange);

     AppendFloat( Header, 'DT=', FScanInterval );

     AppendFloat( Header, 'TD=',10.0 ) ;
     AppendFloat( Header, 'DF=',1.0 ) ;
     AppendFloat( Header, 'TZ=', 0.0 ) ;

     CHTVoltageRange := 5.0 ;
     for ch := 0 to FNumChannelsPerScan-1 do begin
         AppendFloat( Header, format('AD%d=',[ch]), CHTVoltageRange ) ;
         AppendString( Header, format('YU%d=',[ch]), FChannelUnits[ch] ) ;
         AppendString( Header, format('YN%d=',[ch]), FChannelName[ch] ) ;
         AppendFloat( Header, format('YS%d=',[ch]), FChannelScale[ch] ) ;
         CHTCalibFactor := CHTVoltageRange /
                           (FChannelGain[ch]*FChannelScale[ch]*FMaxADCValue) ;
         AppendFloat( Header, format('YC%d=',[ch]), CHTCalibFactor ) ;
         AppendFloat( Header, format('YG%d=',[ch]), FChannelGain[ch]) ;
         AppendInt( Header, format('YZ%d=',[ch]), FChannelZero[ch] ) ;
         AppendFloat( Header, format('YMAX%d=',[ch]), FMaxADCValue ) ;
         AppendFloat( Header, format('YMIN%d=',[ch]), -FMaxADCValue-1 ) ;
         AppendInt( Header, format('YO%d=',[ch]), FChannelOffset[ch] ) ;
         AppendFloat( Header, format('YB%d=',[ch]), 1.0 ) ;
         AppendFloat( Header, format('YV%d=',[ch]), 1.0 ) ;

         end ;

     { Experiment identification line }
     AppendString( Header, 'ID=', FIdentLine ) ;

     { Save RMS & HR processor setting }
     AppendInt( Header, 'FCRMS=', 0 ) ;
     AppendInt( Header, 'TCRMS=', 0 ) ;
     AppendInt( Header, 'AVRMS=', 10 ) ;
     AppendLogical( Header, 'IURMS=', False ) ;
     AppendInt( Header, 'FCHR=', 0 ) ;
     AppendInt( Header, 'TCHR=', 0 ) ;
     AppendFloat( Header, 'THHR=', 50.0 ) ;
     AppendFloat( Header, 'MAXHR=', 300 ) ;
     AppendLogical( Header, 'IUHR=', False ) ;
     AppendLogical( Header, 'DSPHR=', False ) ;

     { Write Markers }
     AppendInt( Header, 'MKN=', FMarkerList.Count ) ;
     FMarkerList.Clear ;
     for i := 0 to FMarkerList.Count-1 do begin
         MarkerTime := Single(FMarkerList.Objects[i]) ;
         MarkerText := FMarkerList.Strings[i] ;
         AppendFloat( Header, format('MKTIM%d=',[i]), MarkerTime ) ;
         AppendString( Header, format('MKTXT%d=',[i]), MarkerText ) ;
         end ;

    FileSeek( FileHandle, 0, 0 ) ;
    if FileWrite( FileHandle, Header, Sizeof(Header) )
       <> Sizeof(Header) then begin
       ShowMessage( FFileName + ' File Header Write - Failed ' ) ;
       Exit ;
       end ;

    for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
    FADCOffset := 0 ;
    UseTempFile := False ;

    Result := True ;
    end ;


function TADCDataFile.WAVLoadFileHeader : Boolean ;
// -------------------------------------------
// Read file header block from WAV data file
// -------------------------------------------
var
   ch : Integer ;
   RIFFHeader : TRIFFHeader ;
   FormatChunk : TWaveFormatChunk ;
   DataChunk : TWaveDataChunk ;
   DataChunkFound : Boolean ;
   ChunkID : Array[0..3] of Char ;
   ChunkSize : Cardinal ;
begin

     Result := False ;

     // Load file header data
     FileSeek( FileHandle, 0, 0 ) ;

     // Read file header

     FileRead( FileHandle, RIFFHeader, SizeOf(RIFFHeader) ) ;
     if (CharacterArrayToString(RIFFHeader.ID) <> 'RIFF') or
        (CharacterArrayToString(RIFFHeader.Format) <> 'WAVE') then begin
        ShowMessage( 'WAV File: File header incorrect!' ) ;
        Exit ;
        end ;

     // Read format chunk
     FileRead( FileHandle, FormatChunk, SizeOf(FormatChunk)) ;
     if Pos('fmt',CharacterArrayToString(FormatChunk.ID)) <= 0 then begin ;
        ShowMessage( 'WAV File: Format chunk missing!' ) ;
        Exit ;
        end ;

     if FormatChunk.AudioFormat <> 1 then begin
        ShowMessage( 'WAV File: Unable to read compressed format!' ) ;
        Exit ;
        end ;

     // Find data chunk

     DataChunkFound := False ;
     FileSeek( FileHandle,
               SizeOf(RIFFHeader) +
               SizeOf(ChunkID) +
               Sizeof(ChunkSize) +
               FormatChunk.ChunkSize, 0 ) ;
     repeat
        // Read ID and size of chunk
        if FileRead(FileHandle, ChunkID, SizeOf(ChunkID)) <> SizeOf(ChunkID) then Break ;
        if FileRead( FileHandle, ChunkSize, SizeOf(ChunkSize)) <> SizeOf(ChunkSize) then Break ;

        // Check if it is data chunk
        if Pos('data',CharacterArrayToString(ChunkID)) > 0 then begin
           // Data chunk found - Move pointer back to start of data chunk
           DataChunkFound := True ;
           FileSeek( FileHandle, -8, 1 ) ;
           end
        else begin
           // Move file pointer to beginning of next chunk
           FileSeek( FileHandle, ChunkSize, 1 ) ;
           end ;
        until DataChunkFound ;

     if not DataChunkFound then begin
        ShowMessage( 'WAV File: Unable to find data chunk!' ) ;
        Exit ;
        end ;

     // Read data chunk
     FileRead( FileHandle, DataChunk, SizeOf(DataChunk)) ;

     { Get default size of file header }
     FNumHeaderBytes := FileSeek( FileHandle, 0, 1 ) ;

     FNumChannelsPerScan := FormatChunk.NumChannels ;

     FMaxADCValue := Round(Power(2,FormatChunk.BitsPerSample-1)) ;
     FMinADCValue := -FMaxADCValue - 1 ;

     FFloatingPointSamples := False ;
     FNumBytesPerScan := FormatChunk.BlockAlign ;
     FNumBytesPerSample := FNumBytesPerScan  div FNumChannelsPerScan ;

     FNumScansPerRecord := DataChunk.ChunkSize div FNumBytesPerScan ;
     FNumRecords := 1 ;
     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordAnalysisBytes := 0 ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;

     FADCVoltageRange := 10.0 ;

     FScanInterval := 1.0/FormatChunk.SampleRate ;

     for ch := 0 to FNumChannelsPerScan-1 do begin

         FChannelOffset[ch] := ch ;

         FChannelUnits[ch] := 'V' ;
         FChannelName[ch] := 'Ch' + IntToStr(ch) ;

         FChannelGain[ch] := 1.0 ;
         FChannelADCVoltageRange[ch] := FADCVoltageRange ;

         // Calculate calib factor from scale factor
         FChannelCalibrationFactor[ch] := CalibFactor( ch ) ;

         FChannelZero[ch] := 0 ;

         FChannelZeroAt[ch] := -1 ;
         end ;

     { Experiment identification line }
     FIdentLine := '' ;

    for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
    FADCOffset := 0 ;
    UseTempFile := False ;

    Result := True ;

    end ;


function TADCDataFile.WAVSaveFileHeader : Boolean ;
// -------------------------------------------
// Save file header block to WAV data file
// -------------------------------------------
var
   ch : Integer ;
   RIFFHeader : TRIFFHeader ;
   FormatChunk : TWaveFormatChunk ;
   DataChunk : TWaveDataChunk ;
   //ChunkID : Array[0..3] of Char ;
   //ChunkSize : Cardinal ;
begin

     //Result := False ;

     // Create & write file header
     FileSeek( FileHandle, 0, 0 ) ;
     StringToCharacterArray( 'RIFF', RIFFHeader.ID ) ;
     StringToCharacterArray( 'WAVE', RIFFHeader.Format ) ;
     FileWrite( FileHandle, RIFFHeader, SizeOf(RIFFHeader) ) ;

     // Create and write format chunk
     StringToCharacterArray( 'fmt ', FormatChunk.ID ) ;
     FormatChunk.ChunkSize := SizeOf(FormatChunk) - 8 ;
     FormatChunk.AudioFormat := 1 ;     // PCM format
     FormatChunk.NumChannels := FNumChannelsPerScan ;
     FormatChunk.SampleRate := Round(1.0/FScanInterval) ;
     FormatChunk.BlockAlign := FNumChannelsPerScan*FNumBytesPerScan ;
     FormatChunk.ByteRate := FormatChunk.SampleRate*FormatChunk.BlockAlign ;
     FormatChunk.BitsPerSample := FNumBytesPerScan*8 ;
     FileWrite( FileHandle, FormatChunk, SizeOf(FormatChunk)) ;

    // Create and write data chunk
    StringToCharacterArray( 'data', DataChunk.ID ) ;
    DataChunk.ChunkSize := FNumBytesPerScan*FNumRecords*FNumScansPerRecord ;
    FileWrite( FileHandle, DataChunk, SizeOf(DataChunk)) ;

    // Set RIFF header chunk size and save again
    RIFFHeader.ChunkSize := FileSeek( FileHandle, 0, 2 ) - 8 ;
    FileSeek( FileHandle, 0, 0 ) ;
    FileWrite( FileHandle, RIFFHeader, SizeOf(RIFFHeader) ) ;

    for ch := 0 to FNumChannelsPerScan-1 do FADCScale[ch] := 1.0 ;
    FADCOffset := 0 ;
    UseTempFile := False ;

    Result := True ;

    end ;


function TADCDataFile.CharacterArrayToString(
         Buf : Array of Char
         )  : String ;
// ------------------------------
// Copy character array to string
// ------------------------------
var
    s : String ;
    i : Integer ;
begin
    s := '' ;
    for i := 0 to High(Buf) do s := s + Buf[i] ;
    Result := s ;
    end ;


procedure TADCDataFile.StringToCharacterArray(
         Source : String ;
         var Dest : Array of Char
         ) ;
// ------------------------------
// Copy string to character array
// ------------------------------
var
    i : Integer ;
begin
    for i := 1 to Length(Source) do if (i-1) <= High(Dest) then
        Dest[i-1] := Source[i] ;
    end ;



function TADCDataFile.GetChannelName( i : Integer ) : String ;
// --------------------------------
// Get analogue input channel name
// --------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then begin
        Result := FChannelName[i] ;
        end
     else Result := '' ;
     end ;


function TADCDataFile.GetChannelUnits( i : Integer ) : String ;
// --------------------------------
// Get analogue input channel units
// --------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then Result := FChannelUnits[i]
                                         else Result := '' ;
     end ;


function TADCDataFile.GetChannelOffset( i : Integer ) : Integer ;
// --------------------------------------------
// Get analogue input channel A/D sample offset
// --------------------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then Result := FChannelOffset[i]
                                         else Result := 0 ;
     end ;


function TADCDataFile.GetChannelZero( i : Integer ) : Integer ;
// --------------------------------------
// Get analogue input channel zero level
// --------------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then Result := FChannelZero[i]
                                         else Result := 0 ;
     end ;


function TADCDataFile.GetChannelZeroAt( i : Integer ) : Integer ;
// ------------------------------------------------
// Get analogue input channel zero reference sample
// ------------------------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then Result := FChannelZeroAt[i]
                                         else Result := 0 ;
     end ;


function TADCDataFile.GetChannelScale( i : Integer ) : Single ;
// ------------------------------------------------
// Get analogue input channel A/D scaling factor
// ------------------------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then Result := FChannelScale[i]
                                         else Result := 0 ;
     end ;


function TADCDataFile.GetChannelCalibrationFactor( i : Integer ) : Single ;
// -----------------------------------------------------
// Get analogue input channel V/Units calibration factor
// -----------------------------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then Result := FChannelCalibrationFactor[i]
                                         else Result := 0 ;
     end ;


function TADCDataFile.GetChannelGain( i : Integer ) : Single ;
// -------------------------------------------
// Get analogue input channel additional gain
// -------------------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then Result := FChannelGain[i]
                                         else Result := 0 ;
     end ;


function TADCDataFile.GetChannelADCVoltageRange( i : Integer ) : Single ;
// --------------------------------------------
// Get analogue input channel A/D voltage range
// --------------------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then Result := FChannelADCVoltageRange[i]
                                         else Result := 0 ;
     end ;


function TADCDataFile.GetScanInterval : Single ;
// --------------------------------------------
// Get time interval between channel scans
// --------------------------------------------
begin

     Case FFileType of
          ftWCP : Result := WCPRecordHeader.dt ;
          else Result := FScanInterval ;
          end ;

     end ;


function TADCDataFile.GetASCIITimeDataInCol0 : Boolean ;
// ------------------------------------
// Get state of ASCII time column field
// ------------------------------------
begin
     if ASCTimeColumn = 1 then Result := True
                          else Result := False ;
     end ;


procedure TADCDataFile.SetChannelName(
          i : Integer ;
          Value : String ) ;
// --------------------------------
// Set analogue input channel name
// --------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then FChannelName[i] := Value ;
     end ;


procedure TADCDataFile.SetChannelUnits(
          i : Integer ;
          Value : String ) ;
// --------------------------------
// Set analogue input channel units
// --------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then FChannelUnits[i] := Value ;
     end ;


procedure TADCDataFile.SetChannelOffset(
          i : Integer ;
          Value : Integer ) ;
// --------------------------------------------
// Set analogue input channel A/D sample offset
// --------------------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then FChannelOffset[i] := Value ;
     end ;


procedure TADCDataFile.SetChannelZero(
          i : Integer ;
          Value : Integer ) ;
// --------------------------------------
// Set analogue input channel zero level
// --------------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then FChannelZero[i] := Value ;
     end ;


procedure TADCDataFile.SetChannelZeroAt(
          i : Integer ;
          Value : Integer ) ;
// ------------------------------------------------
// Set analogue input channel zero reference sample
// ------------------------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then FChannelZeroAt[i] := Value ;
     end ;


procedure TADCDataFile.SetChannelScale(
          i : Integer ;
          Value : Single ) ;
// ------------------------------------------------
// Set analogue input channel A/D scaling factor
// ------------------------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then FChannelScale[i] := Value ;
     end ;


procedure TADCDataFile.SetChannelCalibrationFactor(
          i : Integer ;
          Value : Single ) ;
// -----------------------------------------------------
// Set analogue input channel V/Units calibration factor
// -----------------------------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then FChannelCalibrationFactor[i] := Value ;
     end ;


procedure TADCDataFile.SetChannelGain(
          i : Integer ;
          Value : Single ) ;
// -------------------------------------------
// Set analogue input channel additional gain
// -------------------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then FChannelGain[i] := Value ;
     end ;


procedure TADCDataFile.SetChannelADCVoltageRange(
          i : Integer ;
          Value : Single ) ;
// --------------------------------------------
// Set analogue input channel A/D voltage range
// --------------------------------------------
begin
     if (i >= 0) and (i <= ChannelLimit) then begin
        FChannelADCVoltageRange[i] := Value ;
        FADCVoltageRange := Value ;
        end ;
     end ;


procedure TADCDataFile.SetRecordNum( Value : Integer ) ;
// ------------
// Set record #
// ------------
var
     ch : Integer ;
begin

     FRecordNum := Value ;


     end ;


procedure TADCDataFile.SetNumScansPerRecord( Value : Integer ) ;
// ------------------------------------
// Set no. of channels scans per record
// ------------------------------------
begin
     //FNumScansPerRecord := 256*Max( Value div 256,1 ) ;
     FNumScansPerRecord := Value ;
     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;
     end ;


procedure TADCDataFile.SetNumChannelsPerScan( Value : Integer ) ;
// ---------------------------
// Set no. of channel per scan
// ---------------------------
begin
     FNumChannelsPerScan := Min(Max(Value,1),ChannelLimit) ;
     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;
     end ;


procedure TADCDataFile.SetNumBytesPerSample( Value : Integer ) ;
// -------------------------------
// Set no. of bytes per A/D sample
// -------------------------------
begin
     FNumBytesPerSample := Max( 1,Value ) ;
     FNumBytesPerScan := FNumChannelsPerScan*FNumBytesPerSample ;
     FNumRecordDataBytes := FNumScansPerRecord*FNumBytesPerScan ;
     FNumRecordBytes := FNumRecordDataBytes + FNumRecordAnalysisBytes ;
     end ;


procedure TADCDataFile.SetASCIITimeDataInCol0( Value : Boolean ) ;
// ------------------------------------
// Set state of ASCII time column field
// ------------------------------------
begin
     if Value = True then ASCTimeColumn := 1
                     else ASCTimeColumn := 0 ;
     end ;


function TADCDataFile.ADCScale( ch : Integer ) : Single ;
// -----------------------------------------------
// Calculate Units/bit scale factor for channel ch
// -----------------------------------------------
var
     Denom : Single ;
begin
     Denom := FChannelCalibrationFactor[ch]*FChannelGain[ch]*
              (FMaxADCValue {- FMinADCValue} + 1) ;
     if Denom <> 0.0 then Result := FChannelADCVoltageRange[ch] / Denom
                     else Result := 1.0 ;
     end ;


function TADCDataFile.CalibFactor( ch : Integer ) : Single ;
// -----------------------------------------------
// Calculate calibration factor for channel ch
// -----------------------------------------------
var
     Denom : Single ;
begin
     Denom := FChannelScale[ch]*FChannelGain[ch]*(FMaxADCValue  + 1) ;
     if Denom <> 0.0 then Result := FChannelADCVoltageRange[ch] / Denom
                     else Result := 1.0 ;
     end ;



procedure TADCDataFile.AppendFloat(
          var Dest : Array of char;
          Keyword : string ;
          Value : Extended ) ;
{ --------------------------------------------------------
  Append a floating point parameter line
  'Keyword' = 'Value' on to end of the header text array
  --------------------------------------------------------}
begin
     CopyStringToArray( Dest, Keyword ) ;
     CopyStringToArray( Dest, format( '%.6g',[Value] ) ) ;
     CopyStringToArray( Dest, chr(13) + chr(10) ) ;
     end ;


procedure TADCDataFile.ReadFloat(
          const Source : Array of char;
          Keyword : string ;
          var Value : Single ) ;
var
   Parameter : string ;
begin
     FindParameter( Source, Keyword, Parameter ) ;
     if Parameter <> '' then Value := ExtractFloat( Parameter, 1. ) ;
     end ;


procedure TADCDataFile.AppendInt(
          var Dest : Array of char;
          Keyword : string ;
          Value : Integer ) ;
{ -------------------------------------------------------
  Append a long integer point parameter line
  'Keyword' = 'Value' on to end of the header text array
  ------------------------------------------------------ }
begin
     CopyStringToArray( Dest, Keyword ) ;
     CopyStringToArray( Dest, InttoStr( Value ) ) ;
     CopyStringToArray( Dest, chr(13) + chr(10) ) ;
     end ;


procedure TADCDataFile.ReadInt(
          const Source : Array of char;
          Keyword : string ;
          var Value : Integer ) ;
var
   Parameter : string ;
begin
     FindParameter( Source, Keyword, Parameter ) ;
     if Parameter <> '' then Value := ExtractInt( Parameter ) ;
     end ;

{ Append a text string parameter line
  'Keyword' = 'Value' on to end of the header text array}

procedure TADCDataFile.AppendString(
          var Dest : Array of char;
          Keyword, Value : string ) ;
begin
CopyStringToArray( Dest, Keyword ) ;
CopyStringToArray( Dest, Value ) ;
CopyStringToArray( Dest, chr(13) + chr(10) ) ;
end ;

procedure TADCDataFile.ReadString(
          const Source : Array of char;
          Keyword : string ;
          var Value : string ) ;
var
   Parameter : string ;
begin
     FindParameter( Source, Keyword, Parameter ) ;
     if Parameter <> '' then Value := Parameter  ;
     end ;

{ Append a boolean True/False parameter line
  'Keyword' = 'Value' on to end of the header text array}

procedure TADCDataFile.AppendLogical(
          var Dest : Array of char;
          Keyword : string ;
          Value : Boolean ) ;
begin
     CopyStringToArray( Dest, Keyword ) ;
     if Value = True then CopyStringToArray( Dest, 'T' )
                     else CopyStringToArray( Dest, 'F' )  ;
     CopyStringToArray( Dest, chr(13) + chr(10) ) ;
     end ;

procedure TADCDataFile.ReadLogical(
          const Source : Array of char;
          Keyword : string ;
          var Value : Boolean ) ;
var
   Parameter : string ;
begin
     FindParameter( Source, Keyword, Parameter ) ;
     if pos('T',Parameter) > 0 then Value := True
                               else Value := False ;
     end ;


procedure TADCDataFile.CopyStringToArray(
          var Dest : array of char ;
          Source : string ) ;
var
   i,j : Integer ;
begin

     { Find end of character array }
     j := 0 ;
     while (Dest[j] <> chr(0)) and (j < High(Dest) ) do j := j + 1 ;

     if (j + length(Source)) < High(Dest) then
     begin
          for i := 1 to length(Source) do
          begin
               Dest[j] := Source[i] ;
               j := j + 1 ;
               end ;
          end
     else
         ShowMessage( ' Array Full ' ) ;

     end ;

procedure TADCDataFile.CopyArrayToString(
          var Dest : string ;
          var Source : array of char ) ;
var
   i : Integer ;
begin
     Dest := '' ;
     for i := 0 to High(Source) do begin
         Dest := Dest + Source[i] ;
         end ;
     end ;


procedure TADCDataFile.FindParameter(
          const Source : array of char ;
          Keyword : string ;
          var Parameter : string ) ;
var
s,k : integer ;
Found : boolean ;
begin

     { Search for the string 'keyword' within the
       array 'Source' }

     s := 0 ;
     k := 1 ;
     Found := False ;
     while (not Found) and (s < High(Source)) do
     begin
          if Source[s] = Keyword[k] then
          begin
               k := k + 1 ;
               if k > length(Keyword) then Found := True
               end
               else k := 1;
         s := s + 1;
         end ;


    { Copy parameter value into string 'Parameter'
      to be returned to calling routine }

    Parameter := '' ;
    if Found then
    begin
        while (Source[s] <> chr(13)) and (s < High(Source)) do
        begin
             Parameter := Parameter + Source[s] ;
             s := s + 1
             end ;
        end ;
    end ;


function TADCDataFile.ExtractFloat (
         CBuf : string ;     { ASCII text to be processed }
         Default : Single    { Default value if text is not valid }
         ) : single ;
{ -------------------------------------------------------------------
  Extract a floating point number from a string which
  may contain additional non-numeric text
  28/10/99 ... Now handles both comma and period as decimal separator
  -------------------------------------------------------------------}

var
   CNum : string ;
   i : integer ;
   Done,NumberFound : Boolean ;
begin
     { Extract number from othr text which may be around it }
     CNum := '' ;
     Done := False ;
     NumberFound := False ;
     i := 1 ;
     repeat
         if CBuf[i] in ['0'..'9', 'E', 'e', '+', '-', '.', ',' ] then begin
            CNum := CNum + CBuf[i] ;
            NumberFound := True ;
            end
         else if NumberFound then Done := True ;
         Inc(i) ;
         if i > Length(CBuf) then Done := True ;
         until Done ;

     { Correct for use of comma/period as decimal separator }
     if (DECIMALSEPARATOR = '.') and (Pos(',',CNum) <> 0) then
        CNum[Pos(',',CNum)] := DECIMALSEPARATOR ;
     if (DECIMALSEPARATOR = ',') and (Pos('.',CNum) <> 0) then
        CNum[Pos('.',CNum)] := DECIMALSEPARATOR ;

     { Convert number from ASCII to real }
     try
        if Length(CNum)>0 then ExtractFloat := StrToFloat( CNum )
                          else ExtractFloat := Default ;
     except
        on E : EConvertError do ExtractFloat := Default ;
        end ;
     end ;


function TADCDataFile.ExtractInt ( CBuf : string ) : Integer ;
{ ---------------------------------------------------
  Extract a 32 bit integer number from a string which
  may contain additional non-numeric text
  ---------------------------------------------------}

Type
    TState = (RemoveLeadingWhiteSpace, ReadNumber) ;
var CNum : string ;
    i : integer ;
    Quit : Boolean ;
    State : TState ;

begin
     CNum := '' ;
     i := 1;
     Quit := False ;
     State := RemoveLeadingWhiteSpace ;
     while not Quit do begin

           case State of

                { Ignore all non-numeric characters before number }
                RemoveLeadingWhiteSpace : begin
                   if CBuf[i] in ['0'..'9','+','-'] then State := ReadNumber
                                                    else i := i + 1 ;
                   end ;

                { Copy number into string CNum }
                ReadNumber : begin
                    {End copying when a non-numeric character
                    or the end of the string is encountered }
                    if CBuf[i] in ['0'..'9','E','e','+','-','.'] then begin
                       CNum := CNum + CBuf[i] ;
                       i := i + 1 ;
                       end
                    else Quit := True ;
                    end ;
                else end ;

           if i > Length(CBuf) then Quit := True ;
           end ;
     try


        ExtractInt := StrToInt( CNum ) ;
     except
        ExtractInt := 1 ;
        end ;
     end ;


procedure TADCDataFile.FillCharArray(
          InString : String ;
          var OutArray : Array of Char ;
          NullTerminate : Boolean
          ) ;
// -----------------------------------------
// Copy characters from InString to OutArray
// -----------------------------------------
var
     i : Integer ;
     TermChar : Char ;
begin

     // Set terminal character
     if NullTerminate then TermChar := #0
                      else TermChar := ' ' ;

     for i := 0 to High(OutArray) do begin
         OutArray[i] := TermChar ;
         if (i < Length(InString)) and (i < High(OutArray)) then OutArray[i] := InString[i+1] ;
         end ;
     end ;


procedure TADCDataFile.ZeroMem(
          pBuf : Pointer ;
          NumBytes : Integer
          ) ;
// --------------------------------------------------
// Fill Buffer pointed to by pBuf with NumBytes zeros
// --------------------------------------------------
var
    i : Integer ;
begin
    for i := 0 to NumBytes-1 do pByteArray(pBuf)^[i] := 0 ;
    end ;

end.
