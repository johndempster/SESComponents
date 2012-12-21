//  WinRTDriver.pas
//  Copyright 1998 BlueWater Systems
//
//  Implementation of WinRT functionality provided outside the WinRT preprocessor.
//
unit WinRTDriver;

interface
uses
    Windows,
    WinRTCtl,
    sysutils;

    Function WinRTCreateEvent(Signaled : boolean; var hWinRTEventHandle : integer) : integer;
    Function WinRTCloseEvent(hEvent : integer) : boolean;
    Function WinRTOpenDevice(DeviceNumber : integer; Sharing : boolean) : integer;
    Function WinRTCloseDevice(hWinRT : integer) : boolean;
    Function WinRTGetFullConfiguration(hWinRT : integer;
                                       var ConfigBuffer : tWINRT_FULL_CONFIGURATION;
                                   var Length : Integer) : boolean;
    Function WinRTProcessIoBuffer(hWinRT : integer;
                                  var Buffer; Size : integer;
                                  var Length : integer) : boolean;
    Function WinRTProcessIoBufferDirect(hWinrt : integer;
                                        var Buffer; Size : integer;
                                        var Length : integer) : boolean;
    Function WinRTProcessDmaBuffer(hWinrt : integer;
                                   var Buffer; Size : integer;
                                   var Length : integer) : boolean;
    Function WinRTProcessDmaBufferDirect(hWinrt : integer;
                                         var Buffer; Size : integer;
                                         var Length : integer) : boolean;
    Function WinRTWaitInterrupt(hWinrt : integer;
                                var Buffer; Size : integer;
                                var Length : integer) : boolean;
    Function WinRTSetInterrupt(hWinrt : integer;
                               var Buffer; Size : integer;
                               var Length : integer) : boolean;
    Function WinRTSetupDmaBuffer(hWinrt : integer;
                                 var Buffer : tWINRT_DMA_BUFFER_INFORMATION;
                                 var Length : integer) : boolean;
    Function WinRTFreeDmaBuffer(hWinrt : integer;
                                var Buffer : tWINRT_DMA_BUFFER_INFORMATION;
                                var Length : integer) : boolean;
    Function WinRTMapMemory(hWinrt : integer; var Buffer;
                            var MemPtr : pointer;
                            var Length : integer) : boolean;
    Function WinRTUnMapMemory(hWinrt : integer;
                              var MemPtr : pointer;
                              var Length : integer) : boolean;
    Function WinRTAutoIncIo(hWinrt : integer;
                            var Inbuff : tWINRT_AUTOINC_ITEM; SizeIn : integer;
                            var Outbuff; SizeOut : integer; var Length : integer) : boolean;

implementation

    // WinRTCreateEvent - creates an auto-resetting event
    // Inputs:  Signaled  - TRUE for initial state signaled
    //                      FALSE for initial state non-signaled
    // Outputs: pWinRTEventHandle - handle to use for
    //                              WinRT script items
    // Returns - Win32 HANDLE to event or NULL for failure.
Function WinRTCreateEvent(Signaled : boolean; var hWinRTEventHandle : integer) : integer;
type
    tOpenVxDHandle = function(handle : integer) : integer; cdecl;
var
    OpenVxDHandle : tOpenVxDHandle;
    EventHandle : integer;
    VersionInformation : tOSVERSIONINFO;
    LibraryHandle : integer;
	Error : integer;
begin

        // create the Win32 accessible event
    EventHandle := CreateEvent(nil, FALSE, Signaled, nil);

    if EventHandle = 0 then begin
            // the handle could not be created
        Result := 0;
        exit;
        end;

        // get the version information to determine if this
        // is running on 95 or NT
    VersionInformation.dwOSVersionInfoSize := sizeof(VersionInformation);
    if (GetVersionEx(VersionInformation)) = False then begin
            // could not retrieve version information
        CloseHandle(EventHandle);
        Result := 0;
        exit;
        end;                                               

    if VER_PLATFORM_WIN32_NT = VersionInformation.dwPlatformId then begin
            // if we're running on NT, the kernel-accessible handle
            // is the same as the Win32 handle
        hWinRTEventHandle := EventHandle;
        Result := EventHandle;
        exit;
        end;

        // load the library with the OpenVxDHandle function
    LibraryHandle := LoadLibrary('kernel32.dll');
    if LibraryHandle = 0 then begin
            // could not load the DLL
        CloseHandle(eventHandle);
        Result := 0;
        exit;
        end;

        // get the function to convert the handle
    @OpenVxDHandle := GetProcAddress(LibraryHandle, 'OpenVxDHandle');
    Error := GetLastError();
    if Error <> 0 then begin
        writeln(format('GetProcAddress("Kernel32.dll", "OpenVxDHandle") failed. Error: %d',
                [Error]));
        Result := 0;
        exit;
        end;

        // call the function to get the VxD-accessible handle
    hWinRTEventHandle := OpenVxDHandle(EventHandle);
    if hWinRTEventHandle = 0 then begin
            // could not convert the handle
        Error := GetLastError();
        writeln(format('OpenVxDHandle failed.  Error: %d', [Error]));
        CloseHandle(EventHandle);
        Result := 0;
        exit;
        end;
        
        // return the VxD-accessible handle
    Result := EventHandle;
    end;

    // WinRTCloseEvent - closes handle to an event
    //     Inputs:  hWinRT  - handle to event
    //                       (returned from WinRTCreateEvent())
    //     Outputs: returns - error if zero
    //                   (call GetLastError() to error code)
Function WinRTCloseEvent(hEvent : integer) : boolean;
begin
    Result := CloseHandle(hEvent);
    end;    { WinRTCloseEvent }

    // WinRTOpenDevice - get handle to driver
    //     Inputs: DeviceNumber  - device number 0 - n
    //                             (0 opens WRTdev0 device)
    //             Sharing       - TRUE opens device for sharing
    //                             FALSE opens device for exclusive use
    //     Outputs: returns - HANDLE to device or
    //              INVALID_HANDLE_VALUE if error.
Function WinRTOpenDevice(DeviceNumber : integer; Sharing : boolean) : integer;
const
    sh      : array[boolean] of integer = (0, FILE_SHARE_READ or FILE_SHARE_WRITE);
var
    DeviceName  : array[0..31] of char;
begin
    Result := CreateFile(strfmt(DeviceName, '\\.\WRTdev%d', [DeviceNumber]), 0,
                         sh[sharing], nil, OPEN_EXISTING, 0, 0);
    end;    { WinRTOpenDevice }

    // WinRTCloseDevice - closes handle to driver
    //     Inputs:  hWinRT  - handle to device
    //                       (returned from WinRTOpenDevice())
    //     Outputs: returns - error if zero
    //                       (call GetLastError() to error code)
Function WinRTCloseDevice(hWinRT : integer) : boolean;
begin
    Result := CloseHandle(hWinRT);
    end;    { WinRTCloseDevice }

    // WinRTGetFullConfiguration - gets driver configuration
    //     Inputs:  hWinRT  - handle to device
    //                       (returned from WinRTOpenDevice())
    //     Outputs: ConfigBuffer  - pointer to configuration buffer
    //                              of type WINRT_FULL_CONFIGURATION
    //              Length  - pointer to variable which contains
    //                        length of returned buffer (DWORD)
    //              returns - error if zero
    //                   (call GetLastError() to error code)
Function WinRTGetFullConfiguration(hWinRT : integer;
                                   var ConfigBuffer : tWINRT_FULL_CONFIGURATION;
                                   var Length : Integer) : boolean;
begin
    Result := DeviceIoControl(hWinRT,
                IOCTL_WINRT_GET_CONFIG,
                nil, 0,
                @ConfigBuffer,
                sizeof(tWINRT_FULL_CONFIGURATION),
					 DWORD(Length),
                nil);
    end;    { WinRTGetFullConfiguration }

    // WinRTProcessIoBuffer - process an input/output buffer
    //     Inputs:  hWinRT  - handle to device
    //                       (returned from WinRTOpenDevice())
    //              Buffer - pointer to input/output buffer
    //                      (array of WINRT_CONTROL_ITEM)
    //              Size  - size off input/output buffer
    //     Outputs: Length  - pointer to variable which contains
    //                        length of returned buffer (DWORD)
    //              returns - error if zero
    //                   (call GetLastError() to error code)
    //      notes: Buffer is both an input & output
Function WinRTProcessIoBuffer(hWinRT : integer;
                              var Buffer; Size : integer;
                              var Length : integer) : boolean;
begin
    Result := DeviceIoControl(hWinRT,
                IOCTL_WINRT_PROCESS_BUFFER,
                @Buffer, Size,
					 @Buffer, Size,
					 DWORD(Length),
					 nil);
    end;    { WinRTProcessIoBuffer }

    // WinRTProcessIoBufferDirect - process an input/output buffer 
    //                              using method direct i/o
    //     Inputs:  hWinrt  - handle to device
    //                       (returned from WinRTOpenDevice())
    //              Buffer - pointer to input/output buffer
    //                      (array of WINRT_CONTROL_ITEM)
    //              Size  - size off input/output buffer
    //     Outputs: Length  - pointer to variable which contains
    //                        length of returned buffer (DWORD)
    //              returns - error if zero
    //                   (call GetLastError() to error code)
    //      notes: Buffer is both an input & output
Function WinRTProcessIoBufferDirect(hWinrt : integer;
                                    var Buffer; Size : integer;
                                    var Length : integer) : boolean;
begin
    Result := DeviceIoControl(hWinRT,
                IOCTL_WINRT_PROCESS_BUFFER_DIRECT,
                nil, 0,
					 @Buffer, Size,
					 DWORD(Length),
					 nil);
    end;    { WinRTProcessIoBufferDirect }

    // WinRTProcessDmaBuffer - process an input/output buffer
    //  containing a DMAStart
    //     Inputs:  hWinrt  - handle to device
    //                       (returned from WinRTOpenDevice())
    //              Buffer - pointer to input/output buffer
    //                      (array of WINRT_CONTROL_ITEM)
    //              Size  - size off input/output buffer
    //     Outputs: Length  - pointer to variable which contains
    //                        length of returned buffer (DWORD)
    //              returns - error if zero
    //                   (call GetLastError() to error code)
    //      notes: Buffer is both an input & output
Function WinRTProcessDmaBuffer(hWinrt : integer;
                               var Buffer; Size : integer;
                               var Length : integer) : boolean;
begin
    Result := DeviceIoControl(hWinrt,
                IOCTL_WINRT_PROCESS_DMA_BUFFER,
                @Buffer, Size,
					 @Buffer, Size,
					 DWORD(Length),
					 nil);
	 end;    { WinRTProcessDmaBuffer }

    // WinRTProcessDmaBufferDirect - process an input/output buffer
    //  containing a DMAStart using method direct i/o
    //     Inputs:  hWinrt  - handle to device
    //                       (returned from WinRTOpenDevice())
    //              Buffer - pointer to input/output buffer
    //                      (array of WINRT_CONTROL_ITEM)
    //              Size  - size off input/output buffer
    //     Outputs: Length  - pointer to variable which contains
    //                        length of returned buffer (DWORD)
    //              returns - error if zero
    //                   (call GetLastError() to error code)
    //      notes: Buffer is both an input & output
Function WinRTProcessDmaBufferDirect(hWinrt : integer;
                                     var Buffer; Size : integer;
                                     var Length : integer) : boolean;
begin
    Result := DeviceIoControl(hWinRT,
                IOCTL_WINRT_PROCESS_DMA_BUFFER_DIRECT,
                nil, 0,
                @Buffer, Size,
					 DWORD(Length),
					 nil);
	 end;    { WinRTProcessDmaBufferDirect }

    // WinRTWaitInterrupt - set up a repeating interrupt on 
    //  device and wait for completion
    //     Inputs:  hWinrt  - handle to device
    //                  (returned from WinRTOpenDevice())
    //              Buffer - pointer to input/output buffer
    //                  (array of WINRT_CONTROL_ITEM)
    //              Size  - size off input/output buffer
    //     Outputs: Length  - pointer to variable which contains
    //                  length of returned buffer (DWORD)
    //              returns - error if zero
    //                   (call GetLastError() to error code)
    //      notes: Buffer is both an input & output.
Function WinRTWaitInterrupt(hWinrt : integer;
                            var Buffer; Size : integer;
                            var Length : integer) : boolean;
begin
    Result := DeviceIoControl(hWinRT,
                IOCTL_WINRT_WAIT_INTERRUPT,
					 @Buffer, Size,
					 @Buffer, Size,
					 DWORD(Length),
					 nil);
	 end;    { WinRTWaitInterrupt }

    // WinRTSetInterrupt - set up a continuous repeating interrupt
    //                   on device
    //     Inputs:  hWinrt  - handle to device
    //                       (returned from WinRTOpenDevice())
    //              Buffer - pointer to input/output buffer
    //                      (array of WINRT_CONTROL_ITEM)
    //              Size  - size off input/output buffer
    //     Outputs: Length  - pointer to variable which contains
    //                        length of returned buffer (DWORD)
    //              returns - error if zero
    //                   (call GetLastError() to error code)
    //      notes: Buffer is both an input & output.
Function WinRTSetInterrupt(hWinrt : integer;
                           var Buffer; Size : integer;
                           var Length : integer) : boolean;
begin
    Result := DeviceIoControl(hWinRT,
                IOCTL_WINRT_SET_INTERRUPT,
                nil, 0,
                @Buffer, Size,
					 DWORD(Length),
					 nil);
    end;    { WinRTSetInterrupt }

    // WinRTSetupDmaBuffer - set up the DMA common buffer
    //     Inputs:  hWinrt  - handle to device
    //                       (returned from WinRTOpenDevice())
    //     Outputs: Buffer  - pointer to DMA information buffer
    //                        of type WINRT_DMA_BUFFER_INFORMATION
    //              Length  - pointer to variable which contains
    //                        length of returned buffer (DWORD)
    //              returns - error if zero
    //                   (call GetLastError() to error code)
Function WinRTSetupDmaBuffer(hWinrt : integer;
                             var Buffer : tWINRT_DMA_BUFFER_INFORMATION;
                             var Length : integer) : boolean;
begin
    Result := DeviceIoControl(hWinRT,
                IOCTL_WINRT_SETUP_DMA_BUFFER,
                nil, 0,
                @Buffer,
                sizeof(tWINRT_DMA_BUFFER_INFORMATION),
					 DWORD(Length),
					 nil);
    end;    { WinRTSetupDmaBuffer }

    // WinRTFreeDmaBuffer - unmap the common buffer and
    //     return the DMA channel and map registers to
    //     the system
    //     Inputs:  hWinrt  - handle to device
    //                       (returned from WinRTOpenDevice())
    //              Buffer  - pointer to DMA information buffer
    //                        of type WINRT_DMA_BUFFER_INFORMATION
    //                        This buffer must be the same buffer
    //                        that was passed to WinRTSetupDmaBuffer
    //     Outputs: Length  - pointer to variable which contains
    //                        length of returned buffer (DWORD)
    //              returns - error if zero
    //                   (call GetLastError() to error code)
Function WinRTFreeDmaBuffer(hWinrt : integer;
                            var Buffer : tWINRT_DMA_BUFFER_INFORMATION;
                            var Length : integer) : boolean;
begin
    Result := DeviceIoControl(hWinRT,
                IOCTL_WINRT_FREE_DMA_BUFFER,
                @Buffer,
                sizeof(tWINRT_DMA_BUFFER_INFORMATION),
                nil, 0,
					 DWORD(Length),
					 nil);
    end;    { WinRTFreeDmaBuffer }

    // WinRTMapMemory - map physical memory into user space
    //     Inputs:  hWinRT  - handle to device
    //                       (returned from WinRTOpenDevice())
    //              Buffer - pointer to input buffer
	 //                      (of type WINRT_MEMORY_MAP)
	 //     Outputs: MemPtr - pointer to variable (of PVOID) which will
	 //                       receive mapped address
	 //              Length  - pointer to variable which contains
	 //                        length of returned buffer (DWORD)
	 //              returns - error if zero
	 //                   (call GetLastError() to error code)
Function WinRTMapMemory(hWinrt : integer; var Buffer;
								var MemPtr : pointer;
								var Length : integer) : boolean;
begin
	 Result := DeviceIoControl(hWinRT,
					 IOCTL_WINRT_MAP_MEMORY,
					 @Buffer,
					 sizeof(tWINRT_MEMORY_MAP),
					 @MemPtr,
					 sizeof(Pointer),
					 DWORD(Length),
					 nil);
	 end;    { WinRTMapMemory }

	 // WinRTUnMapMemory - unmap physical memory from user space
	 //     Inputs:  hWinrt  - handle to device
	 //                       (returned from WinRTOpenDevice())
	 //              MemPtr - pointer to address returned from
	 //                       WinRTMapMemory
	 //                      (of type PVOID)
	 //     Outputs: Length  - pointer to variable which contains
	 //                        length of returned buffer (DWORD)
	 //              returns - error if zero
	 //                   (call GetLastError() to error code)
Function WinRTUnMapMemory(hWinrt : integer;
								  var MemPtr : pointer;
								  var Length : integer) : boolean;
begin
	 Result := DeviceIoControl(hWinRT,
					 IOCTL_WINRT_UNMAP_MEMORY,
					 @MemPtr,
					 sizeof(Pointer),
					 nil, 0,
					 DWORD(Length),
					 nil);
	 end;    { WinRTUnMapMemory }

	 // WinRTAutoIncIo - process an Auto Incrementing input/output buffer
	 //     Inputs:  hWinrt  - handle to device
	 //                       (returned from WinRTOpenDevice())
	 //              Inbuff - pointer to input buffer,
	 //                       buffer sent to driver.
	 //                      (of type WINRT_AUTOINC_ITEM)
	 //              SizeIn  - size off pIn input buffer
	 //              Outbuff - pointer to output buffer,
	 //                        buffer received from driver.
	 //                       (of type PVOID)
	 //              SizeOut  - size off output buffer
	 //     Outputs: Length  - pointer to variable which contains
	 //                        length of returned buffer (DWORD)
	 //              returns - error if zero
	 //                   (call GetLastError() to error code)
Function WinRTAutoIncIo(hWinrt : integer;
								var Inbuff : tWINRT_AUTOINC_ITEM; SizeIn : integer;
								var Outbuff; SizeOut : integer; var Length : integer) : boolean;
begin
	 Result := DeviceIoControl(hWinrt,
					 IOCTL_WINRT_AUTOINC_IO,
					 @Inbuff, SizeIn,
					 @Outbuff, SizeOut,
					 DWORD(Length),
					 nil);
	 end;    { WinRTAutoIncIo }

end.
