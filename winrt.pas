//  WinRT.pas
//  Copyright 1998 BlueWater Systems
//
//  Implementation of the tWinRT class.  This class encapsulates some of the
//  functionality provided by the script commands to the WinRT preprocessor.
//
unit WinRT;
{$H+}               { must use huge strings }
interface
uses
    Windows,
    classes,
    sysutils,
    WinRTCtl,
	 WinRTDriver,
	 WinRTDimItem;

type
        // the inp and outp methods require as a parameter a set
        // of tRTFlags.
    tRTFlags    = set of (
        rtfword,        // the data is 16 bit
        rtflong,        // or the data is 32 bit.
                        // default is 8 bit when none of the above
        rtfabs,         // port or memory address is absolute. Default is relative
        rtfdirect);     // do a direct single call through DeviceIOControl
                        // takes slightly less code but it's slower than
                        // combining several operations in one DeviceIOControl call

        // type of buffer being passed to processlist
    tBufferType = (
        btProcessBuffer,
        btWaitInterrupt,
		  btSetInterrupt
	 );

    tWinRT  = class
    private
        fhandle     : cardinal;                 // handle returned by WinRTOpenDevice
    public
        constructor create(DeviceNumber : integer; sharing : boolean);
        destructor destroy; override;
        Procedure DeclEnd;
        Procedure inp(const aflags : tRTFlags; portaddr : integer; var addr);
        Procedure inm(const aflags : tRTFlags; memaddr : pointer; var addr);
        Procedure outp(const aflags : tRTFlags; portaddr, value : integer);
        Procedure outm(const aflags : tRTFlags; memaddr : pointer; value : integer);
        Procedure outpshadow(const aflags : tRTFlags; portaddr : integer; shadow : pointer);
        Procedure outmshadow(const aflags : tRTFlags; memaddr, shadow : pointer);
        Procedure Delay(wait : integer);
        Procedure Stall(wait : integer);
        Procedure SetEvent(handle : integer);
        Procedure DMAStart(TransferToDevice : boolean; NumberOfBytes : integer);
        Procedure DMAFlush;
        Procedure Trace(BitMask : integer; Str : string);
        Procedure TraceValue(BitMask : integer; Str : string; Value : integer);
        Procedure TraceShadow(Bitmask : integer; Str : string; shadow : pointer);
        Procedure BlockInterruptRoutine;
        Procedure ReleaseInterruptRoutine;
        Procedure InterruptSetup;
        Procedure InterruptService;
        Procedure InterruptDeferredProcessing;
        Procedure RejectInterrupt;
        Procedure ScheduleDeferredProcessing;
        Procedure StopInterrupts;
        Function AddItem(command, aport, avalue : integer) : integer;
        Procedure clear;
        Procedure ProcessBuffer;
        Procedure WaitInterrupt;
        Procedure SetInterrupt;
        Function SingleCall(command, aport, avalue : integer) : integer;
        Function Dim(wordsize, wordcount : integer; var data) : pointer;
        Function DimK(wordsize, value : integer) : pointer;
        Function DimStr(var S : string; size : integer) : pointer;
        Function GlobalDim(name:string;wordsize, wordcount : integer; var data) : pointer;
        Function ExternDim(name:string;wordsize, wordcount : integer; var data) : pointer;
        Procedure Math(operation : tWINRT_LOGIC_MATH; flags : integer; result, var1, var2 : pointer);
        Procedure ArrayMove(lvar : pointer; lvarindex : integer; rvar : pointer; rvarindex : integer);
        Procedure ArraySrcInd(lvar : pointer; lvarindex : integer; rvar, rvarindex : pointer);
        Procedure ArrayDstInd(lvar, lvarindex : pointer; rvar : pointer; rvarindex : integer);
        Procedure ArrayBothInd(lvar, lvarindex, rvar, rvarindex : pointer);
        Procedure _While(amath : tWINRT_LOGIC_MATH; mathflags : integer; var1, var2 : pointer);
        Procedure _Wend;
        Procedure _If(amath : tWINRT_LOGIC_MATH; mathflags : integer; var1, var2 : pointer);
        Procedure _Else;
        Procedure _Endif;
        Procedure _Goto(const alabel : string);
        Procedure _Label(const alabel : string);
        Procedure assign(dst, src : pointer);
        Property handle : cardinal read fhandle;

    private
        DimList,                                    // list of dimmed variables
        fList           : tlist;                    // list of WinRT commands
        buff            : pWINRT_CONTROL_array;     // a pointer to the array passed to DeviceIOControl
        whilestack,                                 // a stack of pending _While's. _Wend closes.
        ifstack     : tstack;                       // a stack of pending _IF's. _Endif closes.
        fDeviceNo,                                  // WinRT device No. Used in error messages.
        lasterr,                                    // last error. Read just befor raising an exception
        buffsize,                                   // size of the buffer being passed to the driver
        undefgotos      : integer;                  // number of _Goto's with _labels not yet defined
        fLabelList  : tstringlist;                  // list of labels

        Function Flags2Ofs(const aflags : tRTFlags; var datasize : integer) : integer;
        Function Flags2Shf(const aflags : tRTFlags) : integer;

        Procedure Putdata;
        Procedure GetData;
        Procedure Push(value : integer; var stack : tStack);
        Function Pop(var stack : tStack) : integer;
        Function GetControlItems(index : integer) : pCONTROL_ITEM_ex;
        Procedure processlist(command : tBufferType);
        Procedure AddName(GlobalOrExtern: integer; const name: string);
        Property ControlItems[index : integer] : pCONTROL_ITEM_ex read GetControlItems;
        end;        { of tWinRT declaration }

        // ***********************************************************
        // eWinRTError  - exception class for tWinRT errors
    eWinRTError	= class(exception);


implementation

    // tWinRT.create - Open the Device and setup the object
    // Inputs:  DeviceNumber  - 0 - n (0 opens device WRTdev0)
    //          sharing  - TRUE opens device for sharing
    //                     FALSE opens device for exclusive use
    // Outputs: raises an exception if the device cannot be opened
constructor tWinRT.create(DeviceNumber : integer; sharing : boolean);
begin
    fhandle := cardinal(INVALID_HANDLE_VALUE);  { get it ready for a possible early exception }
    inherited create;
    fDeviceNo := DeviceNumber;
        // open the device
    fhandle := WinRTOpenDevice(DeviceNumber, sharing);
        // make sure we got a valid handle to the device
    if fhandle = INVALID_HANDLE_VALUE then begin
        lasterr := GetLastError;
        raise eWinRTError.createfmt('Can''t open device %d Error %d', [DeviceNumber, lasterr]);
        end;
        //initialize the lists
	 flist := tlist.create;
    DimList := tlist.create;
    fLabelList := tstringlist.create;
    with fLabelList do begin
        sorted := true;
        duplicates := dupAccept;
        end;
    end;    { create }

    // tWinRT.destroy - frees memory and closes the WinRT device
    //                  if there is an error it raises eWinRTError showing
    //                  the last error
destructor tWinRT.destroy;
begin
	 clear;
    flist.free;
    DimList.free;
    fLabelList.free;
    try
        if (fhandle <> INVALID_HANDLE_VALUE) and not CloseHandle(fhandle) then begin
				lasterr := GetLastError;
				raise eWinRTError.createfmt('Error when closing device %d Error %d', [fDeviceNo, Lasterr]);
				end;
	 finally
		  inherited destroy;
		  end
	 end;    { destroy }

	 // tWinRT.DeclEnd - called after all commands.  Sets up the buffer passed to the
	 //                  WinRT driver.
	 // Inputs:          none
	 // Outputs:         will raise exceptions if there are _While's without _Wend's
	 //                  or _If's or _Else's without _Endifs's
	 //                  or _Else's without matching _If's
	 //                  or _Goto's to an undefined label
Procedure tWinRT.DeclEnd;
var
	 ii,
	 len,
     extraitems:	integer;  // loop counter
	 p:	pointer;		// temporary place for string pointer
begin
	 if WhileStack.sp <> 0 then
		  raise eWinRTError.create('Open _While calls');
	 if IfStack.sp <> 0 then
		  raise eWinRTError.create('Open _If calls');
	 if undefgotos <> 0 then
		  raise eWinrtError.create('_Goto''s with undefined labels');
		  // the labellist is no longer needed. Recover some memory
	 fLabelList.clear;
	 with flist do begin
		    // allocate the buffer
        buffsize := count * sizeof(tWINRT_CONTROL_item);
		getmem(buff, buffsize);
		    // fill the buffer with the control items
        ii := 0;
		while ii < count do begin
            buff^[ii] := pWINRT_CONTROL_item(flist[ii])^;
			with buff^[ii] do begin
					// replace the Dim Global and extern string pointer with the actual values
                if (WINRT_COMMAND = WINRT_GLOBAL) or (WINRT_COMMAND = WINRT_EXTERN) then begin
				    	// copy the content of the string
                    len := length(string(value));
                    extraitems := port;
                    p := pointer(value);
                    system.move(p^, value, len + 1);
                    // decrement string refcount
                    string(p) := '';
                    port := len;
                    inc(ii, extraitems);
                    end;
				inc(ii);
				end;
            end;
		end;
	end;    { DeclEnd }

	 // tWinRT.processlist - does the actual processing for ProcessBuffer,
	 //                      WaitForInterrupt or SetInterrupt
	 // Inputs:  command - whether to use ProcessIoBuffer, WaitInterrupt,
	 //                    or SetInterrupt
	 // Outputs: none
Procedure tWinRT.processlist(command : tBufferType);
var
	 Length,         // length of data return from driver
	 ii  : integer;  // loop counter
begin
		  // exit if there are no commands to send
	 if flist.count = 0 then
		  exit;
	 with flist do begin
				// copy data from dimmed variables into the buffer
		  putdata;
				// send the buffer down and wait for an interrupt
		  if command = btWaitInterrupt then begin
				if not WinRTWaitInterrupt(fhandle, buff^, buffsize, Length) then begin
					 lasterr := GetLastError;
					 raise eWinRTError.createfmt('Error in WinRTWaitInterrupt Device %d Error %d', [fDeviceNo, LastErr])
					 end
				end
				// send the buffer down, set up the interrupt service routine
		  else if command = btSetInterrupt then begin
				if not WinRTSetInterrupt(fhandle, buff^, buffsize, Length) then begin
					 lasterr := GetLastError;
					 raise eWinRTError.createfmt('Error in WinRTSetInterrupt Device %d Error %d', [fDeviceNo, LastErr])
					 end
				end
				// send the buffer down.
		  else
				if not WinRTProcessIoBuffer(fhandle, buff^, buffsize, Length) then begin
					 lasterr := GetLastError;
					 raise eWinRTError.createfmt('Error in WinRTProcessBuffer Device %d Error %d', [fDeviceNo, LastErr]);
					 end;

				// move data from the buffer to the dimmed variables
		  for ii := 0 to count - 1 do with pCONTROL_ITEM_ex(flist[ii])^ do
					 // values in the $0..$7fff range belong to DIM statements
				if (dsize > 0) and ((value < integer(NOVALUE)) or (value >= $8000)) then
					 system.move(buff^[ii].value, pointer(value)^, dsize);
				// move data kept in WinRT variables to Pascal variables
		  getdata;
		  end;
	 end;    { processlist }

	 // tWinRT.clear - clear all items
	 //                You call this function if you want to reuse a tWinRT object.
	 //                The handle to the Device remains valid, as the device will remain open.
	 //                All memory allocations inside the object are disposed.
Procedure tWinRT.clear;
var
	 ii  : integer;  // loop counter
begin
	 if flist <> nil then
		  with flist do begin
				for ii := 0 to count - 1 do begin
						  // cancel the link to the heap
					 dispose(CONTROLITEMs[ii]);
					 end;
				clear
				end;
	 if DimList <> nil then
		  with DimList do begin
				for ii := 0 to count - 1 do
					 tDimItem(items[ii]).free;
				clear
				end;
	 if fLabelList <> nil then
		  fLabelList.clear;
	 WhileStack.sp := 0;
	 IfStack.sp := 0;
	 if buff <> nil then begin
		  freemem(buff, buffsize);
		  buff := nil
		  end
	 end;    { clear }

	 // tWinRT.inp - request a direct or buffered input from a port.
	 //              can be absolute or relative, and byte, word or long size
	 //              if the value addr is located under $8000 then it goes to
	 //              a shadow variable.
	 //
	 // Inputs
	 //  aFlags -        can be one or more of
	 //          rtfword     the data is 16 bit
	 //          rtflong     or the data is 32 bit.
	 //                      default is 8 bit when none of the above
    //          rtfabs      port address is absolute. Default is relative
    //          rtfdirect   do a single direct call through DeviceIOControl
    //              example
    //                  [rtfabs, rtfdirect]     use absolute addressing and
    //                                          call direct. Data size is 8 bit
    //                  []                      data size is 8 bit. Addressing is
    //                                          relative and add it to the list for
    //                                          future buffer processing.
    //                                          the square brackets are needed because it's a pascal set.
    //
    //      Portaddr -      port address, relative. Absolute if rtfdirect set
    //      Addr -          reference to the variable that will receive the reading.
    //                      if the location of addr is under $8000 it's treated as a shadow.
    //                      In this case you must pass the shadow variable as shadowname^.
Procedure tWinRT.inp(const aFlags : tRTFlags; Portaddr : integer; var Addr);

var
    Datasize,
	 Result,
    Command,
    Varpos	: integer;
begin
    Varpos := integer(@Addr);
    Command := INP_B + Flags2Ofs(aflags, datasize);
    if rtfdirect in aFlags then begin
        Result := SingleCall(Command, Portaddr, 0);
    if rtflong in aFlags then
            plong(@Addr)^ := result
        else if rtfword in aFlags then
            pword(@Addr)^ := Result
        else
            pbyte(@Addr)^ := Result;
		  exit;
        end;

    if (Varpos >= $10000) or (Varpos < 0) then begin	// goes to normal memory
        Result := AddItem(Command, Portaddr, integer(@Addr));
        ControlItems[Result]^.dsize := Datasize;
        end
    else begin
        AddItem(Command, Portaddr, 0);
        Math(MOVE_TO, 0, @Addr, @Addr, pointer(MATH_MOVE_FROM_VALUE));
        end
    end;    { inp }

    // tWinRT.inm - request a direct or buffered input from physical memory.
    //              can be absolute or relative, and byte, word or long size
    //              if the value addr is located under $8000 then it goes to
    //              a shadow variable.
    //
    // Inputs:
	 //      aFlags -    can be one or more of
    //          rtfword     the data is 16 bit
    //          rtflong     or the data is 32 bit.
    //                      default is 8 bit when none of the above
    //          rtfabs      physical memory address is absolute. Default is relative
    //          rtfdirect   do a single direct call through DeviceIOControl
    //              example
    //                  [rtfabs, rtfdirect]     use absolute addressing and
    //                                          call direct. Data size is 8 bit
    //                  []                      data size is 8 bit. Addressing is
    //                                          relative and add it to the list for
    //                                          future buffer processing.
    //                          the square brackets are needed because it's a pascal set.
    //
    //      Memaddr -       physical memory address, relative. Absolute if rtfdirect set
    //      Addr -          reference to the variable that will receive the reading.
    //                      if the location of addr is under $8000 it's treated as a shadow.
    //                      In this case you must pass the shadow variable as shadowname^.
Procedure tWinRT.inm(const aFlags : tRTFlags; Memaddr : pointer; var Addr);
var
    Datasize,
    Result,
    Command,
    Varpos  : integer;
begin
    Command := INM_B + Flags2Ofs(aFlags, Datasize);
    if rtfdirect in aFlags then begin
        Result := SingleCall(Command, integer(Memaddr), 0);
        if rtflong in aFlags then
            plong(@Addr)^ := Result
        else if rtfword in aFlags then
            pword(@Addr)^ := Result
        else
				pbyte(@Addr)^ := Result;
        exit;
        end;

    Varpos := integer(@Addr);
    if (Varpos >= $10000) or (Varpos < integer(NOVALUE)) then begin	// goes to normal memory
        Result := AddItem(Command, integer(Memaddr), integer(@Addr));
        ControlItems[Result]^.dsize := Datasize;
        end
    else begin
        AddItem(Command, integer(Memaddr), 0);
        Math(MOVE_TO, 0, @Addr, @Addr, pointer(MATH_MOVE_FROM_VALUE));
        end
    end;    { inm }

    // tWinRT.outp - request a direct or buffered output to a port.
    //               can be absolute or relative, and byte, word or long size
    //               use outpshadow instead if you need to pass the value of
    //               a shadow variable
    //
    // Inputs
    //      aFlags -    can be one or more of
    //          rtfword     the data is 16 bit
    //          rtflong     or the data is 32 bit.
    //                      default is 8 bit when none of the above
    //          rtfabs      port address is absolute. Default is relative
    //          rtfdirect   do a single direct call through DeviceIOControl
    //              example
    //                  [rtfabs, rtfdirect]     use absolute addressing and
    //                                          call direct. Data size is 8 bit
    //                  []                      data size is 8 bit. Addressing is
    //                                          relative and add it to the list for
    //                                          future buffer processing.
	 //                          the square brackets are needed because it's a pascal set.
    //
    //      Portaddr -      port address, relative. Absolute if rtfdirect set
    //      Value -         value to be sent to the port
Procedure tWinRT.outp(const aFlags : tRTFlags; Portaddr, Value : integer);
var
    Datasize,
    Command	: integer;
begin
    Command := OUTP_B + Flags2Ofs(aFlags, Datasize);
    if rtfdirect in aFlags then
        SingleCall(Command, Portaddr, Value)
    else
        Additem(Command, Portaddr, Value)
    end;    { outp }

    // tWinRT.outm - request a direct or buffered output to physical memory.
    //               can be absolute or relative, and byte, word or long size
    //               use outmshadow instead if you need to pass the value of
    //               a shadow variable
    //
    // Inputs
    //      aFlags -    can be one or more of
    //          rtfword     the data is 16 bit
    //          rtflong     or the data is 32 bit.
    //                      default is 8 bit when none of the above
    //          rtfabs      physical memory address is absolute. Default is relative
    //          rtfdirect   do a single direct call through DeviceIOControl
    //              example
    //                  [rtfabs, rtfdirect]     use absolute addressing and
    //                                          call direct. Data size is 8 bit
    //                  []                      data size is 8 bit. Addressing is
    //                                          relative and add it to the list for
	 //                                          future buffer processing.
    //                      the square brackets are needed because it's a pascal set.
    //
    //      Memaddr -       physical memory address, relative. Absolute if rtfdirect set
    //      Value -         value to be sent to physical memory
Procedure tWinRT.outm(const aFlags : tRTFlags; Memaddr : pointer; Value : integer);
var
    Datasize,
    Command : integer;
begin
    Command := OUTM_B + Flags2Ofs(aFlags, Datasize);
    if rtfdirect in aflags then
        SingleCall(Command, integer(Memaddr), Value)
    else
        AddItem(Command, integer(Memaddr), Value)
    end;    { outm }

    // tWinRT.outpshadow - request a direct or buffered output to a port
    //                     from a shadow variable.
    //                     can be absolute or relative, and byte, word or long size
    //
    // Inputs:
    //      aFlags -    can be one or more of
    //          rtfword     the data is 16 bit
    //          rtflong     or the data is 32 bit.
    //                      default is 8 bit when none of the above
    //          rtfabs      port address is absolute. Default is relative
    //          rtfdirect   no valid
    //              example
    //                  [rtfabs, rtfdirect]     use absolute addressing and
    //                                          call direct. Data size is 8 bit
    //                  []                      data size is 8 bit. Addressing is
    //                                          relative and add it to the list for
	 //                                          future buffer processing.
    //                        the square brackets are needed because it's a pascal set.
    //
    //      Portaddr -      port address, relative. Absolute if rtfdirect set
    //      Shadow -        shadow variable holding the value to be sent to the port
Procedure tWinRT.outpshadow(const aFlags : tRTFlags; Portaddr : integer; Shadow : pointer);
var
    Datasize    : integer;
begin
    Math(MOVE_TO, 0, Shadow, Shadow, pointer(MATH_MOVE_TO_VALUE));
    AddItem(OUTP_B + Flags2Ofs(aFlags, Datasize), Portaddr, 0)
    end;    { outp }

    // tWinRT.outmshadow - request a direct or buffered output to physical
    //                     memory from a shadow variable.
    //                     can be absolute or relative, and byte, word or long size
    //
    // Inputs
    //      aFlags - can be one or more of
    //          rtfword     the data is 16 bit
    //          rtflong     or the data is 32 bit.
    //                      default is 8 bit when none of the above
    //          rtfabs      port address is absolute. Default is relative
    //          rtfdirect   no valid
    //              example
    //                  [rtfabs, rtfdirect]     use absolute addressing and
    //                                          call direct. Data size is 8 bit
    //                  []                      data size is 8 bit. Addressing is
    //                                          relative and add it to the list for
    //                                          future buffer processing.
    //                          the square brackets are needed because it's a pascal set.
    //
    //      Memaddr -       physical memory address, relative. Absolute if rtfdirect set
	 //      Shadow -        shadow variable holding the value to be sent to the port
Procedure tWinRT.outmshadow(const aFlags : tRTFlags; Memaddr, Shadow : pointer);
var
    Datasize    : integer;
begin
    Math(MOVE_TO, 0, Shadow, Shadow, pointer(MATH_MOVE_TO_VALUE));
    additem(OUTM_B + Flags2Ofs(aFlags, Datasize), integer(Memaddr), 0)
    end;    { outm }

    // tWinRT.Delay - allows timing delays between I/O commands. Delay is
    //      implemented as a thread delay, and is used for relatively long
    //      delays.  Its accuracy is machine dependent and typically 10 or 15
    //      milliseconds on an Intel machine running Windows NT.  This function
    //      cannot by used during interrupt processing
    // Inputs:  wait - wait time in milliseconds
    // Outputs: none
Procedure tWinRT.Delay(wait : integer);
begin
    AddItem(_DELAY, 0, wait);
    end; { Delay }

    // tWinRT.Stall - allows brief timing delays between I/O commands. Stall is
    //      implemented as a spin loop type delay and is used for short delays.
    //      Its accuracy is dependent on driver set up time.  This function does
    //      not allow other threads to operate during its delay and should
    //      therefore be used as sparingly as possible.  Setting stall times
    //      greater than 50 microseconds can have very detrimental effects
    //      to the system.
    // Inputs:  wait - wait time in microseconds
    // Outputs: none
Procedure tWinRT.Stall(wait : integer);
begin
    AddItem(_STALL, 0, wait);
	 end;

    // tWinRT.SetEvent - sets the state of a Win32 event to signaled.
    // Inputs:  handle - handle to driver accessible event returned
    //                   from WinRTCreateEvent
    // Outputs: none
Procedure tWinRT.SetEvent(handle : integer);
begin
    AddItem(SET_EVENT, handle, 0);
    end;

    // tWinRT.DMAStart - Starts a DMA operation on a slave DMA device.  This
    //      command is not necessary for bus master DMA transfers.  For slave
    //      DMA devices, this command must be the last item in the list.
    // Inputs:  TransferToDevice - true to transfer data from the host to the device
    //          NumberOfBytes - number of bytes to transfer with this request.
    //                          This value MUST be less than or equal to the
    //                          size of the common buffer.
    // Outputs: none
Procedure tWinRT.DMAStart(TransferToDevice : boolean; NumberOfBytes : integer);
begin
    AddItem(DMA_START, integer(TransferToDevice), NumberOfBytes);
    end;

    // tWinRT.DMAFlush - Flushes the DMA buffers
    // Inputs:  none
    // Outputs: none
Procedure tWinRT.DMAFlush;
begin
    AddItem(DMA_FLUSH, 0, 0);
    end;

	 // tWinRT.Trace - used to places messages into the driver's internal debug
	 //      buffer, which can then be retrieved using the Debug Trace option
	 //      of the WinRT Console.
	 // Inputs:  BitMask - trace selection bitmask (16 bits).  This value is
	 //                    logically ANDed with the internally stored bitmask,
	 //                    and if the result is non-zero, the trace message is placed
	 //                    into the debug buffer.  Otherwise, the message is discarded.
	 //          Str - the string to trace
	 // Outputs: none
Procedure tWinRT.Trace(BitMask : integer; Str : string);
var
	 Param1,
	 Param2,
	 Param3,
	 ii    : integer;
	 Count : Double;
	 Token : array[0..3] of char;
begin
		  // add the trace command to the command list
	 AddItem(WINRT_TRACE, 0, BitMask shl 16 or Length(Str));
	 Count := Length(Str);
	 ii := 0;
		  // add the string to trace to the command list
	 while ii < Count do begin
		  StrLCopy(@Token[0], @Str[1+ii], 4);
		  Param1 := integer(Token);
		  ii := ii + 4;
		  if ii >= Count then begin
				AddItem(Param1, 0, 0);
            exit;
            end;
        StrLCopy(@Token[0], @Str[1+ii], 4);
        Param2 := integer(Token);
        ii := ii + 4;
        if ii >= Count then begin
            AddItem(Param1, Param2, 0);
            exit;
            end;
        StrLCopy(@Token[0], @Str[1+ii], 4);
        Param3 := integer(Token);
        ii := ii + 4;
        AddItem(Param1, Param2, Param3);
        end;
    end;

    // tWinRT.TraceValue - used to places messages into the driver's internal debug
    //      buffer, which can then be retrieved using the Debug Trace option
	 //      of the WinRT Console.
	 // Inputs:  BitMask - trace selection bitmask (16 bits).  This value is
	 //                    logically ANDed with the internally stored bitmask,
	 //                    and if the result is non-zero, the trace message is placed
	 //                    into the debug buffer.  Otherwise, the message is discarded.
	 //          Str - the string to trace
	 //          Value - number to be traced
	 // Outputs: none
Procedure tWinRT.TraceValue(BitMask : integer; Str : string; Value : integer);
var
	 Param1,
	 Param2,
	 Param3,
	 ii    : integer;
	 Count : Double;
	 Token : array[0..3] of char;
	 temp_const : pointer;
begin
		  // add the value to the command list
	 temp_const := DimK(4, Value);
	 ii := integer(MOVE_TO);
	 AddItem(WinRTctl.MATH, ii shl 16 or integer(temp_const), integer(temp_const) shl 16 or DIMENSION_CONSTANT);
		  // add the trace command to the command list
	 AddItem(WINRT_TRACE, 0, BitMask shl 16 or Length(Str));
	 Count := Length(Str);
	 ii := 0;
		  // add the string to the command list
	 while ii < Count do begin
		  StrLCopy(@Token[0], @Str[1+ii], 4);
		  Param1 := integer(Token);
		  ii := ii + 4;
		  if ii >= Count then begin
				AddItem(Param1, 0, 0);
				exit;
				end;
		  StrLCopy(@Token[0], @Str[1+ii], 4);
		  Param2 := integer(Token);
		  ii := ii + 4;
		  if ii >= Count then begin
				AddItem(Param1, Param2, 0);
				exit;
				end;
		  StrLCopy(@Token[0], @Str[1+ii], 4);
		  Param3 := integer(Token);
		  ii := ii + 4;
		  AddItem(Param1, Param2, Param3);
		  end;
	 end;

	 // tWinRT.TraceShadow - used to places messages into the driver's internal debug
	 //      buffer, which can then be retrieved using the Debug Trace option
	 //      of the WinRT Console.
	 // Inputs:  BitMask - trace selection bitmask (16 bits).  This value is
	 //                    logically ANDed with the internally stored bitmask,
	 //                    and if the result is non-zero, the trace message is placed
	 //                    into the debug buffer.  Otherwise, the message is discarded.
	 //          Str - the string to trace
	 //          Shadow - shadow variable to be traced.
	 // Outputs: none
Procedure tWinRT.TraceShadow(Bitmask : integer; Str : string; Shadow : pointer);
var
	 Param1,
	 Param2,
	 Param3,
	 ii    : integer;
	 Count : Double;
	 Token : array[0..3] of char;
begin
		  // add the value to trace to the command list
	 ii := integer(MOVE_TO);
	 AddItem(WinRTctl.MATH, ii shl 16 or integer(Shadow), integer(Shadow) shl 16 or DIMENSION_CONSTANT);
		  // add the trace command to the command list
	 AddItem(WINRT_TRACE, integer(Shadow), BitMask shl 16 or Length(Str));
	 Count := Length(Str);
	 ii := 0;
		  // add the string to the command list
	 while ii < Count do begin
        StrLCopy(@Token[0], @Str[1+ii], 4);
        Param1 := integer(Token);
        ii := ii + 4;
        if ii >= Count then begin
            AddItem(Param1, 0, 0);
            exit;
            end;
        StrLCopy(@Token[0], @Str[1+ii], 4);
        Param2 := integer(Token);
        ii := ii + 4;
        if ii >= Count then begin
            AddItem(Param1, Param2, 0);
            exit;
            end;
        StrLCopy(@Token[0], @Str[1+ii], 4);
        Param3 := integer(Token);
        ii := ii + 4;
        AddItem(Param1, Param2, Param3);
        end;
    end;

    // tWinRT.BlockInterruptRoutine - Used to prevent the interrupt service routine
    //      from interrupting a block of WinRT code.  Any code in a block and release
    //      section will not be interrupt by the interrupt service rotine.  BlockInterruptRoutine
    //      is not the same as  CLI operation, as some other interrupts in the system
    //      may still occur.  Some (but not necessarily all) of the systm's interrupts
    //      are blocked during a BlockInterruptRoutine block, so this command should be
    //      used sparingly or it will have a detrimental impact on system performance.
    //      This command is not valid in interrupt service routine blocks, but is valid
    //      in deferred processing blocks.
Procedure tWinRT.BlockInterruptRoutine;
begin
	 AddItem(WINRT_BLOCK_ISR, 0, 0);
    end;

    // tWinRT.ReleaseInterruptRoutine - Used following a BlockInterruptRoutine command
    //      to allow the interrupt service routine to execute.  ANy code in a block
    //      and release section will not be interrupted by the interrupt service routine.
    //      ReleaseInterruptRoutine is not the same as a STI operation.  This command is
    //      not valid in interrupt service blocks, but is valid in deferred processing blocks.
Procedure tWinRT.ReleaseInterruptRoutine;
begin
    AddItem(WINRT_RELEASE_ISR, 0, 0);
    end;

    // tWinRT.Interruptsetup - Used to process commands that will enable the
    //      hardware device to interrupt.  The driver first established the
    //      interrupt service routine, then executes this block of code.
    //      Commands in the buffer between this call and the InterruptService call
    //      will be executed only once when the call to the driver is made.
    //
    //      Must be located in a buffer with InterruptService and
    //      InterruptDeferredProcessing.  Must come before InterruptService and
    //      InterruptDeferredProcessing.
    // Inputs:  none
    // Outputs: none
Procedure tWinRT.InterruptSetup;
begin
    AddItem(ISR_SETUP, 0, 0);
    end;

    // tWinRT.InterruptService - Used to process commands at interrupt time.
    //      The driver first establishes this code as the interrupt service routine.
    //      Then it excutes the InterruptSetup block of code.  Commands within
    //      the interrupt service block will be executed each time an interrupt
	 //      occurs until a StopInterrupts command is encountered.
    //
    //      Must be located in a buffer with InterruptSetup and InterruptDeferredProcessing.
    //      Must be located between InterruptSetup and InterruptDeferredProcessing.
    //      Delay, DMAStart and SetEvent are not allowed in the InterruptService block.
    // Inputs:  none
    // Outputs: none
Procedure tWinRT.InterruptService;
begin
    AddItem(BEGIN_ISR, 0, 0);
    end;

    // tWinRT.InterruptDeferredProcessing - Used to process commands after an interrupt
    //      occurs.  The code in this block is executed after an interrupt occurs,
    //      in response to one or more ScheduleDeferredProcessing commands.
    // Inputs:  none
    // Outputs: none
Procedure tWinRT.InterruptDeferredProcessing;
begin
    AddItem(BEGIN_DPC, 0, 0);
    end;

    // tWinRT.RejectInterrupt - Used to indicate to the OS that the interrupt
    //      that occurred did not belong to the device and exit from the interrupt
    //      service routine.  This command is necessary when using WinRT with a
    //      PCI device that has interrupts.
    // Inputs:  none
    // Outputs: none
Procedure tWinRT.RejectInterrupt;
begin
    AddItem(REJECT_INTERRUPT, 0, 0);
    end;

	 // tWinRT.ScheduleDeferredProcessing - Indicates that the InterruptDeferredProcessing
    //      block should be run when the interrupt service routine exits.
    //      ScheduleDeferredProcessing must be called from the InterruptService
    //      block and may be called once or more in the block.  Multiple
    //      InterruptService blocks may be executed before a single
    //      InterruptDeferredProcessing finishes executing.
    // Input:  none
    // Output: none
Procedure tWinRT.ScheduleDeferredProcessing;
begin
    AddItem(SCHEDULE_DPC, 0, 0);
    end;

    // tWinRT.StopInterrupts - Indicates that the InterruptService should no longer
    //      be called when an interrupt occurs.  The application must program
    //      the device to disable the device from generating interruptsbefore the
    //      application calls this command.
Procedure tWinRT.StopInterrupts;
begin
    AddItem(STOP_INTERRUPT, 0, 0);
    end;                

    // tWinRT.AddItem - Add a control item to the list for buffered processing.
    //                  This low level method allows you to create entries in the
    //                  list that are not otherwise supported.
    //                  There is seldom need to call this method, as other higher
    //                  level methods are generally more suitable.
    // Inputs
    //      Command     The value that will go to WINRT_COMMAND
    //      aPort       The value that will go to port
    //      aValue      The value that will go to value in the tWINRT_CONTROL_ITEM
    //                      record
    //  Outputs         return the position of the item in the list
Function tWinRT.AddItem(Command, aPort, aValue : integer) : integer;
var
    iTemp       : pCONTROL_ITEM_ex;
begin
	 new(iTemp);
    with iTemp^ do begin
        WINRT_COMMAND := command;
		  port := aPort;
		  value := aValue;
		  dsize := 0;             // used only to store data to pascal memory
		  end;
	 Result := flist.add(iTemp);
	 end;    { AddItem }

    // tWinRT.ProcessBuffer - Using the list already prepared, do the actual
    //              processing.  After a list has been prepared and completed with a call
    //              to DeclEnd, ProcessBuffer can be called one or more times to
    //              achieve the results programmed into the list.
    //              ProcessBuffer does its work by calling processlist,
    //              which then calls DeviceIOControl to communicate with the driver.
    //
    // Inputs:  none
    // Outputs: none
Procedure tWinRT.ProcessBuffer;
begin
    ProcessList(btProcessBuffer)
    end;    { ProcessBuffer }

    // tWinRT.WaitInterrupt - Using the list already prepared, do the actual
    //      processing for a WaitInterrupt.
    //      After a list has been prepared and completed with a call to
    //      DeclEnd, WaitInterrupt can be called one or more times to
    //      achieve the results programmed into the list
    //      WaitInterrupt does its work by calling processlist
    //      which then calls DeviceIOControl to communicate with the driver.
    //
    //      The list previously supplied must have an InterruptSetup,
    //      InterruptService, and InterruptDeferredProcessing.
    //
    // Inputs   none
    // Outputs  none
Procedure tWinRT.WaitInterrupt;
begin
    ProcessList(btWaitInterrupt)
    end;    { WaitInterrupt }

    // tWinRT.SetInterrupt - Using the list already prepared, do the actual
    //      processing for a SetInterrupt.
    //      After a list has been prepared and completed with a call to
    //      DeclEnd, SetInterrupt can be called to setup an ISR.
    //
    //      The list previously supplied must have an InterruptSetup,
    //      InterruptService, and InterruptDeferredProcessing.
    //
    // Inputs   none
    // Outputs  none
Procedure tWinRT.SetInterrupt;
begin
    ProcessList(btSetInterrupt)
    end;    { SetInterrupt }

    // tWinRT.SingleCall - Perform an unbuffered call to the WinRT driver,
    //                     and Return value. Command is not checked.
    // Inputs
    //      command The value that will go to WINRT_COMMAND
    //      aport   The value that will go to port
    //      avalue  The value that will go to value in the tWINRT_CONTROL_ITEM
    //                  record
    //  Outputs     returns whatever was stored in tWINRT_CONTROL_ITEM.value
Function tWinRT.SingleCall(Command, aPort, aValue : integer) : integer;
var
    Item    : tWINRT_CONTROL_ITEM;
    Length  : integer;
begin
    with item do begin
        WINRT_COMMAND := Command;
        port := aPort;
        value := aValue;
        end;
    if not WinRTProcessIoBuffer(fhandle, pWINRT_CONTROL_array(@Item)^, sizeof(Item), Length) then begin
        LastErr := GetLastError;
        raise eWinRTError.createfmt('Error in WinRT SingleCall Device %d Error %d', [fDeviceNo, LastErr]);
        end;
    Result := Item.value;   { return value to caller }
    end;    { SingleCall }

	 // tWinRT.Dim - dimensions a shadow variable or array. Returns a pseudo pointer
	 // Inputs:
	 //  wordsize:   1 for byte or char, 2 for word, 4 for integer/longint
	 //      wordcount:  1 if single item, or the range if an array
	 //      data:       a reference (not a pointer) to the Pascal variable shadows
	 // Outputs:     returns a pseudo pointer to the shadow variable created. This is
	 //              not a valid pascal pointer and should not be used as such
Function tWinRT.Dim(wordsize, wordcount : integer; var data) : pointer;
var
	 i,
	 flags,
	 extrabytes,
	 extraitems  : integer;
	 Dimitem     : tDimItem;
begin
	 extrabytes := wordsize * wordcount - sizeof(longint);
	 if extrabytes > 0 then
		  extraitems := (extrabytes + sizeof(tWINRT_CONTROL_ITEM) - 1) div sizeof(tWINRT_CONTROL_ITEM)
	 else
		  extraitems := 0;
	 if wordcount < 1 then
		  wordcount := 1;
	 if wordcount = 1 then
		  flags := 0
	 else
		  flags := DIMENSION_ARRAY;
	 i := additem(WinRTCtl.DIM, (flags + wordsize) shl 16 + wordcount, 0);
	 result := pointer(i);
	 for i := 1 to extraitems do
		  additem(NOP, 0, 0);
		  // create an entry in the Dim list
	 DimItem := tDimItem.create(result, data, WordSIze * WordCount);
	 DimList.add(DimItem);
	 end;    { Dim }

	 //  tWinRT.DimStr - Declare a shadow variable to a huge string
	 //                  This function is needed due to the special
	 //                  way huge strings are processed in Delphi 2
	 // Inputs
	 //      S:      The pascal huge string being shadowed
	 //      size:   The maximum allowed size for S. Should include space
	 //              for an extra eos character which is #0, like an ASCIZ string
	 //              Sorry, no dynamic allocation possible here.
	 //      name:   the name of the pascal variable shadowed.
	 //              Used in debug mode to list the shadow variable in the file Debug.fil
	 //      bConst: Is the string a constant, rather than a variable.
	 // Outputs:     returns a pseudo pointer to the shadow variable created. This is
	 //              not a valid pascal pointer and should not be used as such
Function tWinRT.DimStr(var S : string; size : integer) : pointer;
var
	 index,
	 extrabytes,
	 extraitems  : integer;
	 DimStritem      : tDimStrItem;
begin
	 extrabytes := size - sizeof(longint);
	 if extrabytes > 0 then
		  extraitems := (extrabytes + sizeof(tWINRT_CONTROL_ITEM) - 1) div sizeof(tWINRT_CONTROL_ITEM)
	 else
		  extraitems := 0;
	 index := additem(WinRTCtl.DIM, (DIMENSION_ARRAY + 1) shl 16 + size, 0);
	 result := pointer(index);
	 for index := 1 to extraitems do
		  additem(NOP, 0, 0);
		  // create an entry in the Dim list
	 DimStrItem := tDimStrItem.create(result, S, Size);
	 DimList.add(DimStrItem);
	 end;    { DimStr }

// tWinRT.DimK - Create a shadow helper constant.
//               Because it's a constant it actually does not
//               shadow any Pascal variable, but it's used
//               in math operations with other shadow variables }
// Inputs:  wordsize:   1 for byte or char, 2 for word, 4 for integer/longint
//          value:      the value to assign to the constant
Function tWinRT.DimK(wordsize, value : integer) : pointer;
var
    index   : integer;
begin
    if (wordsize = 4) or (wordsize = 2) or (wordsize = 1) then
        index := additem(WinRTCtl.DIM, (DIMENSION_CONSTANT + wordsize) shl 16 + 1, Value)
    else
        raise eWinRTError.create('Invalid word size in constant creation');
    result := pointer(index);
    end;    { DimK }

    // tWinRT.Flags2Ofs - converts flag options for size and
    //                    absolute/relative to offsets to command value
    // Inputs:  aFlags -  flags to convert
    //          Datasize - size of the data
    // Outputs: offset for command value
Function tWinRT.Flags2Ofs(const aFlags : tRTFlags; var Datasize : integer) : integer;
begin
    Result := Flags2Shf(aFlags);
        // get the size in bytes
    Datasize := 1 shl Result;
	 if rtfabs in aFlags then
        inc(Result, 6)
    end;    { Flags2Ofs }

    // tWinRT.Flags2Shf - converts flag options for size to offsets to command value
    // Inputs:  aFlags - flags to convert
    // Outputs: offset for command value.
    //          returns 0 for byte, 1 for word, 2 for long }
Function tWinRT.Flags2Shf(const aflags : tRTFlags) : integer;
begin
        // if rtfword and rtflong are set, rtfword takes precedence
    if rtfword in aflags then
        result := 1
    else if rtflong in aflags then
        result := 2
    else
        result := 0;
    end;    { Flags2Shf }

    // tWinRT.Putdata - iterates over the Dim items and puts the data into the buff^ array
    // Inputs:  none
    // Outputs: none
Procedure tWinRT.Putdata;
var
    i       : integer;
begin
    With Dimlist do
        For i := 0 to count - 1 do
            tDimItem(items[i]).put(buff^)
    end;    { Putdata }

    // tWinRT.Getdata - iterates over the Dim items and gets the data from the buff^ array
    // Inputs:  none
	 // Outputs: none
Procedure tWinRT.GetData;
var
    i   : integer;
begin
    With Dimlist do
        For i := 0 to count - 1 do
            tDimItem(items[i]).get(buff^)
    end;    { GetData }

    // tWinRT.Push - Helper function for while loops, and if statements.
    //               Pushes value onto the whilestack and preincrements WhileStackPointer.
    // Inputs:  Value - value to push onto the stack
    //          Stack - the stack to push the value onto
    // Outputs: none
Procedure tWinRT.Push(Value : integer; var Stack : tStack);
begin
    with Stack do begin
        inc(sp);
        if sp > high(data) then
            raise eWinRTError.create('WinRT Declaration Stack overflow');
        data[sp] := Value;
        end
    end;    { WhilePush }

    // tWinRT.Pop - Helper function for while loops and if statements.
    //              Pops value off the whilestack and decrements WhileStackPointer.
    // Inputs:  Stack - the stack to pop from
    // Outputs: the value popped from the stack
Function tWinRT.Pop(var Stack : tStack) : integer;
begin
    with Stack do begin
        if sp < low(data) then
				raise eWinRTError.create('WinRT Declaration Stack underflow');
        Result := data[sp];
        dec(sp);
        end
    end;    { WhilePop }

    // tWinRT._While - insert a _While statement in the list. All the list elements
    //                 will be processed later when the methods ProcessBuffer,
    //                 WaitInterrupt or SetInterrupt are called
    //
    // Inputs:
    //      aMath       The logical or bitwise command to be performed. It's listed in
    //                  the file WinRTCtl as an enumeration type tWINRT_LOGIC_MATH
    //      Mathflags   Optional flags that modify the operation. Also listed
    //                  in the interface section of file WinRTCtl
    //                  meaningful flags are LOGICAL_NOT_FLAG and MATH_SIGNED
    //      Var1, Var2  pseudo pointers to the first and second operand.  These
    //                  are pseudo pointers to dimmed variables
    // Outputs: none
    //
    //  The _while statement continues until the next matching _Wend
Procedure tWinRT._While(amath : tWINRT_LOGIC_MATH; mathflags : integer; var1, var2 : pointer);
begin
    Push(additem(WinRTCtl._While, (ord(amath) or mathflags) shl 16, integer(var1) shl 16 + integer(var2)), WhileStack);
    end;    { _While }

    //  tWinRT._Wend - Inserts the statement that ends the _While.
    //                 An exception will be raised if there is no pending _While.
    // Inputs:  none
    // Outputs: none
Procedure tWinRT._Wend;
var
    lastwhile   : integer;
	 whilep      : pCONTROL_ITEM_ex;

begin
    try
        lastwhile := Pop(WhileStack);
    except
        on eWinRTError do
            raise eWinRTError.create('A _Wend call without a corresponding _While');
        end;
        // code the looping jump
    AddItem(JUMP_TO, lastwhile - flist.count, 0);
    whilep := flist[lastwhile];
    with whilep^ do
            // store the while jump offset past the JUMP_TO
        port := port or (flist.count - lastwhile)
    end;    { _Wend }

    // tWinRT._IF - insert an _IF statement in the list. All the list elements
    //              will be processed later when the methods ProcessBuffer,
    //              WaitInterrupt or SetInterrupt are called
    //
    // Inputs:
    //      aMath       The logical or bitwise command to be performed. It's listed in
    //                  the file WinRTCtl as an enumeration type tWINRT_LOGIC_MATH
    //      Mathflags   Optional flags that modify the operation. Also listed
    //                  in the interface section of file WinRTCtl
    //                  meaningful flags are LOGICAL_NOT_FLAG and MATH_SIGNED
    //      Var1, Var2  pseudo pointers to the first and second operand
    // Outputs: none
    //
    // The _IF statement continues until the next matching _Else or _Endif
Procedure tWinRT._If(aMath : tWINRT_LOGIC_MATH; Mathflags : integer; Var1, Var2 : pointer);
begin
	 Push(additem(LOGICAL_IF, (ord(aMath) or Mathflags) shl 16, integer(Var1) shl 16 + integer(Var2)), IfStack);
    end;    { _If }

    // tWinRT._Else - Insert the statement that starts the code that will perform
    //                if the _If condition does not succeed.
    //                An exception will be raised if there is no pending _IF
    // Inputs:  none
    // Outputs: none
Procedure tWinRT._Else;
var
    lastif  : integer;
    ifp     : pCONTROL_ITEM_ex;
begin
    try
        lastif := Pop(IfStack);
        if lastif < 0 then
            raise eWinRTError.create('');
    except
        on eWinRTError do
            raise eWinRTError.create('An _Else call without an _If');
        end;
        // or it with $80000000 to flag it as an else
    Push(AddItem(JUMP_TO, 0, 0) or integer($80000000), ifstack);
    ifp := flist[lastif];
    with ifp^ do
        port := port or (flist.count - lastif);
    end;    { _Else }

    // tWinRT._Endif - Insert the statement that starts the code that will finish
    //                 the _If or _Else section
    //                 An exception will be raised if there is no pending _IF or _Else
    // Inputs:  none
    // Outputs: none
Procedure tWinRT._Endif;
var
    LastIfElse  : integer;
    Jumpp       : pCONTROL_ITEM_ex;
begin
    try
        LastIfElse := Pop(IfStack) and $7fffffff;	{ get the last _if or _else }
    except
        On eWinRTError do
            raise eWinRTError.create('An _Endif without a matching _If or _Else');
        end;
    Jumpp := flist[LastIfElse];                 { get the control item pointer }
    with Jumpp^ do
        port := port or (flist.count - LastIfElse);     { fix the jump offset }
    end;    { _Endif }

    // tWinRT.Math - insert a math item in the list. All the list elements
    //               will be processed later when the methods ProcessBuffer,
    //               WaitInterrupt or SetInterrupt are called.
    //
    // Inputs:
    //      operation   The math command to be performed. It's listed in
    //                  the file WinRTCtl as an enumeration type tWINRT_LOGIC_MATH
    //      flags       Optional flags that modify the operation. Also listed
    //                  in the interface section of file WinRTCtl
    //      result      pseudo pointer to the shadow variable that will receive the
    //                  result
    //      var1, var2  pseudo pointers to the first and second operand
    //
    // Outputs:         none
Procedure tWinRT.Math(Operation : tWINRT_LOGIC_MATH; Flags : integer; Result, Var1, Var2 : pointer);
begin
    AddItem(WinRTctl.MATH, (integer(Operation) + Flags) shl 16 + integer(Result), integer(Var1) shl 16 + integer(Var2));
	 end;    { Math }

	 // tWinRT.ArrayMove - move a value from a shadow array entry to another.
	 //                    Either the source or the destination can be a non-array
	 //                    shadow variable, in which case use an index of 0
	 //
	 // Inputs
	 //      lvar:       left side (destination) array pseudo pointer
	 //      lvarindex:  destination index. Use 0 if not an array
	 //      rvar:       right side (source) array pseudo pointer
	 //      lvarindex:  source index. Use 0 if not an array
Procedure tWinRT.ArrayMove(lvar : pointer; lvarindex : integer; rvar : pointer; rvarindex : integer);
begin
	 AddItem(ARRAY_MOVE, integer(lvar) + lvarindex shl 16, integer(rvar) + rvarindex shl 16)
	 end;    { ArrayMove }

	 // tWinRT.ArraySrcInd - move a value from a shadow array entry to another.
	 //                      The source index is indirect
	 //                      The index in the source is actually another shadow
	 //                      variable as in
	 //                          lvar[lvarindex] := rvar[shadow variable]
	 //                      The destination can be a non-array
	 //                           shadow variable, in which case use an index of 0
	 //
	 // Inputs
	 //      lvar:       left side (destination) array pseudo pointer
	 //      lvarindex:  destination index. Use 0 if not an array
	 //      rvar:       right side (source) array pseudo pointer
	 //      rvarindex:  source index shadow variable pseudo pointer.
    //                      This is an indirect index
Procedure tWinRT.ArraySrcInd(lvar : pointer; lvarindex : integer; rvar, rvarindex : pointer);
begin
    ArrayMove(lvar, lvarindex, rvar, integer(rvarindex) + ARRAY_MOVE_INDIRECT);
	 end;    { ArraySrcInd }

    // tWinRT.ArrayDstInd - move a value from a shadow array entry to another.
    //                      The destination index is indirect
    //                      The index in the destination is actually another shadow
    //                      variable as in
    //                           lvar[shadow variable] := rvar[rvarindex]
    //                      The source can be a non-array
    //                           shadow variable, in which case use an index of 0
    //
    // Inputs
    //      lvar:       left side (destination) array pseudo pointer
    //      lvarindex:  destination index shadow variable pseudo pointer.
    //                      This is an indirect index
    //      rvar:       right side (source) array pseudo pointer
    //      rvarindex:  source index. Use 0 if not an array
Procedure tWinRT.ArrayDstInd(lvar, lvarindex : pointer; rvar : pointer; rvarindex : integer);
begin
    ArrayMove(lvar, integer(lvarindex) + ARRAY_MOVE_INDIRECT, rvar, rvarindex)
    end;    { ArrayDstInd }

    // tWinRT.ArrayBothInd - move a value from a shadow array entry to another.
    //                       The destination and source indices are indirect
    //                       They are shadow variables as in
    //                       lvar[shadow variable] := rvar[shadow variable]
    //
    // Inputs
    //      lvar:       left side (destination) array pseudo pointer
	 //      lvarindex:  destination index shadow variable pseudo pointer.
    //                      This is an indirect index
    //      rvar:       right side (source) array pseudo pointer
    //      rvarindex:  source index shadow variable pseudo pointer.
    //                  This is an indirect index
Procedure tWinRT.ArrayBothInd(lvar, lvarindex, rvar, rvarindex : pointer);
begin
    ArrayMove(lvar, integer(lvarindex) + ARRAY_MOVE_INDIRECT, rvar, integer(rvarindex) + ARRAY_MOVE_INDIRECT)
    end;    { ArrayBothInd }

    // tWinRT._Goto - Yes, there is a goto statement! But you don't have
    //                to use it if you don't like it!
    //                _Goto is useful when there is a need to exit from
    //                several levels of nested _if's or _While's
    //
    //  Input aLabel:   The label to jump to. The label can be declared before
    //                  or after the _goto statement
    //                  Any number of _goto statements can jump to the same
    //                  label
Procedure tWinRT._Goto(const aLabel : string);
var
    position,
    index,
    jumpofs : integer;
begin
    position := -1;
    with fLabelList do begin
        if find(aLabel, index) then
            position := integer(objects[index]);
        if position >= 0 then
            jumpofs := position - fList.count
        else begin
            jumpofs := 0;
				addobject(aLabel, pointer(fList.count or integer($80000000)));
				inc(undefgotos)
            end;
        end;
    AddItem(JUMP_TO, jumpofs, 0);
	 end;    { _Goto }

    // tWinRT._Label - Create a label that allows _Goto Statements to jump
    //                 to it.
	 //
	 //  Input
	 //      aLabel: The label name. The label can be declared before
	 //              or after the _goto statement
	 //              Any number of _goto statements can jump to the same label
	 //              Will raise an exception if a label with the same
	 //              name has been already declared
Procedure tWinRT._Label(const aLabel : string);
var
	 controlitemindex,
	 index   : integer;
	 Jumpp           : pCONTROL_ITEM_ex;
begin
    with fLabelList do begin
		repeat
            if not find(aLabel, index) then
                 break;
            controlitemindex := integer(objects[index]);
            if controlitemindex < 0 then begin				// a yet undefined goto
                 controlitemindex := controlitemindex and $7fffffff;		// reset the label unknown bit
                 jumpp := fList[controlitemindex];
                 with jumpp^ do
                      port := port or (fList.count - controlitemindex);		{ fix the jump offset }
                 delete(index);      // another one taken care
                 dec(undefgotos)     // one less to worry
                 end
            else
                 raise eWinRTError.createfmt('Duplicate Label "%s"', [aLabel]);
            until false;
                // add the label to the list
            addobject(aLabel, pointer(fList.count));
            end;    { with }
	 end;    { _Label }

	 // tWinRT.assign - assign a shadow variable to another. They must not be
	 //                 array variables
	 // Inputs:  dst -    The destination pseudo pointer
	 //          src -    The source pseudo pointer
	 // Outputs; none
Procedure tWinRT.assign(dst, src : pointer);
begin
	 Math(MOVE_TO, 0, dst, src, nil)
	 end;    { assign }

	 // tWinRT.GetControlItems - gets a control item from the list
	 // Inputs:  index - index of the item to get
	 // Outputs: the item
Function tWinRT.GetControlItems(index : integer) : pCONTROL_ITEM_ex;
begin
	 result := flist[index]
	 end;    { GetControlItems }

	 // tWinRT.ExternDim - dimensions a shadow variable or array. Returns a pseudo pointer
	 //
	 // Inputs:
	 //      name:       the name of the extern variable
	 //  wordsize:   1 for byte or char, 2 for word, 4 for integer/longint
	 //      wordcount:  1 if single item, or the range if an array
	 //      data:       a reference (not a pointer) to the Pascal variable shadows
	 // Outputs:     returns a pseudo pointer to the shadow variable created. This is
	 //              not a valid pascal pointer and should not be used as such
function tWinRT.ExternDim(name: string; wordsize, wordcount: integer;
  var data): pointer;
var
	 i,
	 flags,
	 extrabytes,
	 extraitems  : integer;
	 Dimitem     : tDimItem;
begin
	 extrabytes := wordsize * wordcount - sizeof(longint);
	 if extrabytes > 0 then
		  extraitems := (extrabytes + sizeof(tWINRT_CONTROL_ITEM) - 1) div sizeof(tWINRT_CONTROL_ITEM)
	 else
		  extraitems := 0;
	 if wordcount < 1 then
		  wordcount := 1;
	 if wordcount = 1 then
		  flags := DIMENSION_EXTERN
	 else
		  flags := DIMENSION_ARRAY + DIMENSION_EXTERN;
	 i := additem(WinRTCtl.DIM, (flags + wordsize) shl 16 + wordcount, 0);
	 result := pointer(i);
	 for i := 1 to extraitems do
		  additem(NOP, 0, 0);
		  // create an entry in the Dim list
	 DimItem := tDimItem.create(result, data, WordSIze * WordCount);
	 DimList.add(DimItem);

     AddName(WinRTCtl.WINRT_EXTERN, name);

	 end;    { Dim }



	 // tWinRT.GlobalDim - dimensions a global shadow variable or array. Returns a pseudo pointer
	 // Inputs:
	 //      name:       the name of the global variable
	 //  wordsize:   1 for byte or char, 2 for word, 4 for integer/longint
	 //  wordcount:  1 if single item, or the range if an array
	 //  data:       a reference (not a pointer) to the Pascal variable shadows
	 // Outputs:     returns a pseudo pointer to the shadow variable created. This is
	 //              not a valid pascal pointer and should not be used as such
function tWinRT.GlobalDim(name: string; wordsize, wordcount: integer;
  var data): pointer;
var
	 i,
	 flags,
	 extrabytes,
	 extraitems  : integer;
	 Dimitem     : tDimItem;
begin
	 extrabytes := wordsize * wordcount - sizeof(longint);
	 if extrabytes > 0 then
		  extraitems := (extrabytes + sizeof(tWINRT_CONTROL_ITEM) - 1) div sizeof(tWINRT_CONTROL_ITEM)
	 else
		  extraitems := 0;
	 if wordcount < 1 then
		  wordcount := 1;
	 if wordcount = 1 then
		  flags := DIMENSION_GLOBAL
	 else
		  flags := DIMENSION_ARRAY + DIMENSION_GLOBAL;
	 i := additem(WinRTCtl.DIM, (flags + wordsize) shl 16 + wordcount, 0);
	 result := pointer(i);
	 for i := 1 to extraitems do
		  additem(NOP, 0, 0);
		  // create an entry in the Dim list
	 DimItem := tDimItem.create(result, data, WordSIze * WordCount);
	 DimList.add(DimItem);

     AddName(WinRTCtl.WINRT_GLOBAL, name);

	 end;    { Dim }


procedure tWinRT.AddName(GlobalOrExtern: integer; const name: string);
var
	 index,
	 extrabytes,
	 extraitems:    integer;
     p:             pointer;

begin
	 extrabytes := length(name) + 1 - sizeof(longint);
	 if extrabytes > 0 then
		  extraitems := (extrabytes + sizeof(tWINRT_CONTROL_ITEM) - 1) div sizeof(tWINRT_CONTROL_ITEM)
	 else
		  extraitems := 0;

     // increment name refcount
     p := nil;
     string(p) := name;
	 additem(GlobalOrExtern, extraitems, integer(p));
	 for index := 1 to extraitems do
		  additem(NOP, 0, 0);
end;

end.
