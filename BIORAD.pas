unit BIORAD;
// -----------------------------------
// BIORAD file format handling component
// -----------------------------------
// 21.04.03

interface

uses
  SysUtils, Classes, Dialogs ;

const
     PICSignature = 12345 ;


type

  TPICFileHeader = packed record
      FrameWidth : SmallInt ;     // Image width (pixels)
      FrameHeight : SmallInt ;    // Image height (pixels)
      NumFrames : SmallInt ;      // No. images in file
      LUT1Min : SmallInt ;        // Lower intensity limit of LUT map
      LUT1Max : SmallInt ;        // Upper intensity limit of LUT map
      NotesOffset : Integer ;     // Offset of notes lines in file
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
      FLensMagnification : Single ;   // Floating point lens magnfication factor
      Free : Array[1..3] of SmallInt ;
      end ;

  TBIORAD = class(TComponent)
  private
    { Private declarations }
    PICHeader : TPICFileHeader ;   // PIC file header block
    FileHandle : Integer ;         // PIC file handle
    FFrameWidth : Integer ;        // Image width
    FFrameHeight : Integer ;       // Image height
    FPixelDepth : Integer ;        // No. of bits per pixel
    FNumFrames : Integer ;         // No. of images in file

  protected
    { Protected declarations }
  public
    { Public declarations }
    Constructor Create(AOwner : TComponent) ; override ;
    Destructor Destroy ; override ;

    function OpenFile(
             FileName : String
              ) : Boolean ;

    function CreateFile(
             FileName : String ;
             FrameWidth : Integer ;
             FrameHeight : Integer ;
             PixelDepth : Integer
             ) : Boolean ;


    function LoadFrame(
             FrameNum : Integer ;
             PFrameBuf : Pointer
             ) : Boolean ;
    function SaveFrame(
             FrameNum : Integer ;
             PFrameBuf : Pointer
             ) : Boolean ;

  published
    { Published declarations }
    Property FrameWidth : Integer Read FFrameWidth ;
    Property FrameHeight : Integer Read FFrameHeight ;
    Property PixelDepth : Integer Read FPixelDepth ;
    Property NumFrames : Integer Read FNumFrames ;

  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TBIORAD]);
end;

constructor TBIORAD.Create(AOwner : TComponent) ;
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


     end ;




destructor TBIORAD.Destroy ;
{ ------------------------------------
   Tidy up when component is destroyed
   ----------------------------------- }
begin

     // Close PIC file
     if FileHandle >= 0 then FileClose( FileHandle ) ;

     { Call inherited destructor }
     inherited Destroy ;

     end ;


function TBioRAD.OpenFile(
         FileName : String
          ) : Boolean ;
// ---------------------------
// Open BioRad PIC data file
// ---------------------------
var
    Done : Boolean ;        // Loop done flag

begin

    Result := False ;

    if FileHandle >= 0 then begin
       MessageDlg( 'BIORAD: A file is aready open ', mtWarning, [mbOK], 0 ) ;
       Exit ;
       end ;

    // Open file
    FileHandle := FileOpen( FileName, fmOpenRead ) ;
    if FileHandle < 0 then begin
       MessageDlg( 'BIORAD: Unable to open ' + FileName, mtWarning, [mbOK], 0 ) ;
       Exit ;
       end ;

    // Read PIC file header
    FileSeek(FileHandle,0,0) ;
    if FileRead(FileHandle, PICHeader, SizeOf(PICHeader))
        <> SizeOf(PICHeader) then begin  ;
        MessageDlg( 'BIORAD: Unable to read BioRad PIC file ' + FileName, mtWarning, [mbOK], 0 ) ;
        FileClose( FileHandle ) ;
        FileHandle := -1 ;
        Exit ;
        end ;

    // Check PIC file signature
    if PICHeader.Signature <> PICSignature then begin
       MessageDlg( 'BIORAD: ' + FileName + ' not a PIC file!', mtWarning, [mbOK], 0 ) ;
       FileClose( FileHandle ) ;
       FileHandle := -1 ;
       Exit ;
       end ;

    FFrameWidth := PICHeader.FrameWidth ;
    FFrameHeight := PICHeader.FrameHeight ;
    if PICHeader.ByteImage = 1 then FPixelDepth := 8
                               else FPixelDepth := 16 ;
    FNumFrames := PICHeader.NumFrames ;

    Result := True ;

    end ;


function TBioRAD.CreateFile(
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
       MessageDlg( 'BIORAD: A file is aready open ', mtWarning, [mbOK], 0 ) ;
       Exit ;
       end ;

    // Open file
    FileHandle := FileCreate( FileName, fmOpenRead ) ;
    if FileHandle < 0 then begin
       MessageDlg( 'BIORAD: Unable to create ' + FileName, mtWarning, [mbOK], 0 ) ;
       Exit ;
       end ;

    // Initialise file header`
    FFrameWidth := FrameWidth ;
    FFrameHeight := FrameHeight ;
    FPixelDepth := PixelDepth ;
    PICHeader.FrameWidth := FFrameWidth ;
    PICHeader.FrameHeight := FFrameHeight ;
    if FPixelDepth <= 8 then PICHeader.ByteImage := 1
                        else PICHeader.ByteImage := 0 ;
    FNumFrames := 0 ;
    PICHeader.NumFrames := FNumFrames ;
    PICHeader.Signature := PICSignature ;
    Result := True ;

    end ;



function TBioRAD.LoadFrame(
         FrameNum : Integer ;
         PFrameBuf : Pointer
         ) : Boolean ;
// ----------------------------------------
// Load frame from BioRad PIC data file
// ----------------------------------------
var
    NumBytesPerFrame : Integer ; // No. of bytes per image frame
    FilePointer : Integer ;      // File offset
begin

    if (FrameNum < 1) or (FrameNum > FNumFrames) then begin
       Result := False ;
       Exit ;
       end ;

    // Find file offset of start of frame
    NumBytesPerFrame := FFrameWidth*FFrameHeight ;
    if PICHeader.ByteImage <> 1 then NumBytesPerFrame := NumBytesPerFrame*2 ;
    FilePointer := SizeOf(TPICFileHeader) + (FrameNum-1)*NumBytesPerFrame ;

    // Read data from file
    FileSeek( FileHandle, FilePointer, 0 ) ;
    if FileRead(FileHandle, PFrameBuf^, NumBytesPerFrame)
       = NumBytesPerFrame then Result := True
                          else Result := False ;
    end ;


function TBioRAD.SaveFrame(
         FrameNum : Integer ;             // No. of frame to write
         PFrameBuf : Pointer
         ) : Boolean ;// Pointer to image buffer
// ----------------------------------------
// Save frame to BioRad PIC data file
// ----------------------------------------
var
    NumBytesPerFrame : Integer ; // No. of bytes per image frame
    FilePointer : Integer ;      // File offset
begin

    if (FrameNum < 1) then begin
       Result := False ;
       Exit ;
       end ;

    // Find file offset of start of frame
    NumBytesPerFrame := FFrameWidth*FFrameHeight ;
    if PICHeader.ByteImage <> 1 then NumBytesPerFrame := NumBytesPerFrame*2 ;
    FilePointer := SizeOf(TPICFileHeader) + (FrameNum-1)*NumBytesPerFrame ;

    // Read data from file
    FileSeek( FileHandle, FilePointer, 0 ) ;
    if FileWrite(FileHandle, PFrameBuf^, NumBytesPerFrame)
       = NumBytesPerFrame then Result := True
                          else Result := False ;
    end ;

end.
