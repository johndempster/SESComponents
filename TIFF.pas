unit TIFF;
// -----------------------------------
// TIFF file format handling component
// -----------------------------------
// 17.04.03

interface

uses
  SysUtils, Classes, Dialogs ;

type

    TTiffHeader = packed record
        ByteOrder : Word ;
        Signature : Word ;
        IFDOffset : Cardinal ;
        end ;

    TTiffIFDEntry = packed record
        Tag : Word ;
        FieldType : Word ;
        Count : Cardinal ;
        Offset : Cardinal ;
        end ;

    TRational = packed record
                Numerator : Cardinal ;
                Denominator : Cardinal ;
                end ;

  TTIFF = class(TComponent)
  private
    { Private declarations }
    FileHandle : Integer ;     // TIFF file handle
    FFrameWidth : Integer ;    // Image width
    FFrameHeight : Integer ;   // Image height
    FPixelDepth : Integer ;    // No. of bits per pixel
    FNumFrames : Integer ;     // No. of images in file
    FXResolution : Double ;
    FYResolution : Double ;
    FResolutionUnit : Integer ;
    FDescription : String ;    // Description of TIFF image

    IFDCount : Word ;
    TIFFHeader : TTiffHeader ;  // TIFF file header
    SamplesPerPixel : Word ;
    BitsPerSample : Word ;
    RowsPerStrip : Cardinal ;
    MinSampleValue : Cardinal ;
    MaxSampleValue : Cardinal ;
    UICSTKFormat : Boolean ;
    NumBytesPerFrame : Integer ;

    FIFDPointerList : Array[0..10000] of Integer ;

    procedure ClearIFD ;

    Procedure ReadIFDFromFile(
              FileHandle : Integer ;
              IFDPointer : Cardinal ;
              var IFD : Array of TTiffIFDEntry  ;
              var NumIFDEntries : Integer ;
              var NextIFDPointer : Integer
              ) ;

    procedure AddIFDEntry(
               Tag : Word ;
               FieldType : Word ;
               NumValues : Cardinal ;
               Value  : Cardinal ) ;

    function GetIFDEntry(
              IFD : Array of TTIFFIFDEntry ;
              NumEntries : Integer ;
              Tag : Integer ;
              var NumValues : Integer ;
              var Value : Integer ) : Boolean ;

    function ReadRationalField(
             FileHandle : Integer ;  // Open TIFF file handle
             FileOffset : Integer    // Offset to start reading from
             ) : Double ;            // Return as double

    function ReadASCIIField(
         FileHandle : Integer ;  // Open TIFF file handle
         FileOffset : Integer ;  // Offset to start reading from
         NumChars : Integer     // No. of characters to read
         ) : String ;

  protected
    { Protected declarations }
  public
    { Public declarations }
    Constructor Create(AOwner : TComponent) ; override ;
    Destructor Destroy ; override ;
    Function OpenFile( FileName : String ) : Boolean ;
    Procedure CloseFile ;
    Function LoadFrame(
              FrameNum : Integer ;
              PImageBuf : Pointer
              ) : Boolean ;


  published
    { Published declarations }
    Property FrameWidth : Integer Read FFrameWidth ;
    Property FrameHeight : Integer Read FFrameHeight ;
    Property PixelDepth : Integer Read FPixelDepth ;
    Property NumFrames : Integer Read FNumFrames ;
    Property ResolutionUnit : Integer Read FResolutionUnit ;
    Property XResolution : Double Read FXResolution ;
    Property YResolution : Double Read FYResolution ;
  end;

procedure Register;

implementation

type
    TLongArray = Array[0..60000] of Cardinal ;
const
     LittleEndian = $4949 ;
     BigEndian = $4d4d ;
     Signature = $42 ;
     // Field types
     ByteField = 1 ;
     ASCIIField = 2 ;
     ShortField = 3 ;
     LongField = 4 ;
     RationalField = 5 ;
     SignedByteField = 6 ;
     UndefinedField = 7 ;
     SignedShortField = 8 ;
     SignedLongField = 9 ;
     SignedRationalField = 10 ;
     FloatField = 11 ;
     DoubleField = 12 ;
     // Tag definitions
     NewSubfileTypeTag = 254 ;
     SubfileTypeTag = 255 ;
       FullResolutionImage = 1 ;
       ReducedResolutionImage = 2 ;
       MultiPageImage = 3 ;
     ImageWidthTag = 256 ;
     ImageLengthTag = 257 ;
     BitsPerSampleTag = 258 ;
     CompressionTag = 259 ;
       NoCompression = 1 ;
       CCCITCompression = 2 ;
       Group3Fax = 3 ;
       Group4Fax = 4 ;
       LZW = 5 ;
       JPEG = 6 ;
       PackBits = 32773 ;
     PhotometricInterpretationTag = 262 ;
       WhiteIsZero = 0 ;
       BlackIsZero = 1 ;
       RGB = 2 ;
       RGBPalette = 3 ;
       TransparencyMask = 4 ;
       CMYK = 5 ;
       YCbCr = 6 ;
       CIELab = 7 ;
     ThresholdingTag = 263 ;
     CellWidthTag = 264 ;
     CellLengthTag = 265 ;
     FillOrderTag = 266 ;
     DocumentNameTag = 269 ;
     ImageDescriptionTag = 270 ;
     MakeTag = 271 ;
     ModelTag = 272 ;
     StripOffsetsTag = 273 ;
     OrientationTag = 274 ;
     SamplesPerPixelTag = 277 ;
     RowsPerStripTag = 278 ;
     StripByteCountsTag = 279 ;
     MinSampleValueTag = 280 ;
     MaxSampleValueTag = 281 ;
     XResolutionTag = 282 ;
     YResolutionTag = 283 ;
     PlanarConfigurationTag = 284 ;
     PageNameTag = 285 ;
     XPositionTag = 286 ;
     YPositiontag = 287 ;
     FreeOffsetsTag = 288 ;
     FreeByteCountstag = 289 ;
     GrayResponseUnitTag = 290 ;
     GrayResponseCurveTag = 291 ;
     T4OptionsTag = 292 ;
     T6OptionsTag = 293 ;
     ResolutionUnitTag = 296 ;
        NoUnits = 1 ;
        InchUnits = 2 ;
        CentimeterUnits = 3 ;
     PageNumberTag = 297 ;
     TransferFunctionTag = 301 ;
     // Universal Imaging MetaMorph tags
     UIC1Tag = 33628 ;
     UIC2Tag = 33629 ;
     UIC3Tag = 33630 ;
     UIC4Tag = 33631 ;

procedure Register;
begin
  RegisterComponents('Samples', [TTIFF]);
end;

constructor TTIFF.Create(AOwner : TComponent) ;
{ --------------------------------------------------
  Initialise component's internal objects and fields
  -------------------------------------------------- }
begin
     inherited Create(AOwner) ;

     FileHandle := -1 ;

     FFrameWidth := 0 ;
     FFrameHeight := 0 ;
     FPixelDepth := 0 ;
     FNumFrames := 0 ;

     FResolutionUnit := 1 ;
     FXResolution := 1.0 ;
     FYResolution := 1.0 ;

     FDescription := '' ;

     end ;




destructor TTIFF.Destroy ;
{ ------------------------------------
   Tidy up when component is destroyed
   ----------------------------------- }
begin

     // Close open TIFF file
     if FileHandle >= 0 then FileClose( FileHandle ) ;

     { Call inherited destructor }
     inherited Destroy ;

     end ;


procedure TTiff.ClearIFD ;
// --------------------------
// Clear Image file directory
// --------------------------
begin
     IFDCount := 0 ;
     end ;


procedure TTiff.AddIFDEntry(
          Tag : Word ;            // Type of IFD entry
          FieldType : Word ;      // Type of data in field
          NumValues : Cardinal ;  // Number of values
          Value  : Cardinal ) ;   // Value (or file offset of value)
// ------------------------------------------
// Add a single valued IFD entry to IFD table
// ------------------------------------------
begin
    { IFD[IFDCount].Tag := Tag ;
     IFD[IFDCount].FieldType := FieldType ;
     IFD[IFDCount].Count := NumValues ;
     IFD[IFDCount].Offset := Value ;
     if IFDCount < High(IFD) then Inc(IFDCount) ;}
     end ;


function TTIFF.GetIFDEntry(
         IFD : Array of TTIFFIFDEntry ;
         NumEntries : Integer ;
         Tag : Integer ;
         var NumValues : Integer ;
         var Value : Integer ) : Boolean ;
// ----------------------------------
// Find and return value of IFD entry
// ----------------------------------
var
     i : Integer ;
begin
     i := 0 ;
     while (i < NumEntries) and (IFD[i].Tag <> Tag) do Inc(i) ;
     if IFD[i].Tag = Tag then begin
        NumValues := IFD[i].Count ;
        Value := IFD[i].Offset ;
        Result := True ;
        end
     else begin
        NumValues := 0 ;
        Value := 0 ;
        Result := False ;
        end ;
     end ;


function TTIFF.ReadRationalField(
         FileHandle : Integer ;  // Open TIFF file handle
         FileOffset : Integer    // Offset to start reading from
         ) : Double ;            // Return as double
// ----------------------------------------
// Read`rational field entry from TIFF file
// ----------------------------------------
var
     Numerator, Denominator : Integer ;
     Value : Double ;
begin

     FileSeek( FileHandle, FileOffset, 0 ) ;
     FileRead( FileHandle, Numerator, SizeOf(Numerator) ) ;
     FileRead( FileHandle, Denominator, SizeOf(Denominator) ) ;
     Value := Numerator ;
     if Denominator <> 0 then Value := Value / Denominator
                         else Value := 0.0 ;
     Result := Value ;
     end ;


function TTIFF.ReadASCIIField(
         FileHandle : Integer ;  // Open TIFF file handle
         FileOffset : Integer ;  // Offset to start reading from
         NumChars : Integer     // No. of characters to read
         ) : String ;
// ----------------------------------------
// Read`ASCII field entry from TIFF file
// ----------------------------------------
var
     i : Integer ;
     Ch : Char ;
begin

     Result := '' ;
     if NumChars <= 0 then Exit ;

     FileSeek( FileHandle, FileOffset, 0 ) ;
     for i := 1 to NumChars do begin
         FileRead( FileHandle, Ch, 1 ) ;
         if Ch <> #0 then Result := Result + Ch ;
         end ;
     end ;



procedure TTiff.ReadIFDFromFile(
          FileHandle : Integer ;               // TIFF File handle (IN)
          IFDPointer : Cardinal ;              // File pointer to start of IFD (IN)
          var IFD : Array of TTiffIFDEntry  ;  // IFD (OUT)
          var NumIFDEntries : Integer ;         // No. of entries in IDF (OUT)
          var NextIFDPointer  : Integer
          ) ;
// -----------------------------------
// Read image file directory from file
// -----------------------------------
var
    IFDCount : SmallInt ;
    i : Integer ;
    IFDEntry : TTiffIFDEntry ;
    Done : Boolean ;
begin

    // Move file pointer to start of IFD
    FileSeek(FileHandle,IFDPointer,0) ;

    // Read number of entries in IFD
    FileRead(FileHandle, IFDCount, SizeOf(IFDCount) ) ;

    Done := False ;
    NumIFDEntries := 0 ;
    while not Done do begin

        // Read IFD entry
        if FileRead(FileHandle, IFDEntry, SizeOf(TTiffIFDEntry))
           = SizeOf(TTiffIFDEntry) then begin
           IFD[NumIFDEntries] := IFDEntry ;
           Inc(NumIFDEntries) ;
           Dec(IFDCount) ;
           if IFDCount = 0 then Done := True ;
           end
        else begin
           MessageDlg( 'TIFF: Error reading IFD', mtWarning, [mbOK], 0 ) ;
           Done := True ;
           end ;
        end ;

    NextIFDPointer := 1 ;
    FileRead(FileHandle, NextIFDPointer, SizeOf(NextIFDPointer) ) ;

    end ;

function TTiff.OpenFile(
          FileName : string             // Name of TIFF file to be read (IN)
          ) : Boolean ;                 // Returns TRUE if successful
// ---------------
// Open TIFF file
// ---------------
var

     i,NumEntries : Integer ;
     NumValues : Integer ;
     FileOffset : Integer ;
     IFDPointer : Integer ;    // Pointer to image file directory
     NextIFDPointer : Integer ;
     NumIFDEntries : Word ;    // No.of entries in an IFD
     TIFFHeader : TTIFFHeader ; // TIFF file header structure
     IFD : Array[0..100] of TTiffIFDEntry ;
     Done : Boolean ;
     Value : Double ;
begin

     Result := False ;

     if FileHandle >= 0 then begin
        MessageDlg( 'TIFF: A file is aready open ', mtWarning, [mbOK], 0 ) ;
        Exit ;
        end ;

     // Open file
     FileHandle := FileOpen( FileName, fmOpenRead ) ;
     if FileHandle < 0 then begin
        MessageDlg( 'TIFF: Unable to open ' + FileName, mtWarning, [mbOK], 0 ) ;
        Exit ;
        end ;

    // Read TIFF file header
    FileSeek(FileHandle,0,0) ;
    if FileRead(FileHandle, TIFFHeader, SizeOf(TIFFHeader))
        <> SizeOf(TIFFHeader) then begin  ;
        MessageDlg( 'TIFF: Unable to read file header of' + FileName, mtWarning, [mbOK], 0 ) ;
        FileClose( FileHandle ) ;
        FileHandle := -1 ;
        Exit ;
        end ;

    // Only little-endian (Intel CPUs) byte ordering supported at present
    if TIFFHeader.ByteOrder <> LittleEndian then begin
       MessageDlg( 'TIFF: Macintosh byte ordering not supported!', mtWarning, [mbOK], 0 ) ;
       FileClose( FileHandle ) ;
       FileHandle := -1 ;
       Exit ;
       end ;

    // A .stk file ending indicates that this is a Universal Imaging
    // stack file which has to be processed specially

    if LowerCase(ExtractFileExt(FileName)) = '.stk' then UICSTKFormat := True
                                                    else UICSTKFormat := False ;

    IFDPointer := TIFFHeader.IFDOffset ;
    FNumFrames := 0 ;
    Done := False ;
    while not Done do begin

       // Read`image file directory
       FIFDPointerList[FNumFrames] := IFDPointer ;
       ReadIFDFromFile( FileHandle, IFDPointer, IFD, NumEntries, NextIFDPointer ) ;

       // Get image characteristics
       GetIFDEntry( IFD, NumEntries, ImageWidthTag, NumValues, FFrameWidth ) ;
       GetIFDEntry( IFD, NumEntries, ImageLengthTag, NumValues, FFrameHeight ) ;
       GetIFDEntry( IFD, NumEntries, BitsPerSampleTag, NumValues, FPixelDepth ) ;

       NumBytesPerFrame := FFrameWidth*FFrameHeight* (((FPixelDepth-1) div 8) + 1) ;

       // Get spatial resolution information
       FResolutionUnit := 1 ;
       GetIFDEntry( IFD, NumEntries, ResolutionUnitTag, NumValues, FResolutionUnit ) ;

       GetIFDEntry( IFD, NumEntries, XResolutionTag, NumValues, FileOffset ) ;
       if NumValues > 0 then begin
          Value := ReadRationalField(FileHandle,FileOffset) ;
          if Value <> 0.0 then FXResolution := 1.0 / Value ;
          end ;

       GetIFDEntry( IFD, NumEntries, YResolutionTag, NumValues, FileOffset ) ;
       if NumValues > 0 then begin
          Value := ReadRationalField(FileHandle,FileOffset) ;
          if Value <> 0.0 then FYResolution :=  1.0 / Value ;
          end ;

       // Read image description field
       FDescription := '' ;
       GetIFDEntry( IFD, NumEntries, ImageDescriptionTag, NumValues, FileOffset ) ;
       if NumValues > 0 then FDescription :=  ReadASCIIField(FileHandle,FileOffset,NumValues) ;

      // If this is Universal Imaging STK format file get number of frames

      if UICSTKFormat then begin
         GetIFDEntry( IFD, NumEntries, UIC1Tag, NumValues, FileOffset ) ;
         if NumValues > 0 then FNumFrames := NumValues ;
         GetIFDEntry( IFD, NumEntries, UIC2Tag, NumValues, FileOffset ) ;
         if NumValues > 0 then FNumFrames := NumValues ;
         end
      else Inc(FNumFrames) ;

       // Null pointer indicates last IFD
       if NextIFDPointer > 0 then IFDPointer := NextIFDPointer
                             else Done := True ;

       // Only one IFD in UIC format
       if UICSTKFormat then begin
          for i := 1 to FNumFrames-1 do FIFDPointerList[i] := FIFDPointerList[0] ;
          end ;
       end ;

    Result := True ;

    end ;


procedure TTiff.CloseFile ;
// ---------------
// Close TIFF file
// ---------------
begin

     FNumFrames := 0 ;
     if FileHandle >= 0 then begin
        FileClose(FileHandle) ;
        FileHandle := -1 ;
        end ;
     end ;

Function TTIFF.LoadFrame(
         FrameNum : Integer ; // Frame # to load
         PImageBuf : Pointer  // Pointer to buffer to receive image
         ) : Boolean ;        // Returns TRUE if frame available
// --------------------------------------
// Load frame # <FrameNum> from TIFF file
// --------------------------------------
var
    NumEntries : Integer ;
    NumValues,nc : Integer ;
    IFDPointer : Integer ;    // Pointer to image file directory
    NextIFDPointer : Integer ;
    NumIFDEntries : Word ;    // No.of entries in an IFD
    OK : Boolean ;
    Strip : Integer ;
    StripOffsets : Array[0..1000] of Cardinal ;
    StripByteCounts : Array[0..1000] of Cardinal ;
    IFD : Array[0..100] of TTiffIFDEntry ;
    NumStrips : Integer ;
    FilePointer : Integer ;
    RowsPerStrip : Integer ;
    FrameOffset : Integer ;
    PBuf : Pointer ;

begin

     Result := False ;
     if (NumFrames <= 0) or
        (FrameNum <= 0) or
        (FrameNum > NumFrames) then Exit ;

     // Read IFD
     IFDPointer := FIFDPointerList[FrameNum-1] ;
     ReadIFDFromFile( FileHandle, IFDPointer, IFD, NumEntries, NextIFDPointer ) ;

     // Get pointers to image strips
     OK := GetIFDEntry( IFD, NumEntries, StripOffsetsTag, NumStrips, FilePointer ) ;
     if OK then begin
        FileSeek( FileHandle, FilePointer, 0 ) ;
        FileRead( FileHandle, StripOffsets, NumStrips*4 ) ;
        end
     else Exit ;

     // Get number of bytes in each image strip
     OK := GetIFDEntry( IFD, NumEntries, StripByteCountsTag, NumStrips, FilePointer ) ;
     if OK then begin
        FileSeek( FileHandle, FilePointer, 0 ) ;
        FileRead( FileHandle, StripByteCounts, NumStrips*4 ) ;
        end
     else Exit ;

     // Get number of image rows in each strip
     OK := GetIFDEntry( IFD, NumEntries, RowsPerStripTag, NumValues, RowsPerStrip ) ;

     // Read image

     if UICSTKFormat then begin
        // Read frame from UIC metamorph stack format file
        FrameOffset := FrameNum*( StripOffsets[NumStrips-1] +
                                  StripByteCounts[NumStrips-1] -
                                  StripOffsets[0] )
                       + StripOffsets[0] ;
        FileSeek( FileHandle, FrameOffset, 0 ) ;
        FileRead( FileHandle, PByteArray(PImageBuf)^, NumBytesPerFrame ) ;
        end
     else begin
        // Read frame from standard multi-page TIFF file
        PBuf := PImageBuf ;
        for Strip := 0 to NumStrips-1 do begin
            FileSeek( FileHandle, StripOffsets[Strip], 0 ) ;
            RowsPerStrip := FileRead( FileHandle, PByteArray(PBuf)^, StripByteCounts[Strip] ) ;
            PBuf := Ptr(Integer(PBuf) + StripByteCounts[Strip]) ;
            end ;
        end ;

     Result := True ;
     end ;


end.
