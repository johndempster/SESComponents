unit ImageFile;
// -------------------------------------------------
// Image data file handling component
// (c) J. Dempster, University of Strathclyde, 2003
// -------------------------------------------------
// 29.04.03
// 31.7.03 NumPixelsPerFrame & NumBytesPerFrame properties added
// 31.10.03 Support for 24 bit RGB TIFs added
// 08.03.04 ZResolution property added
//          Calibrations can now be read from PIC files
// 25.05.04 X,Z and time calibration now written to PIC files
// 7.06.04  PIC file frame rate now handled correctly
// 6.12.05  Error messages now reported in property .ErrorMassage
// 02.05.06 TIFF file format updated (Now works with MetaMorph V7
// 07.06.06 Nikon ICS file import added (NOTE ICSCreateFile and ICSSaveFrame not implemented)
// 11.12.06 LoadFrame32 and SaveFrame32 added
// 31.07.07 Export to STK files now works correctly

interface

uses
  SysUtils, Classes, Dialogs, strutils, math, WinProcs ;

const
     PICSignature = 12345 ;
     PICFileExtension = '.pic' ;
     TIFFileExtension = '.tif' ;
     STKFileExtension = '.stk' ;
     ICSFileExtension = '.ics' ;

     cIFDMaxStrips = 1000 ;
     cIFDMaxTags = 100 ;
     cIFDMaxBytesPerStrip = 4000000 ; //32768*2 ;
     cIFDTagsSpace = cIFDMaxTags*12 + 8 ;
     cIFDStripsOffset = cIFDTagsSpace ;
     cIFDStripsSpace = cIFDMaxStrips*8 ;
     cIFDImageStart = cIFDTagsSpace + cIFDStripsSpace ;

type

 // Types of image file supported
 TFileType = (PICFile,TIFFile, STKFile, ICSFile ) ;

// BIORAD PIC file records

 TPICFileHeader = packed record
      FrameWidth : SmallInt ;     // Image width (pixels)
      FrameHeight : SmallInt ;    // Image height (pixels)
      NumFrames : SmallInt ;      // No. images in file
      LUT1Min : SmallInt ;        // Lower intensity limit of LUT map
      LUT1Max : SmallInt ;        // Upper intensity limit of LUT map
      NotesAvailable : longBool ;  // TRUE = Notes field(s) available
      ByteImage : SmallInt ;      // 1=8 bit, 0=16 bit image
      ImageNumber : SmallInt ;    // Image no. within file
      FileName : Array[1..32] of Char ;  // File name
      Merged : SmallInt ;         // Merged format??
      LUT1Color : Word ;          // LUT1 colour status
      Signature : SmallInt ;   // PIC file signature = 12345
      LUT2Min : SmallInt ;        // Lower intensity limit of LUT2 map
      LUT2Max : SmallInt ;        // Upper intensity limit of LUT2 map
      LUT2Color : Word ;          // LUT2 colour status
      Edited : SmallInt ;         // 1=file has been edited
      ILensMagnification : SmallInt ; // Integer lens magnfication factor
      MagFactor : Single ;   // Floating point lens magnfication factor
      Free : Array[1..3] of SmallInt ;
      end ;

 TPICNote = packed Record
      Level : SmallInt ; // Not used
      Next : LongBool ;   // TRUE=more notes in file
      Num : SmallInt ;   // Image # associated with this note
      Status : Word ;    // Status flag
      NoteType : Word ;      // Note type
      x : SmallInt ;     // X coord associated with note
      y : SmallInt ;     // Y coord associated with note
      Text : Array[1..80] of char ; // Note text
      end ;

//  TIFF file definitions

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

    TImageFileDirectory = record
        SubFileType : Cardinal ;
        PhotometricInterpretation : Cardinal ;
        Compression : Cardinal ;
        NumStrips : Cardinal ;
        StripOffsetsPointer : Cardinal ;
        StripOffsets : Array[0..cIFDMaxStrips-1] of Cardinal ;
        StripByteCountsPointer : Cardinal ;
        StripByteCounts : Array[0..cIFDMaxStrips-1] of Cardinal ;
        RowsPerStrip : Cardinal ;
        ResolutionUnit : Cardinal ;
        XResolutionPointer : Cardinal ;
        YResolutionPointer : Cardinal ;
        SamplesPerPixelPointer : Cardinal ;
        Description : String ;
        DateTime : String ;
        Copyright : String ;
        Artist : String ;
        PageNumber : Integer ;
        UIC1Tag : Integer ;
        UIC2Tag : Integer ;
        UICNumFrames : Integer ;
        NextIFDOffset : Integer ;
        end ;

    TRational = packed record
                Numerator : Cardinal ;
                Denominator : Cardinal ;
                end ;

  TImageFile = class(TComponent)
  private
    { Private declarations }
    NewFile : Boolean ;             // TRUE if newly created file
    FFileType : TFileType ;         // Type of image file
    FileHandle : Integer ;         // File handle
    FFileName : String ;            // Name of data file
    FFrameWidth : Cardinal ;        // Image width
    FFrameHeight : Cardinal ;       // Image height
    FPixelDepth : Cardinal ;        // No. of bits per component
    FComponentsPerPixel : Cardinal ; // No. of colour components per pixel
    FNumBytesPerPixel : Cardinal ;     // No. bytes per pixel
    FNumPixelsPerFrame : Cardinal ;    // No. pixels per frame
    FNumBytesPerFrame : Cardinal ;  // No. of bytes per image frame
    FNumFrames : Integer ;         // No. of images in file
    FXResolution : Double ;       // X axis pixel size
    FYResolution : Double ;       // Y axis pixel size
    FZResolution : Double ;       // Z axis pixel size
    FTResolution : Double ;       // Inter-frame time interval (s)
    FResolutionUnit : String ;
    FDescription : String ;    // Description of TIFF image
    FErrorMessage : String ;   // Last error
    TIFSingleFrame : Boolean ;

    // PIC fields
    PICHeader : TPICFileHeader ;      // PIC file header block
    PICScaleFactor : Single ;         // PIC System scale factor

    // TIFF fields
    TIFFHeader : TTiffHeader ;  // TIFF file header
    UICSTKFormat : Boolean ;

    FIFDPointerList : Array[0..30000] of Integer ;
    IFD : TImageFileDirectory ; // Current Image file directory
    //Buf : Array[0..30000] of Integer ;

//  PIC file methods
//  ----------------

    function PICOpenFile(
             FileName : String
              ) : Boolean ;

    function PICCreateFile(
             FileName : String ;
             FrameWidth : Integer ;
             FrameHeight : Integer ;
             PixelDepth : Integer
             ) : Boolean ;

    function PICCloseFile : Boolean ;

    procedure PICWriteNote(
              FileHandle : Integer ;
              NoteText : String ;
              LastNote : Boolean
              ) ;

    function PICLoadFrame(
             FrameNum : Integer ;
             PFrameBuf : Pointer
             ) : Boolean ;

    function PICSaveFrame(
             FrameNum : Integer ;
             PFrameBuf : Pointer
             ) : Boolean ;

    function PICReadAxisTypeNote(
             AxisType : String ;
             ArgNum : Integer ) : Double ;

//  TIFF file methods

    function TIFOpenFile(
             FileName : String
              ) : Boolean ;

    function TIFCreateFile(
             FileName : String ;
             FrameWidth : Integer ;
             FrameHeight : Integer ;
             PixelDepth : Integer ;
             ComponentsPerPixel : Integer ;
             SingleFrame : Boolean
             ) : Boolean ;

    function TIFCloseFile : Boolean ;
    function STKCloseFile : Boolean ;

    Function TIFLoadIFD(
         IFDPointer : Integer   // Pointer offset to IFD in data file
         ) : Boolean ;

    Function TIFSaveIFD(
             FrameNum : Integer ;           // Frame Number (IN)
             EndOfFile : Boolean
             ) : Integer ;

    procedure TIFReadIntegerValues(
          FileOffset : Cardinal ;            // Byte offset of start of values
          FieldType : Integer ;             // Type of integer values
          NumValues : Cardinal ;             // No. of values in array
          var Values : Array of Cardinal    // Return array
          ) ;

    procedure TIFWriteIntegerValues(
          FileOffset : Cardinal ;
          FieldType : Integer ;
          NumValues : Cardinal ;
          var Values : Array of Cardinal
          ) ;

    function TIFLoadFrame(
             FrameNum : Integer ;
             PImageBuf : Pointer
             ) : Boolean ;

    function TIFSaveFrame(
             FrameNum : Integer ;
             PImageBuf : Pointer
             ) : Boolean ;

    function STKCreateFile(
             FileName : String ;
             FrameWidth : Integer ;
             FrameHeight : Integer ;
             PixelDepth : Integer ;
             ComponentsPerPixel : Integer
             ) : Boolean ;

    function STKLoadFrame(
             FrameNum : Integer ;
             PImageBuf : Pointer
             ) : Boolean ;

    function STKSaveFrame(
             FrameNum : Integer ;
             PImageBuf : Pointer
             ) : Boolean ;

    function ICSOpenFile(
             FileName : String
              ) : Boolean ;

    function ICSCreateFile(
             FileName : String ;
             FrameWidth : Integer ;
             FrameHeight : Integer ;
             PixelDepth : Integer
             ) : Boolean ;

    function ICSCloseFile : Boolean ;

    function ICSLoadFrame(
             FrameNum : Integer ;
             PFrameBuf : Pointer
             ) : Boolean ;

    function ICSSaveFrame(
             FrameNum : Integer ;
             PFrameBuf : Pointer
             ) : Boolean ;

    procedure ICSGetIntParameters(
          Key : String ;
          Source : String ;
          var Values : Array of Integer ;
          var NumValues : Integer
          ) ;

    procedure ICSGetFltParameters(
          Key : String ;
          Source : String ;
          var Values : Array of Single ;
          var NumValues : Integer
          ) ;

    procedure ICSGetStringParameters(
          Key : String ;
          Source : String ;
          var Values : Array of String ;
          var NumValues : Integer
          ) ;

    function GetIFDEntry(
              IFD : Array of TTIFFIFDEntry ;
              NumEntries : Integer ;
              Tag : Integer ;
              var FieldType : Integer ;
              var NumValues : Cardinal ;
              var Value : Cardinal ) : Boolean ;

    procedure SetIFDEntry(
              var IFD : Array of TTiffIFDEntry ; // IFD list being created
              var NumEntries : Word ;             // No. of entries in list (IN/OUT)
              Tag : Integer ;                    // Tag to be added
              FieldType : Integer ;              // Field type
              NumValues : Integer ;          // No. of values in entry
              Value : Integer ) ;  // Entry value/offset


    function ReadRationalField(
             FileHandle : Integer ;  // Open TIFF file handle
             FileOffset : Integer    // Offset to start reading from
             ) : Double ;            // Return as double

    procedure WriteRationalField(
              FileOffset : Integer ;  // Offset to write to
              Value : Double          // Value
              );

    function ReadASCIIField(
         FileHandle : Integer ;  // Open TIFF file handle
         FileOffset : Integer ;  // Offset to start reading from
         NumChars : Integer     // No. of characters to read
         ) : String ;

    procedure WriteASCIIField(
              FileHandle : Integer ;  // Open TIFF file handle
              FileOffset : Integer ;  // Offset to start reading from
              Text : String
              ) ;

    procedure AppendFloat(
              var Dest : array of char;
              Keyword : string ;
              Value : Extended
              ) ;
    procedure ReadFloat(
              const Source : array of char;
              Keyword : string ;
              var Value : Single ) ;

    procedure CopyStringToArray( var Dest : array of char ; Source : string ) ;
    procedure CopyArrayToString( var Dest : string ; var Source : array of char ) ;
    procedure FindParameter(
              const Source : array of char ;
              Keyword : string ;
              var Parameter : string ) ;

    function ExtractFloat (
             CBuf : string ;
             Default : Single
             ) : single ;

    function StringFromArray(
             var Source : array of char ) : String ;
  protected
    { Protected declarations }
  public
    { Public declarations }
    Properties : TStringList ;

    Constructor Create(AOwner : TComponent) ; override ;
    Destructor Destroy ; override ;

    function OpenFile(
             FileName : String
              ) : Boolean ;

    function CreateFile(
             FileName : String ;
             FrameWidth : Integer ;
             FrameHeight : Integer ;
             PixelDepth : Integer ;
             ComponentsPerPixel : Integer ;
             SingleFrame : Boolean
             ) : Boolean ;

    function CloseFile : Boolean ;

    function LoadFrame(
             FrameNum : Integer ;
             PFrameBuf : Pointer
             ) : Boolean ;

    function SaveFrame(
             FrameNum : Integer ;
             PFrameBuf : Pointer
             ) : Boolean ;

    function LoadFrame32(
             FrameNum : Integer ;
             PFrameBuf : Pointer
             ) : Boolean ;

    function SaveFrame32(
             FrameNum : Integer ;
             PFrameBuf : Pointer
             ) : Boolean ;


  published
    { Published declarations }
    Property FileName : String Read FFileName ;
    Property FileType : TFileType Read FFileType ;
    Property FrameWidth : Cardinal Read FFrameWidth ;
    Property FrameHeight : Cardinal Read FFrameHeight ;
    Property PixelDepth : Cardinal Read FPixelDepth ;
    Property ComponentsPerPixel : Cardinal Read FComponentsPerPixel ;
    Property NumPixelsPerFrame : Cardinal Read FNumPixelsPerFrame ;
    Property NumBytesPerFrame : Cardinal Read FNumBytesPerFrame ;
    Property NumFrames : Integer Read FNumFrames ;
    Property ResolutionUnit : String Read FResolutionUnit Write FResolutionUnit ;
    Property XResolution : Double Read FXResolution Write FXResolution ;
    Property YResolution : Double Read FYResolution Write FYResolution ;
    Property ZResolution : Double Read FZResolution Write FZResolution ;
    Property TResolution : Double Read FTResolution Write FTResolution ;
    Property ErrorMessage : String Read FErrorMessage ;
  end;

procedure Register;

implementation

type
    TLongArray = Array[0..60000] of Cardinal ;
    TIntArray = Array[0..99999999] of Integer ;
    PIntArray = ^TIntArray ;
const
     LittleEndian = $4949 ;
     BigEndian = $4d4d ;
     TIFSignature = 42 ;
     // Field types
     ByteField = 1 ;
     ASCIIField = 2 ;
     ShortField = 3 ;
     LongField = 4 ;
     RationalField = 5 ;
     SignedByteField = 6 ;
     UndefinedField = 7 ;
     SShortField = 8 ;
     SLongField = 9 ;
     SRationalField = 10 ;
     FloatField = 11 ;
     DoubleField = 12 ;


    ByteFieldSize = 1 ;
    ASCIIFieldSize = 2 ;
    ShortFieldSize = 2 ;
    LongFieldSize = 4 ;
    RationalFieldSize = 8 ;
    SByteFieldSize = 1 ;
    UndefinedFieldSize = 0 ;
    SShortFieldSize = 2 ;
    SLongFieldSize = 4 ;
    SRationalFieldSize = 8 ;
    SFloatFieldSize = 4 ;
    SDoubleFieldSize = 8 ;

     // Tag definitions
     NewSubfileTypeTag = 254 ;
     SubfileTypeTag = 255 ;
       TransparencyMaskBit = 4 ;
       ReducedResolutionImageBit = 1 ;
       MultiPageImageBit = 2 ;
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
     SoftwareTag = 305 ;
     DateTimeTag = 306 ;
     ArtistTag = 315 ;
     HostComputerTag = 316 ;

     // Universal Imaging MetaMorph tags
     UIC1Tag = 33628 ;
     UIC2Tag = 33629 ;
     UIC3Tag = 33630 ;
     UIC4Tag = 33631 ;

     CopyrightTag = 33432 ;

procedure Register;
begin
  RegisterComponents('Samples', [TImageFile]);
end;

constructor TImageFile.Create(AOwner : TComponent) ;
{ --------------------------------------------------
  Initialise component's internal objects and fields
  -------------------------------------------------- }
begin

     inherited Create(AOwner) ;

     FileHandle := -1 ;
     FFileName := '' ;

     FFrameWidth := 0 ;
     FFrameHeight := 0 ;
     FPixelDepth := 0 ;
     FNumFrames := 0 ;

     FResolutionUnit := '' ;
     FXResolution := 1.0 ;
     FYResolution := 1.0 ;
     FZResolution := 1.0 ;
     FTResolution := 1.0 ;

     FDescription := '' ;

     Properties := TStringList.Create ;

     end ;


destructor TImageFile.Destroy ;
{ ------------------------------------
   Tidy up when component is destroyed
   ----------------------------------- }
begin

     // Close image file
     if FileHandle >= 0 then FileClose( FileHandle ) ;

     Properties.Free ;

     { Call inherited destructor }
     inherited Destroy ;

     end ;


function TImageFile.OpenFile(
         FileName : String     // Name of file (IN)
          ) : Boolean ;        // Returns TRUE if file open successful
// ---------------
// Open image file
// ---------------
begin


     NewFile := False ;

     // Determine type of file from extension

     if LowerCase(ExtractFileExt(FileName)) = PICFileExtension then
        FFileType := PICFile
     else if LowerCase(ExtractFileExt(FileName)) = TIFFileExtension then
        FFileType := TIFFile
     else if LowerCase(ExtractFileExt(FileName)) = STKFileExtension then
        FFileType := STKFile
     else if LowerCase(ExtractFileExt(FileName)) = ICSFileExtension then
        FFileType := ICSFile ;

     FFileName := FileName ;

     case FFileType of
        PICFile : Result := PICOpenFile( FileName ) ;
        TIFFile,STKFile : Result := TIFOpenFile( FileName ) ;
        ICSFile : Result := ICSOpenFile( FileName ) ;
        end ;
     end ;


function TImageFile.CreateFile(
         FileName : String ;      // Name of file to be created
         FrameWidth : Integer ;   // Frame width
         FrameHeight : Integer ;  // Frame height
         PixelDepth : Integer ;    // No. of bits per pixel
         ComponentsPerPixel : Integer ; // No. of colour components/pixel
         SingleFrame : Boolean
          ) : Boolean ;           // Returns TRUE if file created OK
// -----------------------
// Create empty data file
// -----------------------
begin

     NewFile := True ;
     // Determine type of file from extension

     if LowerCase(ExtractFileExt(FileName)) = PICFileExtension then
        FFileType := PICFile
     else if LowerCase(ExtractFileExt(FileName)) = TIFFileExtension then
        FFileType := TIFFile
     else if LowerCase(ExtractFileExt(FileName)) = STKFileExtension then
        FFileType := STKFile ;

     FFileName := FileName ;

     case FFileType of
        PICFile : Result := PICCreateFile( FileName,
                                           FrameWidth,
                                           FrameHeight,
                                           PixelDepth ) ;
        TIFFile : Result := TIFCreateFile( FileName,
                                           FrameWidth,
                                           FrameHeight,
                                           PixelDepth,
                                           ComponentsPerPixel,
                                           SingleFrame ) ;
        STKFile : Result := STKCreateFile( FileName,
                                            FrameWidth,
                                            FrameHeight,
                                            PixelDepth,
                                            ComponentsPerPixel ) ;
        ICSFile : Result := ICSCreateFile( FileName,
                                           FrameWidth,
                                           FrameHeight,
                                           PixelDepth ) ;
        end ;
     end ;


function TImageFile.CloseFile : Boolean ;
// ---------------
// Close data file
// ---------------
begin
     Case FFileType of
          PICFile : Result := PICCloseFile ;
          TIFFile : Result := TIFCloseFile ;
          STKFile : Result := STKCloseFile ;
          ICSFile : Result := ICSCloseFile ;
          end ;
     end ;


function TImageFile.LoadFrame(
         FrameNum : Integer ;
         PFrameBuf : Pointer
         ) : Boolean ;
// --------------------------
// Load frame from image file
// --------------------------
begin

     if FileHandle < 0 then begin
        Result := False ;
        Exit ;
        end ;

     Case FFileType of
          PICFile : Result := PICLoadFrame( FrameNum, PFrameBuf ) ;
          TIFFile : Result := TIFLoadFrame( FrameNum, PFrameBuf ) ;
          STKFile : Result := STKLoadFrame( FrameNum, PFrameBuf ) ;
          ICSFile : Result := ICSLoadFrame( FrameNum, PFrameBuf ) ;
          end ;
     end ;


function TImageFile.LoadFrame32(
         FrameNum : Integer ;
         PFrameBuf : Pointer
         ) : Boolean ;
// ---------------------------------------------
// Load frame from image file into 32 bit buffer
// ---------------------------------------------
var
    i : Integer ;
    NumComponentsPerFrame : Integer ;
begin

    // Load from file
    LoadFrame( FrameNum, PFrameBuf ) ;

    NumComponentsPerFrame := FNumPixelsPerFrame*FComponentsPerPixel ;

    if FPixelDepth > 8 then begin
       // Copy word array to 32 bit array
       for i := NumComponentsPerFrame-1 downto 0 do begin
          PIntArray(PFrameBuf)^[i] := PWordArray(PFrameBuf)^[i] ;
          end ;
       end
    else begin
       // Copy byte array to 32 bit array
       for i := NumComponentsPerFrame-1 downto 0 do begin
          PIntArray(PFrameBuf)^[i] := PByteArray(PFrameBuf)^[i] ;
          end ;
       end ;
    end ;


function TImageFile.SaveFrame(
         FrameNum : Integer ;
         PFrameBuf : Pointer
         ) : Boolean ;
// ------------------------------
// Save frame to image data file
// ------------------------------
begin

     if FileHandle < 0 then begin
        Result := False ;
        Exit ;
        end ;

     Case FFileType of
          PICFile : Result := PICSaveFrame( FrameNum, PFrameBuf ) ;
          TIFFile : Result := TIFSaveFrame( FrameNum, PFrameBuf ) ;
          STKFile : Result := STKSaveFrame( FrameNum, PFrameBuf ) ;
          ICSFile : Result := ICSSaveFrame( FrameNum, PFrameBuf ) ;
          end ;
     end ;


function TImageFile.SaveFrame32(
         FrameNum : Integer ;
         PFrameBuf : Pointer
         ) : Boolean ;
// ------------------------------
// Save frame to image data file
// ------------------------------
var
    pBuf : Pointer ;
    i : Integer ;
    NumComponentsPerFrame : Integer ;
begin

    NumComponentsPerFrame := FNumPixelsPerFrame*FComponentsPerPixel ;

    // Create internal buffer
    GetMem( pBuf, NumComponentsPerFrame*2 ) ;

    if FPixelDepth > 8 then begin
       // Copy 32 bit array to word array
       for i := 0 to NumComponentsPerFrame-1 do begin
          PWordArray(pBuf)^[i] := PIntArray(PFrameBuf)^[i] ;
          end ;
       end
    else begin
       // Copy 32 bit array to byte array
       for i := 0 to NumComponentsPerFrame-1 do begin
          PByteArray(pBuf)^[i] := PIntArray(PFrameBuf)^[i] ;
          end ;
       end ;

    // Load from file
    SaveFrame( FrameNum, pBuf ) ;

    FreeMem( pBuf) ; // Dispose of buffer

    end ;

// BIORAD PIC file methods
// =======================


function TImageFile.PICOpenFile(
         FileName : String
          ) : Boolean ;
// ---------------------------
// Open BioRad PIC data file
// ---------------------------
var
    Done : Boolean ;        // Loop done flag
    Magnification : Double ;
    PICNote : TPICNote ;    // PIC file note record
    NoteText : String ;
    NumSpaces : Integer ;
    i  : Integer ;
    LensMagnification : Single ;
    FrameRate : Single ;
begin

    Result := False ;

    if FileHandle >= 0 then begin
       FErrorMessage := 'TIMAGEFILE: A file is aready open ' ;
       Exit ;
       end ;

    // Open file
    FileHandle := FileOpen( FileName, fmOpenReadWrite ) ;
    if FileHandle < 0 then begin
       FErrorMessage := 'TIMAGEFILE: Unable to open ' ;
       Exit ;
       end ;

    // Read PIC file header
    FileSeek(FileHandle,0,0) ;
    if FileRead(FileHandle, PICHeader, SizeOf(PICHeader))
        <> SizeOf(PICHeader) then begin  ;
        FErrorMessage := 'TIMAGEFILE: Unable to read BioRad PIC file ' + FileName ;
        FileClose( FileHandle ) ;
        FileHandle := -1 ;
        Exit ;
        end ;

    // Check PIC file signature
    if PICHeader.Signature <> PICSignature then begin
       FErrorMessage := 'TIMAGEFILE: ' + FileName + ' not a PIC file!' ;
       FileClose( FileHandle ) ;
       FileHandle := -1 ;
       Exit ;
       end ;

    FFrameWidth := PICHeader.FrameWidth ;
    FFrameHeight := PICHeader.FrameHeight ;
    if PICHeader.ByteImage = 1 then FPixelDepth := 8
                               else FPixelDepth := 16 ;

    FComponentsPerPixel := 1 ;
    FNumBytesPerPixel := (((FPixelDepth-1) div 8) + 1)*FComponentsPerPixel ;

    FNumPixelsPerFrame := FFrameWidth*FFrameHeight ;
    FNumBytesPerFrame := FComponentsPerPixel*FNumPixelsPerFrame*FNumBytesPerPixel ;

    FNumFrames := PICHeader.NumFrames ;

    // Get pixel size from AXIS_2 notes field
    FXResolution := PICReadAxisTypeNote( 'AXIS_2',3 ) ;
    if FXResolution <> 0.0 then FResolutionUnit := 'um'
    else begin
        FXResolution := 1.0 ;
        FResolutionUnit := '' ;
        end ;

    // Get Z interval from AXIS_4 notes field
    FZResolution := PICReadAxisTypeNote( 'AXIS_4',3 ) ;
    if FZResolution <> 0.0 then FResolutionUnit := 'um'
    else begin
        FZResolution := 1.0 ;
        FResolutionUnit := '' ;
        end ;

    // Get inter-frame time interval from notes field
    FrameRate := PICReadAxisTypeNote( 'INFO_FRAME_RATE =',2 ) ;
    if FrameRate = 0.0 then FrameRate := 1.0 ;
    FTResolution := 1.0 / FrameRate ;

    // PIC file properties
    Properties.Add('Format: BIORAD PIC File') ;
    Properties.Add(format('Image Size: %d x %d (%d bits per pixel)',
    [FFrameWidth,FFrameHeight,FPixelDepth])) ;
    Properties.Add(format('Pixel resolution: %.4g %s ',[FXResolution,FResolutionUnit])) ;

    // Copy notes into properties box
    if PICHeader.NotesAvailable then begin
       FileSeek(FileHandle,PICHeader.NumFrames*FNumBytesPerFrame+SizeOf(PICHeader),0) ;
       Done := False ;
       While not Done do begin
           if FileRead(FileHandle, PICNote, SizeOf(PICNote))
              = SizeOf(PICNote) then Properties.Add( StringFromArray(PICNote.Text) )
           else Done := True ;
           Done := not PICNote.Next ;
           end ;
       end ;

    Result := True ;

    end ;

function TImageFile.PICReadAxisTypeNote(
         AxisType : String ;              // Keyword to search for
         ArgNum : Integer ) : Double ;    // Argument after keyword to be extracted
// --------------------------------------------
// Read value of selected axis calibration note
// --------------------------------------------
var
    Done : Boolean ;        // Loop done flag
    PICNote : TPICNote ;    // PIC file note record
    NoteText : String ;
    NumSpaces : Integer ;
    i  : Integer ;
begin

    Result := 0.0 ;
    if not PICHeader.NotesAvailable then Exit ;

    // Move to start of NOTES fields
    FileSeek(FileHandle,PICHeader.NumFrames*FNumBytesPerFrame+SizeOf(PICHeader),0) ;

    // Search notes for selected axis type
    Done := False ;
    While not Done do begin

        // Read note field
        if FileRead(FileHandle,PICNote,SizeOf(PICNote))
           <> SizeOf(PICNote) then Break ;

        if PicNote.NoteType = 20 then begin
           NoteText := StringFromArray(PICNote.Text) ;
           if Pos(AxisType, NoteText) > 0 then begin
              i := 1 ;
              NumSpaces := 0 ;
              While NumSpaces < ArgNum do begin
                    if NoteText[i] = ' ' then Inc(NumSpaces) ;
                    Inc(i) ;
                    end ;
              NoteText := RightStr(NoteText, Length(NoteText)-i+1 ) ;
              Result := ExtractFloat(NoteText,0.0) ;
              Done := True ;
              end ;
           end ;
        Done := not PICNote.Next ;
        end ;

    end ;


function TImageFile.PICCreateFile(
         FileName : String ;      // Name of file to be created
         FrameWidth : Integer ;   // Frame width
         FrameHeight : Integer ;  // Frame height
         PixelDepth : Integer     // No. of bits per pixel
          ) : Boolean ;           // Returns TRUE if file created OK
// ---------------------------------
// Create empty BioRad PIC data file
// ---------------------------------
var
    Done : Boolean ;        // Loop done flag

begin

    Result := False ;

    if FileHandle >= 0 then begin
       FErrorMessage := 'BIORAD: A file is aready open ' ;
       Exit ;
       end ;

    // Open file
    FileHandle := FileCreate( FileName, fmOpenRead ) ;
    if FileHandle < 0 then begin
       FErrorMessage := 'BIORAD: Unable to create '+ FileName ;
       Exit ;
       end ;

    // Initialise file header`
    FFrameWidth := FrameWidth ;
    FFrameHeight := FrameHeight ;
    FPixelDepth := PixelDepth ;
    if FPixelDepth <= 8 then FNumBytesPerPixel := 1
                        else FNumBytesPerPixel := 2 ;

    FComponentsPerPixel := 1 ;
    FNumPixelsPerFrame := FFrameWidth*FFrameHeight ;
    FNumBytesPerFrame := FComponentsPerPixel*FNumPixelsPerFrame*FNumBytesPerPixel ;

    PICHeader.FrameWidth := FFrameWidth ;
    PICHeader.FrameHeight := FFrameHeight ;
    if FPixelDepth <= 8 then PICHeader.ByteImage := 1
                        else PICHeader.ByteImage := 0 ;
    FNumFrames := 0 ;
    PICHeader.NumFrames := FNumFrames ;
    PICHeader.Signature := PICSignature ;
    PICHeader.NotesAvailable := False ;
    PICScaleFactor := 1.0 ;
    Result := True ;

    end ;


function TImageFile.PICCloseFile : Boolean ;
// ---------------
// Close PIC file
// ---------------
var
     PICNote : TPICNote ;    // PIC file note record
     FilePointer : Int64 ;
     i : Integer ;
     NoteText : String ;
begin
     Result := False ;

     // Exit if file not open
     if FileHandle < 0 then Exit ;

     // Update PIC file header
     if NewFile then begin

        // Write file header
        PICHeader.NotesAvailable := True ;
        PICHeader.MagFactor := 1.0 ;
        PICHeader.ILensMagnification := 1 ;
        PICHeader.NumFrames := FNumFrames ;
        FileSeek(FileHandle,0,0) ;
        FileWrite(FileHandle, PICHeader, SizeOf(PICHeader)) ;

        // Move pointer to end of file
        FileSeek( FileHandle,
                  Int64(PICHeader.NumFrames)*Int64(FNumBytesPerFrame)+ Int64(SizeOf(PICHeader)),
                  0 ) ;

        // Write X/Y resolution
        PICWriteNote( FileHandle,
                      format('AXIS_2 001 0.000000e+001 %13.6e Microns',[FXResolution]),
                      False ) ;
        // Write Z resolution
         PICWriteNote( FileHandle,
                      format('AXIS_4 001 0.000000e+001 %13.6e Microns',[FZResolution]),
                      False ) ;
        // Write inter-frame interval
        PICWriteNote( FileHandle,
                      format('INFO_FRAME_RATE = %13.6e',[FTResolution]),
                      True ) ;

        end ;

     // Close file
     FileClose( FileHandle ) ;
     // Note. file handle = -1 indicates no file open
     FileHandle := -1 ;
     FNumFrames := 0 ;
     Result := True ;

     end ;


procedure TImageFile.PICWriteNote(
          FileHandle : Integer ;    // PIC file handle
          NoteText : String ;       // Text of note to be written
          LastNote : Boolean        // Set to TRUE if this is last note to be written
         ) ;
// ----------------------
// Write PIC note to file
// ----------------------
var
    PICNote : TPICNote ;    // PIC file note record
    i : Integer ;
begin

     PICNote.Level := 0 ;
     PICNote.Next := not LastNote ;
     PICNote.Num := 1 ;
     PICNote.Status := 0 ;
     PICNote.NoteType := 20 ;
     PICNote.x := 0 ;
     PICNote.y := 0 ;

     for i := 1 to High(PICNote.Text) do PICNote.Text[i] := #0 ;
     for i := 1 to Length(NoteText) do if i < High(PICNote.Text) then PICNote.Text[i] := NoteText[i] ;

     FileWrite(FileHandle, PICNote, SizeOf(PICNote)) ;

     end ;


function TImageFile.PICLoadFrame(
         FrameNum : Integer ;
         PFrameBuf : Pointer
         ) : Boolean ;
// ----------------------------------------
// Load frame from BioRad PIC data file
// ----------------------------------------
var
    FilePointer : Int64 ;      // File offset
begin

    if (FrameNum < 1) or (FrameNum > FNumFrames) then begin
       Result := False ;
       Exit ;
       end ;

    // Find file offset of start of frame
    FilePointer := SizeOf(TPICFileHeader) + Int64(FrameNum-1)*Int64(FNumBytesPerFrame) ;

    // Read data from file
    FileSeek( FileHandle, FilePointer, 0 ) ;
    if FileRead(FileHandle, PFrameBuf^, FNumBytesPerFrame)
       = FNumBytesPerFrame then Result := True
                           else Result := False ;
    end ;


function TImageFile.PICSaveFrame(
         FrameNum : Integer ;             // No. of frame to write
         PFrameBuf : Pointer
         ) : Boolean ;// Pointer to image buffer
// ----------------------------------------
// Save frame to BioRad PIC data file
// ----------------------------------------
var
    FilePointer : Int64 ;      // File offset
begin

    if (FrameNum < 1) then begin
       Result := False ;
       Exit ;
       end ;

    // Find file offset of start of frame
    FilePointer := SizeOf(TPICFileHeader) + Int64(FrameNum-1)*Int64(FNumBytesPerFrame) ;

    // Write data to file
    FileSeek( FileHandle, FilePointer, 0 ) ;
    if FileWrite(FileHandle, PFrameBuf^, FNumBytesPerFrame)
       = FNumBytesPerFrame then Result := True
                           else Result := False ;

    // Update number of frames stored in file
    if FNumFrames < FrameNum then FNumFrames := FrameNum ;
    PICHeader.NumFrames := FNumFrames ;

    end ;


// TIFF file methods
// =================



function TImageFile.GetIFDEntry(
         IFD : Array of TTiffIFDEntry ;
         NumEntries : Integer ;
         Tag : Integer ;
         var FieldType : Integer ;
         var NumValues : Cardinal ;
         var Value : Cardinal ) : Boolean ;
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
        FieldType := IFD[i].FieldType ;
        Result := True ;
        end
     else begin
        NumValues := 0 ;
        Result := False ;
        end ;
     end ;


procedure TImageFile.SetIFDEntry(
          var IFD : Array of TTiffIFDEntry ; // IFD list being created
          var NumEntries : Word ;             // No. of entries in list (IN/OUT)
          Tag : Integer ;                    // Tag to be added
          FieldType : Integer ;              // Field type
          NumValues : Integer ;          // No. of values in entry
          Value : Integer ) ;  // Entry value/offset
// ----------------------------------
// Add an entry to IFD tag list
// ----------------------------------
begin

     IFD[NumEntries].Tag := Tag ;
     IFD[NumEntries].Count := NumValues ;
     IFD[NumEntries].FieldType := FieldType ;
     IFD[NumEntries].Offset := Value ;
     Inc(NumEntries) ;

     end ;



function TImageFile.ReadRationalField(
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


procedure TImageFile.WriteRationalField(
          FileOffset : Integer ;  // Offset to write to
          Value : Double          // Value
          );
// ----------------------------------------
// Write`rational field entry to TIFF file
// ----------------------------------------
var
     Numerator, Denominator : Integer ;
begin

     Denominator := 1 ;
     while (Abs(Frac(Value)/Value) > 1E-4) and (Denominator < 100000) do Denominator := Denominator*10 ;
     Numerator := Round(Value*Denominator) ;

     FileSeek( FileHandle, FileOffset, 0 ) ;
     FileWrite( FileHandle, Numerator, SizeOf(Numerator) ) ;
     FileWrite( FileHandle, Denominator, SizeOf(Denominator) ) ;

     end ;


function TImageFile.ReadASCIIField(
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


procedure TImageFile.WriteASCIIField(
          FileHandle : Integer ;  // Open TIFF file handle
          FileOffset : Integer ;  // Offset to start reading from
          Text : String ) ;
// ----------------------------------------
// Write`ASCII field entry from TIFF file
// ----------------------------------------
var
     i : Integer ;
     ch : char ;
begin

     FileSeek( FileHandle, FileOffset, 0 ) ;
     for i := 1 to Length(Text) do begin
         FileWrite( FileHandle, Text[i], 1 ) ;
         end ;
     ch := chr(0) ;
     FileWrite( FileHandle, ch, 1 ) ;
     end ;


function TImageFile.TIFOpenFile(
          FileName : string             // Name of TIFF file to be read (IN)
          ) : Boolean ;                 // Returns TRUE if successful
// ---------------
// Open TIFF file
// ---------------
var
     IFDPointer : Integer ;    // Pointer to image file directory
     Done : Boolean ;
begin

     Result := False ;

     if FileHandle >= 0 then begin
        FErrorMessage := 'TIFF: A file is aready open ' ;
        Exit ;
        end ;

     // Open file
     FileHandle := FileOpen( FileName, fmOpenRead ) ;
     if FileHandle < 0 then begin
        FErrorMessage := 'TIFF: Unable to open ' + FileName ;
        Exit ;
        end ;

    // Read TIFF file header
    FileSeek(FileHandle,0,0) ;
    if FileRead(FileHandle, TIFFHeader, SizeOf(TIFFHeader))
        <> SizeOf(TIFFHeader) then begin  ;
        FErrorMessage := 'TIFF: Unable to read file header of' + FileName ;
        FileClose( FileHandle ) ;
        FileHandle := -1 ;
        Exit ;
        end ;
    // Only little-endian (Intel CPUs) byte ordering supported at present
    if TIFFHeader.ByteOrder <> LittleEndian then begin
       FErrorMessage := 'TIFF: Macintosh byte ordering not supported!' ;
       FileClose( FileHandle ) ;
       FileHandle := -1 ;
       Exit ;
       end ;

    // A .stk file ending indicates that this is a Universal Imaging
    // stack file which has to be processed specially

    if LowerCase(ExtractFileExt(FileName)) = '.stk' then UICSTKFormat := True
                                                    else UICSTKFormat := False ;


    // Get pointers to all IFDs within file and key image properties
    // -------------------------------------------------------------

    IFDPointer := TIFFHeader.IFDOffset ; // Pointer to first IFD
    FNumFrames := 0 ;
    Done := False ;
    while not Done do begin

       // Store IFD point for this image
       FIFDPointerList[FNumFrames] := IFDPointer ;

       // Read image file directory
       TIFLoadIFD( IFDPointer ) ;

       FNumPixelsPerFrame := FFrameWidth*FFrameHeight ;
       FNumBytesPerFrame := FNumPixelsPerFrame*FNumBytesPerPixel ;

       // Get spatial resolution information
       Case IFD.ResolutionUnit of
            1 : FResolutionUnit := '' ;
            2 : FResolutionUnit := 'inches' ;
            3 : FResolutionUnit := 'cm' ;
            else FResolutionUnit := '??' ;
            end ;

       // Read image description field
       FDescription := IFD.Description ;

       // If this is Universal Imaging STK format file get number of frames

       if UICSTKFormat then begin
          if IFD.UIC1Tag > 0 then begin
             FNumFrames := IFD.UICNumFrames ;
             FileSeek( FileHandle, IFD.UIC1Tag, 0 ) ;
       //      FileRead( FileHandle, Buf, IFD.UICNumFrames*8 ) ;
             end ;
          if IFD.UIC2Tag > 0 then begin
             FNumFrames := IFD.UICNumFrames ;
             FileSeek( FileHandle, IFD.UIC1Tag, 0 ) ;
       //      FileRead( FileHandle, Buf, IFD.UICNumFrames*8 ) ;
             end ;
          end
       else Inc(FNumFrames) ;

       // Null pointer indicates last IFD
       if IFD.NextIFDOffset > 0 then IFDPointer := IFD.NextIFDOffset
                                else Done := True ;

       end ;

    // TIFF/STK file properties
    Properties.Clear ;
    if UICSTKFormat then Properties.Add('Format: Universal Imaging STK format.')
                    else Properties.Add('Format: Tagged Image File Format (TIFF).');
    Properties.Add(format('Image Size: %d x %d (%d bits per pixel)',
    [FFrameWidth,FFrameHeight,FPixelDepth])) ;
    Properties.Add(format('Pixel resolution: %.4g %s ',[FXResolution,FResolutionUnit])) ;

    if IFD.DateTime <> '' then Properties.Add(format('Created: ',[IFD.DateTime])) ;
    if IFD.Artist <> '' then Properties.Add(format('Artist: ',[IFD.Artist])) ;
    if IFD.Copyright <> '' then Properties.Add(format('Copyright: ',[IFD.Copyright])) ;

    Result := True ;

    end ;


function TImageFile.TIFCreateFile(
         FileName : String ;      // Name of file to be created
         FrameWidth : Integer ;   // Frame width
         FrameHeight : Integer ;  // Frame height
         PixelDepth : Integer ;   // No. of bits per pixel
         ComponentsPerPixel : Integer ;   // No. of colour components/pixel
         SingleFrame : Boolean    // TRUE = single image in TIF
          ) : Boolean ;           // Returns TRUE if file created OK
// ---------------------------------
// Create empty BioRad TIFF data file
// ---------------------------------
var
    i : Integer ;
begin

    Result := False ;

    if FileHandle >= 0 then begin
       FErrorMessage := 'TIMAGEFILE: A file is aready open ' ;
       Exit ;
       end ;

    // Open file
    FileHandle := FileCreate( FileName, fmOpenRead ) ;
    if FileHandle < 0 then begin
       FErrorMessage := 'TIMAGEFILE: Unable to create ' + FileName ;
       Exit ;
       end ;

    // Initialise file header`
    FFrameWidth := FrameWidth ;
    FFrameHeight := FrameHeight ;
    FPixelDepth := PixelDepth ;
    FComponentsPerPixel := ComponentsPerPixel ;
    FNumBytesPerPixel := (((FPixelDepth-1) div 8) + 1)*FComponentsPerPixel ;

    FNumPixelsPerFrame := FFrameWidth*FFrameHeight ;
    FNumBytesPerFrame := FNumPixelsPerFrame*FNumBytesPerPixel ;

    FNumFrames := 0 ;
    TIFSingleFrame := SingleFrame ;

    // Clear array of pointers to frame IFDs
    for i := 0 to High(FIFDPointerList) do FIFDPointerList[i] := 0 ;

    // Write TIFF file header
    TIFFHeader.ByteOrder := LittleEndian ;
    TIFFHeader.Signature := TIFSignature ;
    TIFFHeader.IFDOffset := 8 ;
    FileSeek(FileHandle,0,0) ;
    FileWrite(FileHandle, TIFFHeader, SizeOf(TIFFHeader)) ;

    Result := True ;

    end ;


function TImageFile.TIFCloseFile : Boolean ;
// ---------------
// Close TIFF file
// ---------------
var
    iFrame : Integer ;
begin

     Result := False ;
     if FileHandle < 0 then Exit ;

     if NewFile then begin
        // Ensure that all frames have IFDs
        for iFrame := 1 to FNumFrames do begin
            if FIFDPointerList[iFrame-1] = 0 then TIFSaveIFD( iFrame, False ) ;
            end ;

        TIFSaveIFD( FNumFrames, True ) ;
        end ;

     // Close file
     FileClose(FileHandle) ;
     FileHandle := -1 ;

     Result := True ;

     end ;


function TImageFile.STKCloseFile : Boolean ;
// ---------------
// Close STK file
// ---------------
var
    FilePointer : Int64 ;
begin

     if FileHandle >= 0 then begin

        if NewFile then begin
           // Save IFD
           FilePointer := FileSeek( FileHandle, 0, 2 ) ;
           TIFFHeader.IFDOffset := TIFSaveIFD( 1, True ) ;

           // Write TIFF file header
           FileSeek(FileHandle,0,0) ;
           FileWrite(FileHandle, TIFFHeader, SizeOf(TIFFHeader)) ;
           end ;

        // Close file
        FileClose(FileHandle) ;
        FileHandle := -1 ;

        Result := True ;
        end
     else Result := False ;

     end ;



Function TImageFile.TIFLoadIFD(
         IFDPointer : Integer    // Pointer offset to IFD in data file
         ) : Boolean ;
// -----------------------------------
// Load image file directory from file
// -----------------------------------
var
    IFDCount : SmallInt ;
    i : Integer ;
    IFDEntry : TTiffIFDEntry ;
    IFDList : Array[0..100] of  TTiffIFDEntry ;
    Done : Boolean ;
    NumIFDEntries : Integer ;
    FieldType : Integer ;
    NumValues : Cardinal ;
    FileOffset : Cardinal ;
    Value : Single ;
    Values : Array[0..99] of Cardinal ;
    OK : Boolean ;
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
           IFDList[NumIFDEntries] := IFDEntry ;
           outputdebugString(PChar(format('%d %d %d %d',[IFDList[NumIFDEntries].Tag,
                                                 IFDList[NumIFDEntries].FieldType,
                                                 IFDList[NumIFDEntries].Count,
                                                 IFDList[NumIFDEntries].Offset]))) ;
           Inc(NumIFDEntries) ;
           Dec(IFDCount) ;
           if IFDCount = 0 then Done := True ;
           end
        else begin
           FErrorMessage := 'TIFF: Error reading IFD' ;
           Done := True ;
           end ;
        end ;

    IFD.NextIFDOffset := 0 ;
    FileRead(FileHandle, IFD.NextIFDOffset, SizeOf(IFD.NextIFDOffset) ) ;

    // Image dimensions
    GetIFDEntry( IFDList,NumIFDEntries,ImageWidthTag,
                 FieldType, NumValues, FFrameWidth ) ;
    GetIFDEntry( IFDList, NumIFDEntries, ImageLengthTag,
                 FieldType, NumValues, FFrameHeight ) ;

    GetIFDEntry( IFDList, NumIFDEntries, BitsPerSampleTag,
                 FieldType, NumValues, Values[0] ) ;
    if NumValues > 1 then TIFReadIntegerValues(Values[0],FieldType,NumValues,Values) ;
    FPixelDepth := Values[0] ;

    // Number of colour components per pixel
    FComponentsPerPixel := 1 ;
    GetIFDEntry( IFDList, NumIFDEntries, SamplesPerPixelTag,
                 FieldType, NumValues, FComponentsPerPixel ) ;

    // Calculate number of bytes per pixel
    FNumBytesPerPixel := (((FPixelDepth-1) div 8) + 1)*FComponentsPerPixel ;

    FNumPixelsPerFrame := FFrameWidth*FFrameHeight ;
    FNumBytesPerFrame := FNumPixelsPerFrame*FNumBytesPerPixel ;

    // Image compression type
    IFD.Compression := NoCompression ;
    GetIFDEntry( IFDList, NumIFDEntries, CompressionTag,
                 FieldType, NumValues, IFD.Compression ) ;

    // Get image sub-file type
    IFD.SubFileType := 0 ;
    GetIFDEntry( IFDList, NumIFDEntries, NewSubFileTypeTag,
                 FieldType, NumValues, IFD.SubFileType ) ;

    // Get spatial resolution information
    GetIFDEntry( IFDList, NumIFDEntries, ResolutionUnitTag,
                 FieldType, NumValues, IFD.ResolutionUnit ) ;

    GetIFDEntry( IFDList, NumIFDEntries, XResolutionTag,
                 FieldType, NumValues, FileOffset ) ;
    if NumValues > 0 then begin
       Value := ReadRationalField(FileHandle,FileOffset) ;
       if Value <> 0.0 then FXResolution := 1.0 / Value ;
       end ;

    GetIFDEntry( IFDList, NumIFDEntries, YResolutionTag,
                 FieldType, NumValues, FileOffset ) ;
    if NumValues > 0 then begin
       Value := ReadRationalField(FileHandle,FileOffset) ;
       if Value <> 0.0 then FYResolution :=  1.0 / Value ;
       end ;

    // Read copyright field
    IFD.Copyright := '' ;
    GetIFDEntry( IFDList, NumIFDEntries, CopyrightTag,
                 FieldType, NumValues, FileOffset ) ;
    if NumValues > 0 then IFD.Copyright :=  ReadASCIIField(FileHandle,FileOffset,NumValues) ;

    // Read date/time field
    IFD.DateTime := '' ;
    GetIFDEntry( IFDList, NumIFDEntries, DateTimeTag,
                 FieldType,  NumValues, FileOffset ) ;
    if NumValues > 0 then IFD.DateTime :=  ReadASCIIField(FileHandle,FileOffset,NumValues) ;

    // Read artist field
    IFD.Artist := '' ;
    GetIFDEntry( IFDList, NumIFDEntries, ArtistTag,
                 FieldType, NumValues, FileOffset ) ;
    if NumValues > 0 then IFD.Artist :=  ReadASCIIField(FileHandle,FileOffset,NumValues) ;

    // Read image description field
    IFD.Description := '' ;
    GetIFDEntry( IFDList, NumIFDEntries, ImageDescriptionTag,
                 FieldType, NumValues, FileOffset ) ;
    if NumValues > 0 then IFD.Description :=  ReadASCIIField(FileHandle,FileOffset,NumValues) ;

    // Get Universal Imaging STK format tags
    IFD.UIC1Tag := 0 ;
    GetIFDEntry( IFDList, NumIFDEntries, UIC1Tag,
                 FieldType, NumValues, FileOffset ) ;
    if NumValues > 0 then begin
       IFD.UIC1Tag := FileOffset ;
       IFD.UICNumFrames := NumValues ;
       FileSeek( FileHandle, FileOffset, 0 ) ;
//       FileRead( FileHandle, Buf, NumValues*8 ) ;
       end
    else IFD.UIC1Tag := 0 ;

    GetIFDEntry( IFDList, NumIFDEntries, UIC2Tag,
                 FieldType, NumValues, FileOffset ) ;
    if NumValues > 0 then begin
       IFD.UIC2Tag := FileOffset ;
       IFD.UICNumFrames := NumValues ;
       end
    else IFD.UIC2Tag := 0 ;

    // Get pointers to image strips
    OK := GetIFDEntry( IFDList, NumIFDEntries, StripOffsetsTag,
                       FieldType, IFD.NumStrips, FileOffset ) ;
    if OK then begin
       for i := 0 to High(IFD.StripOffsets) do IFD.StripOffsets[i] := 0 ;
       if IFD.NumStrips > 1 then begin
          FileSeek( FileHandle, FileOffset, 0 ) ;
          FileRead( FileHandle, IFD.StripOffsets, IFD.NumStrips*4 ) ;
          end
       else IFD.StripOffsets[0] := FileOffset ;
       end
    else Exit ;

    // Get number of bytes in each image strip
    OK := GetIFDEntry( IFDList, NumIFDEntries, StripByteCountsTag,
                       FieldType, IFD.NumStrips, FileOffset ) ;
    if OK then begin
       for i := 0 to High(IFD.StripByteCounts) do IFD.StripByteCounts[i] := 0 ;
       if IFD.NumStrips > 1 then begin
          FileSeek( FileHandle, FileOffset, 0 ) ;
          FileRead( FileHandle, IFD.StripByteCounts, IFD.NumStrips*4 ) ;
          end
       else IFD.StripByteCounts[0] := FileOffset ;
       end
    else Exit ;

    // Get number of image rows in each strip
    GetIFDEntry( IFDList, NumIFDEntries, RowsPerStripTag,
                 FieldType, NumValues, IFD.RowsPerStrip ) ;

    end ;


procedure TImageFile.TIFReadIntegerValues(
          FileOffset : Cardinal ;            // Byte offset of start of values
          FieldType : Integer ;             // Type of integer values
          NumValues : Cardinal ;             // No. of values in array
          var Values : Array of Cardinal     // Return array
          ) ;
// -----------------------------------------------
// Read array of unsigned integer IFD field values
// -----------------------------------------------
var
     i : Integer ;
     IValue : Cardinal ;
     FieldSize : Cardinal ;
begin

     case FieldType of
          ByteField : FieldSize := ByteFieldSize ;
          ShortField : FieldSize := ShortFieldSize ;
          LongField : FieldSize := LongFieldSize ;
          SShortField : FieldSize := SShortFieldSize ;
          SLongField : FieldSize := SLongFieldSize ;
          end ;

     IValue := 0 ;
     FileSeek( FileHandle, FileOffset, 0 ) ;
     for i := 0 to NumValues-1 do begin
         FileRead( FileHandle, IValue, FieldSize ) ;
         Values[i] := IValue ;
         end ;
     end ;


procedure TImageFile.TIFWriteIntegerValues(
          FileOffset : Cardinal ;            // Byte offset to write values at
          FieldType : Integer ;             // Type of integer values
          NumValues : Cardinal ;             // No. of values in array
          var Values : Array of Cardinal     // Return array
          ) ;
// ------------------------------------------------
// Write array of unsigned integer IFD field values
// ------------------------------------------------
var
     i : Integer ;
     FieldSize : Integer ;
begin

     case FieldType of
          ByteField : FieldSize := ByteFieldSize ;
          ShortField : FieldSize := ShortFieldSize ;
          LongField : FieldSize := LongFieldSize ;
          SShortField : FieldSize := SShortFieldSize ;
          SLongField : FieldSize := SLongFieldSize ;
          end ;

     FileSeek( FileHandle, FileOffset, 0 ) ;
     for i := 0 to NumValues-1 do begin
         FileWrite( FileHandle, Values[i], FieldSize ) ;
         end ;
     end ;


Function TImageFile.TIFSaveIFD(
         FrameNum : Integer ;          // Frame Number (IN)
         EndOfFile : Boolean
         ) : Integer ;                // File pointer to IFD returned
// -----------------------------------
// Save image file directory to file
// -----------------------------------
var
    IFDCount : Word ;  // IFD list entry counter
    IFDList : Array[0..cIFDMaxTags-1] of  TTiffIFDEntry ;
    Temp : TTiffIFDEntry ;
    i,j : Integer ;
    Numerator, Denominator : Integer ;
    IValues : Array[0..9] of Cardinal ;
    NumBytesToWrite : Cardinal ;
    NumBytesPerImage : Cardinal ;
    NumBytes : Cardinal ;
    IFDPointer : Cardinal ;
    OK : Boolean ;
begin

    NumBytesPerImage := FFrameWidth*FFrameHeight*FNumBytesPerPixel ;
    IFDPointer := (FrameNum-1)*(cIFDImageStart + NumBytesPerImage) + SizeOf(TIFFHeader);
    FIFDPointerList[FrameNum-1] := IFDPointer ;

    // Move file pointer to end of tag list space
    FileSeek( FileHandle, IFDPointer + SizeOf(IFDList) + 8, 0 ) ;

    // Clear IFD entry counter
    IFDCount := 0 ;

    // Image dimensions
    SetIFDEntry( IFDList, IFDCount, ImageWidthTag, LongField, 1, FFrameWidth ) ;
    SetIFDEntry( IFDList, IFDCount, ImageLengthTag, LongField, 1, FFrameHeight ) ;

    // No. of colour components per pixel
    SetIFDEntry( IFDList, IFDCount, SamplesPerPixelTag, ShortField, 1, FComponentsPerPixel ) ;

    // No. of bits per colour component
    if FComponentsPerPixel = 1 then begin
       // Grey scale (single component images)
       SetIFDEntry( IFDList, IFDCount, BitsPerSampleTag, ShortField, 1, FPixelDepth ) ;
       SetIFDEntry( IFDList, IFDCount, PhotoMetricInterpretationTag, ShortField,
                    1, BlackIsZero ) ;
       end
    else begin
       // Colour (multiple component image)
       for i := 0 to FComponentsPerPixel-1 do IValues[i] := FPixelDepth ;
       IFD.SamplesPerPixelPointer := FileSeek( FileHandle, 0, 1 ) ;
       TIFWriteIntegerValues( IFD.SamplesPerPixelPointer, ShortField,
                              FComponentsPerPixel, IValues ) ;
       SetIFDEntry( IFDList, IFDCount, BitsPerSampleTag, ShortField,
                    FComponentsPerPixel, IFD.SamplesPerPixelPointer ) ;
       SetIFDEntry( IFDList, IFDCount, PhotoMetricInterpretationTag, ShortField,
                    1, RGB ) ;
       end ;

    // Image compression type
    IFD.Compression := NoCompression ;
    SetIFDEntry( IFDList, IFDCount, CompressionTag, ShortField, 1, IFD.Compression ) ;

    // Set image sub-file type
    if TIFSingleFrame then IFD.SubFileType := 0
                      else IFD.SubFileType := MultiPageImageBit ;
    SetIFDEntry( IFDList, IFDCount, NewSubFileTypeTag, LongField, 1, 0 ) ;

    // Set page number
    if not TIFSingleFrame then begin
       IFD.PageNumber := FrameNum ;
       SetIFDEntry( IFDList, IFDCount, PageNumberTag, ShortField, 1, IFD.PageNumber ) ;
       end ;

    // Set spatial resolution information
    if FResolutionUnit = 'inches' then IFD.ResolutionUnit := 2
    else if FResolutionUnit = 'cm' then IFD.ResolutionUnit := 3
    else IFD.ResolutionUnit := 1 ;
    SetIFDEntry( IFDList, IFDCount, ResolutionUnitTag, ShortField, 1, IFD.ResolutionUnit ) ;

    // X resolution
    IFD.XResolutionPointer := FileSeek( FileHandle, 0, 1 ) ;
    WriteRationalField( IFD.XResolutionPointer, 1.0/FXResolution ) ;
    SetIFDEntry( IFDList, IFDCount, XResolutionTag, RationalField, 1, IFD.XResolutionPointer ) ;

    // Y resolution
    IFD.YResolutionPointer := FileSeek( FileHandle, 0, 1 ) ;
    WriteRationalField( IFD.YResolutionPointer, 1.0/FYResolution ) ;
    SetIFDEntry( IFDList, IFDCount, YResolutionTag, RationalField, 1, IFD.YResolutionPointer ) ;

    // Calculate strip offsets and byte counts
    IFD.NumStrips := 0 ;
    NumBytesToWrite := NumBytesPerImage ;
    IFD.StripOffsets[0] := IFDPointer + cIFDImageStart ;
    while NumBytesToWrite > 0 do begin
       // Write strip
       NumBytes := Min(NumBytesToWrite,cIFDMaxBytesPerStrip) ;
       IFD.StripByteCounts[IFD.NumStrips] := NumBytes ;
       Inc(IFD.NumStrips) ;
       IFD.StripOffsets[IFD.NumStrips] := IFD.StripOffsets[IFD.NumStrips-1] + NumBytes ;
       NumBytesToWrite := NumBytesToWrite - NumBytes ;
       end ;

    // Write strip offsets & byte counts
    if IFD.NumStrips > 1 then begin
       IFD.StripOffsetsPointer := FileSeek( FileHandle, 0, 1 ) ;
       FileWrite( FileHandle, IFD.StripOffsets, cIFDMaxStrips*4 ) ;
       IFD.StripByteCountsPointer := FileSeek( FileHandle, 0, 1 ) ;
       FileWrite( FileHandle, IFD.StripByteCounts, cIFDMaxStrips*4 ) ;
       end
    else begin
       // Offsets stored in .Offset field for single strip files
       IFD.StripOffsetsPointer := IFD.StripOffsets[0] ;
       IFD.StripByteCountsPointer := IFD.StripByteCounts[0] ;
       end ;

    // Update strip offsets & byte counts IFD entry
    SetIFDEntry( IFDList, IFDCount, StripOffsetsTag, LongField,
                 IFD.NumStrips, IFD.StripOffsetsPointer ) ;
    SetIFDEntry( IFDList, IFDCount, StripByteCountsTag, LongField,
                 IFD.NumStrips, IFD.StripByteCountsPointer ) ;

    // Number of image rows in each strip
    IFD.RowsPerStrip := IFD.StripByteCounts[0] div
                        (FFrameWidth*FNumBytesPerPixel) ;
    SetIFDEntry( IFDList, IFDCount, RowsPerStripTag, LongField, 1, IFD.RowsPerStrip ) ;

    i := 0 ;
    SetIFDEntry( IFDList, IFDCount, ImageDescriptionTag, ASCIIField, 4, i ) ;

    // Write STK format tag
    if UICSTKFormat then begin
       Numerator := 1 ;
       Denominator := 1 ;
       IFD.UIC1Tag := FileSeek( FileHandle, 0, 1 ) ;
       for i := 1 to FNumFrames do begin
           FileWrite( FileHandle, Numerator, 4 ) ;
           FileWrite( FileHandle, Denominator, 4 ) ;
           end ;
       SetIFDEntry( IFDList, IFDCount, UIC1Tag, RationalField, FNumFrames, IFD.UIC1Tag ) ;
       end ;

    for i := 0 to IFDCount-1 do begin
        for j := i+1 to IFDCount-1 do begin
            if IFDList[j].Tag < IFDList[i].Tag then begin
               Temp := IFDList[i] ;
               IFDList[i] := IFDList[j] ;
               IFDList[j] := Temp ;
               end ;
            end ;
        end ;

    FileSeek( FileHandle, IFDPointer, 0 ) ;

    // Write number of IFD entries
    FileWrite(FileHandle, IFDCount, SizeOf(IFDCount) ) ;

    // Write IFD entries
    for i := 0 to IFDCount-1 do begin
        FileWrite(FileHandle, IFDList[i], SizeOf(TTiffIFDEntry)) ;
        end ;

    // Write offset to next IFD
    if EndOfFile then IFD.NextIFDOffset := 0
    else begin
       IFD.NextIFDOffset := IFDPointer + cIFDImageStart + NumBytesPerImage ;
       end ;
    FileWrite(FileHandle, IFD.NextIFDOffset, SizeOf(IFD.NextIFDOffset) ) ;

    // Return IFD pointer
    Result := IFDPointer ;

    end ;


Function TImageFile.TIFLoadFrame(
         FrameNum : Integer ; // Frame # to load
         PImageBuf : Pointer  // Pointer to buffer to receive image
         ) : Boolean ;        // Returns TRUE if frame available
// --------------------------------------
// Load frame # <FrameNum> from TIFF file
// --------------------------------------
var
    IFDPointer : Integer ;    // Pointer to image file directory
    OK : Boolean ;
    Strip : Integer ;
    PBuf : Pointer ;

begin

     Result := False ;
     if (NumFrames <= 0) or
        (FrameNum <= 0) or
        (FrameNum > NumFrames) then Exit ;

     // Read IFD
     IFDPointer := FIFDPointerList[FrameNum-1] ;
     OK := TIFLoadIFD( IFDPointer ) ;

     // Read image
     PBuf := PImageBuf ;
     for Strip := 0 to IFD.NumStrips-1 do begin
         FileSeek( FileHandle, IFD.StripOffsets[Strip], 0 ) ;
         FileRead( FileHandle, PByteArray(PBuf)^, IFD.StripByteCounts[Strip] ) ;
         PBuf := Ptr(Integer(PBuf) + IFD.StripByteCounts[Strip]) ;
         end ;

     Result := True ;
     end ;


Function TImageFile.TIFSaveFrame(
         FrameNum : Integer ; // Frame # to save
         PImageBuf : Pointer  // Pointer to buffer to receive image
         ) : Boolean ;        // Returns TRUE if frame saved OK
// --------------------------------------
// Save frame # <FrameNum> to TIFF file
// --------------------------------------
var
    Strip : Cardinal ;
    PBuf : Pointer ;
begin

     Result := False ;

     // Load IFD if one exists, or create a new one
     if FIFDPointerList[FrameNum-1] <= 0 then TIFSaveIFD( FrameNum, false )
                                         else TIFLoadIFD( FIFDPointerList[FrameNum-1] ) ;

     // Write frame to standard multi-page TIFF file
     PBuf := PImageBuf ;
     for Strip := 0 to IFD.NumStrips-1 do begin
         FileSeek( FileHandle, IFD.StripOffsets[Strip], 0 ) ;
         FileWrite( FileHandle, PByteArray(PBuf)^, IFD.StripByteCounts[Strip] ) ;
         PBuf := Ptr(Integer(PBuf) + IFD.StripByteCounts[Strip]) ;
         end ;

     FNumFrames := Max(FrameNum,FNumFrames) ;

     Result := True ;
     end ;


function TImageFile.STKCreateFile(
         FileName : String ;      // Name of file to be created
         FrameWidth : Integer ;   // Frame width
         FrameHeight : Integer ;  // Frame height
         PixelDepth : Integer ;    // No. of bits per pixel
         ComponentsPerPixel : Integer  // No. colour components per pixel
          ) : Boolean ;           // Returns TRUE if file created OK
// --------------------------
// Create empty STK data file
// --------------------------
var
    i : Integer ;
    FilePointer : Int64 ;
    NumBytesPerStrip,NumBytesToWrite,NumBytes : Cardinal ;
begin

    Result := False ;

    if FileHandle >= 0 then begin
       FErrorMessage := 'TIMAGEFILE: A file is aready open ' ;
       Exit ;
       end ;

    // Open file
    FileHandle := FileCreate( FileName, fmOpenRead ) ;
    if FileHandle < 0 then begin
       FErrorMessage := 'TIMAGEFILE: Unable to create ' + FileName ;
       Exit ;
       end ;

    // Initialise file header`
    FFrameWidth := FrameWidth ;
    FFrameHeight := FrameHeight ;
    FPixelDepth := PixelDepth ;
    FComponentsPerPixel := ComponentsPerPixel ;
    FNumBytesPerPixel := (((PixelDepth-1) div 8) + 1)*FComponentsPerPixel ;

    FNumPixelsPerFrame := FFrameWidth*FFrameHeight ;
    FNumBytesPerFrame := FNumPixelsPerFrame*FNumBytesPerPixel ;

    FNumFrames := 0 ;
    UICSTKFormat := True ;
    TIFSingleFrame := True ;

    // Clear array of pointers to frame IFDs
    for i := 0 to High(FIFDPointerList) do FIFDPointerList[i] := 0 ;

    // Write TIFF file header
    TIFFHeader.ByteOrder := LittleEndian ;
    TIFFHeader.Signature := TIFSignature ;
    TIFFHeader.IFDOffset := 0 ;
    FileSeek(FileHandle,0,0) ;
    FileWrite(FileHandle, TIFFHeader, SizeOf(TIFFHeader)) ;

    Result := True ;

    end ;


Function TImageFile.STKLoadFrame(
         FrameNum : Integer ; // Frame # to load
         PImageBuf : Pointer  // Pointer to buffer to receive image
         ) : Boolean ;        // Returns TRUE if frame available
// --------------------------------------
// Load frame # <FrameNum> from STKle
// --------------------------------------
var
    FrameOffset : Int64 ;
begin

     Result := False ;
     if (NumFrames <= 0) or
        (FrameNum <= 0) or
        (FrameNum > NumFrames) then Exit ;

     // Read image
     FrameOffset := Int64(FrameNum-1)*Int64( IFD.StripOffsets[IFD.NumStrips-1] +
                                             IFD.StripByteCounts[IFD.NumStrips-1] -
                                             IFD.StripOffsets[0] )
                     + Int64(IFD.StripOffsets[0]) ;
     FileSeek( FileHandle, FrameOffset, 0 ) ;
     FileRead( FileHandle, PByteArray(PImageBuf)^, FNumBytesPerFrame ) ;

     Result := True ;
     end ;


Function TImageFile.STKSaveFrame(
         FrameNum : Integer ; // Frame # to load
         PImageBuf : Pointer  // Pointer to buffer to holding image
         ) : Boolean ;        // Returns TRUE if frame saved
// --------------------------------------
// Save frame # <FrameNum> to STK file
// --------------------------------------
var
    FrameOffset : Int64 ;

begin

     Result := False ;

     // Frame
     FrameOffset := Int64(FrameNum-1)*Int64(FNumBytesPerFrame)
                     + Int64(cIFDImageStart + SizeOf(TIFFHeader)) ;

     // Frames are located in a contiguous block starting at
     // cIFDImageStart + SizeOf(TIFFHeader)

     FileSeek( FileHandle, FrameOffset, 0 ) ;
     FileWrite( FileHandle, PByteArray(PImageBuf)^, FNumBytesPerFrame ) ;

     FNumFrames :=  Max( FrameNum, FNumFrames ) ;

     Result := True ;

     end ;


function TImageFile.ICSOpenFile(
         FileName : String
         ) : Boolean ;
// ---------------------------
// Open ICS data file
// ---------------------------
const
    MaxParameters = 20 ;
var
    s,ICSText : String ;
    Pars : Array[0..10] of String ;
    Values : Array[0..10] of Integer ;
    Done : Boolean ;        // Loop done flag
    NumSpaces,NumBytes,NumValues : Integer ;
    i,ix  : Integer ;
    iByte : Byte ;
    NumParameters,Code  : Integer ;
    FrameRate : Single ;
    Key : String ;

    iValues : Array[0..MaxParameters-1] of Integer ;
    Labels : Array[0..MaxParameters-1] of String ;
    Units : Array[0..MaxParameters-1] of String ;
    ScaleFactors : Array[0..MaxParameters-1] of Single ;
    TimePoints : Array[0..MaxParameters-1] of Single ;
    TimeUnits : String ;
begin

    Result := False ;

    if FileHandle >= 0 then begin
       FErrorMessage := 'TIMAGEFILE: A file is aready open ' ;
       Exit ;
       end ;

    // Open file
    FileHandle := FileOpen( FileName, fmOpenReadWrite ) ;
    if FileHandle < 0 then begin
       FErrorMessage := 'TIMAGEFILE: Unable to open ' ;
       Exit ;
       end ;

    // Read ICS file definition text
    NumBytes := FileSeek(FileHandle,0,2) ;
    FileSeek( FileHandle, 0, 0 ) ;
    ICSText := '' ;
    for i := 1 to NumBytes do begin
       FileRead(FileHandle, iByte, 1) ;
       ICSText := ICSText + Char(iByte) ;
       end ;
    FileClose( FileHandle ) ;

   // Find number of parameters
   Key := 'layout'+#9+'parameters'+#9 ;
   ix := Pos( Key, ICSText ) + Length(Key) ;
   s := '' ;
   while ICSText[ix] <> #13 do begin
      s := s + ICSText[ix] ;
      Inc(ix) ;
      end ;
   Val(s,NumParameters,Code) ;

   // Get parameter order
   Key := 'layout'+#9+'order'+#9 ;
   ix := Pos( Key, ICSText ) + Length(Key) ;
   for i := 0 to NumParameters-1 do begin
       Pars[i] := '' ;
       while (ICSText[ix] <> #13) and (ICSText[ix] <> #9) do begin
          Pars[i] := Pars[i] + ICSText[ix] ;
          Inc(ix) ;
          end ;
       inc(ix) ;
       end ;

   // Get parameter values
   Key :='layout'+#9+'sizes'+#9 ;
   ix := Pos( Key, ICSText ) + Length(Key) ;
   for i := 0 to NumParameters-1 do begin
       s := '' ;
       while (ICSText[ix] <> #13) and (ICSText[ix] <> #9) do begin
          s := s + ICSText[ix] ;
          Inc(ix) ;
          end ;
       Val(s,Values[i],Code) ;
       Inc(ix) ;
       end ;

   // Read parameters
   for i := 0 to NumParameters-1 do begin
       if Pars[i] = 'bits' then FPixelDepth := Values[i]
       else if Pars[i] = 'ch' then FComponentsPerPixel := Values[i]
       else if Pars[i] = 'x' then FFrameWidth := Values[i]
       else if Pars[i] = 'y' then FFrameHeight := Values[i]
       else if Pars[i] = 't' then FNumFrames := Values[i] ;
       end ;

    FNumBytesPerPixel := (((FPixelDepth-1) div 8) + 1) ;

    FNumFrames := FNumFrames*FComponentsPerPixel ;

    FNumPixelsPerFrame := FFrameWidth*FFrameHeight ;
    FNumBytesPerFrame := FNumPixelsPerFrame*FNumBytesPerPixel ;

    ICSGetIntParameters( 'layout'+#9+'significant_bits'+#9,
                         ICSText,iValues,NumValues ) ;
    FPixelDepth := iValues[0] ;

    // Get units  list
    ICSGetStringParameters( 'parameter'+#9+'labels'+#9, ICSText,Labels, NumValues ) ;
    ICSGetStringParameters( 'parameter'+#9+'units'+#9, ICSText,Units, NumValues ) ;
    ICSGetFltParameters( 'parameter'+#9+'scale'+#9, ICSText,ScaleFactors, NumValues ) ;

    for i := 0 to NumValues-1 do begin
        if Labels[i] = 'x' then begin
           FXResolution := ScaleFactors[i] ;
           FResolutionUnit := Units[i] ;
           end ;
        if Labels[i] = 'y' then begin
           FYResolution := ScaleFactors[i] ;
           end ;
        if Labels[i] = 't' then begin
           TimeUnits := Units[i] ;
           end ;
        end ;

    FZResolution := 1.0 ;

    // Get inter-frame interval
    ICSGetFltParameters( 'parameter'+#9+'t'+#9, ICSText,TimePoints, NumValues ) ;
    if NumValues > 1 then begin
       FTResolution := 0.0 ;
       for i := 1 to NumValues-1 do
           FTResolution := FTResolution + TimePoints[i] - TimePoints[i-1] ;
       FTResolution := FTResolution / ((NumValues-1)*FComponentsPerPixel) ;
       if LowerCase(TimeUnits) = 'ms' then FTResolution := FTResolution*0.001 ;
       end ;
    if FTResolution <= 0.0 then FTResolution := 1.0 ;

    // PIC file properties
    Properties.Add('Format: Nikon ICS File') ;
    Properties.Add(format('Image Size: %d x %d (%d bits per pixel)',
    [FFrameWidth,FFrameHeight,FPixelDepth])) ;
    Properties.Add(format('Pixel resolution: %.4g %s ',[FXResolution,FResolutionUnit])) ;
    Properties.Add(format('Frame Interval: %.4g %s ',[FTResolution,FResolutionUnit])) ;

    // Add ICS parameters to properties list
    s := '' ;
    for ix := 1 to Length(ICSText) do begin
       if ICSText[ix] = #13 then begin
          Properties.Add(s) ;
          s := '' ;
          end
       else s := s + ICSText[ix] ;
       end ;

    // Open data file (.IDS extension)
    FileHandle := FileOpen( ChangeFileExt(FileName,'.ids'), fmOpenReadWrite ) ;

    Result := True ;

    end ;


procedure TImageFile.ICSGetIntParameters(
          Key : String ;
          Source : String ;
          var Values : Array of Integer ;
          var NumValues : Integer
          ) ;
var
    ix,Code : Integer ;
    s : String ;
    Done : Boolean ;
begin

   NumValues := 0 ;

   // Find number of parameters
   ix := Pos( Key, Source ) + Length(Key) ;
   if ix <= 0 then Exit ;

   s := '' ;
   Done := False ;
   while not Done do begin
      if (Source[ix] <> #9) and (Source[ix] <> #13) then begin
          s := s + Source[ix] ;
          end
      else begin
         Val(s,Values[NumValues],Code) ;
         Inc(NumValues) ;
         s := '' ;
         if (Source[ix] = #13) or (NumValues >= High(Values)) then Done := True ;
         end ;
      Inc(ix) ;
      end ;

   end ;


procedure TImageFile.ICSGetFltParameters(
          Key : String ;
          Source : String ;
          var Values : Array of Single ;
          var NumValues : Integer
          ) ;
var
    ix,Code : Integer ;
    s : String ;
    Done : Boolean ;
begin

   NumValues := 0 ;

   // Find number of parameters
   ix := Pos( Key, Source ) + Length(Key) ;
   if ix <= 0 then Exit ;

   s := '' ;
   Done := False ;
   while not Done do begin

      if (Source[ix] <> #9) and (Source[ix] <> #13) then begin
          s := s + Source[ix] ;
          end
      else begin
         Val(s,Values[NumValues],Code) ;
         Inc(NumValues) ;
         s := '' ;
         if (Source[ix] = #13) or (NumValues >= High(Values)) then Done := True ;
         end ;
      Inc(ix) ;
      end ;

   end ;



procedure TImageFile.ICSGetStringParameters(
          Key : String ;
          Source : String ;
          var Values : Array of String ;
          var NumValues : Integer
          ) ;
var
    ix : Integer ;
    s : String ;
    Done : Boolean ;
begin

   NumValues := 0 ;

   // Find number of parameters
   ix := Pos( Key, Source ) + Length(Key) ;
   if ix <= 0 then Exit ;

   s := '' ;
   Done := False ;
   while not Done do begin

      if (Source[ix] <> #9) and (Source[ix] <> #13) then begin
          s := s + Source[ix] ;
          end
      else begin
         Values[NumValues] := s ;
         Inc(NumValues) ;
         s := '' ;
         if (Source[ix] = #13) or (NumValues >= High(Values)) then Done := True ;
         end ;
      Inc(ix) ;
      end ;

   end ;



function TImageFile.ICSCreateFile(
         FileName : String ;
         FrameWidth : Integer ;
         FrameHeight : Integer ;
         PixelDepth : Integer
         ) : Boolean ;
begin
    end ;



function TImageFile.ICSCloseFile : Boolean ;
// ---------------
// Close ICS file
// ---------------
begin
     Result := False ;

     // Exit if file not open
     if FileHandle < 0 then Exit ;

     // Update PIC file header
     if NewFile then begin
        end ;

     // Close file
     FileClose( FileHandle ) ;
     // Note. file handle = -1 indicates no file open
     FileHandle := -1 ;
     FNumFrames := 0 ;
     Result := True ;

     end ;


function TImageFile.ICSLoadFrame(
             FrameNum : Integer ;
             PFrameBuf : Pointer
             ) : Boolean ;
// ----------------------------------------
// Load frame from ICS/IDS data file
// ----------------------------------------
type
    TImageBuf16bit = Array[0..10000000] of SmallInt ;
    PImageBuf16bit = ^TImageBuf16bit ;
    TImageBuf8bit = Array[0..10000000] of Byte ;
    PImageBuf8bit = ^TImageBuf8bit ;

var
    FilePointer : Int64 ;      // File offset
    i,j : Integer ;
    ICSFrameNum : Integer ;
    ICSFNumBytesPerFrame : Integer ;
    pBuf : PImageBuf16bit ;
begin

    if (FrameNum < 1) or (FrameNum > FNumFrames) then begin
       Result := False ;
       Exit ;
       end ;

    ICSFrameNum := (FrameNum-1) div FComponentsPerPixel ;
    ICSFNumBytesPerFrame := FNumBytesPerFrame*FComponentsPerPixel ;

    // Find file offset of start of frame
    FilePointer := Int64(ICSFrameNum)*Int64(ICSFNumBytesPerFrame) ;

    GetMem( pBuf, ICSFNumBytesPerFrame ) ;

    // Read data from file
    FileSeek( FileHandle, FilePointer, 0 ) ;
    if FileRead(FileHandle, pBuf^, ICSFNumBytesPerFrame)
       = ICSFNumBytesPerFrame then begin
       j := (FrameNum-1) mod FComponentsPerPixel ;
       if FNumBytesPerPixel = 2 then begin
          // 16 bit pixels
          for i := 0 to FNumPixelsPerFrame-1 do begin
              PImageBuf16bit(PFrameBuf)^[i] := pBuf^[j] ;
              j := j + FComponentsPerPixel ;
              end ;
          end
       else begin
          // 8 bit pixels
          for i := 0 to FNumPixelsPerFrame-1 do begin
              PImageBuf8bit(PFrameBuf)^[i] := pBuf^[j] ;
              j := j + FComponentsPerPixel ;
              end ;
          end ;
       Result := True ;
       end
    else Result := False ;

    FreeMem(pBuf) ;

    end ;





function TImageFile.ICSSaveFrame(
             FrameNum : Integer ;
             PFrameBuf : Pointer
             ) : Boolean ;
begin
    end ;




procedure TImageFile.AppendFloat(
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


procedure TImageFile.ReadFloat(
          const Source : Array of char;
          Keyword : string ;
          var Value : Single ) ;
var
   Parameter : string ;
begin
     FindParameter( Source, Keyword, Parameter ) ;
     if Parameter <> '' then Value := ExtractFloat( Parameter, 1. ) ;
     end ;


procedure TImageFile.CopyStringToArray(
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
         FErrorMessage := ' Array Full ' ;

     end ;

procedure TImageFile.CopyArrayToString(
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


function TImageFile.StringFromArray(
          var Source : array of char ) : String ;
// --------------------------------------
// Create string variable from char array
// --------------------------------------
var
   i : Integer ;
begin
     Result := '' ;
     for i := 0 to High(Source) do if Source[i] <> #0 then begin
         Result := Result + Source[i] ;
         end ;
     end ;



procedure TImageFile.FindParameter(
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

function TImageFile.ExtractFloat (
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





end.
