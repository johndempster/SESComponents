{========================================================================}
{=================        TVicHW32  Version 6.0         =================}
{======         Copyright (c) 1997-2004 Victor I.Ishikeev           =====}
{========================================================================}
{=====             http://www.entechtaiwan.com/tools.htm          =======}
{==========             mailto:tools@entechtaiwan.com             =======}
{========================================================================}
{=====                 TVicHW32.DLL interface                       =====} 
{========================================================================}

unit TVicLib;

{==} interface {==}

uses Windows, HW_Types;

function  OpenTVicHW : THANDLE;  stdcall;
function  OpenTVicHW32(HW32 : THANDLE; ServiceName : PChar; EntryPoint : PChar) : THANDLE; stdcall;

function  CloseTVicHW32(HW32 : THANDLE) : THANDLE;     stdcall;
function  GetActiveHW(HW32 : THANDLE) : BOOL;          stdcall;

function  GetHardAccess(HW32 : THANDLE) : BOOL;        stdcall;
procedure SetHardAccess(HW32 : THANDLE; bNewValue : BOOL); stdcall;

function  GetPortByte( HW32 : THANDLE; PortAddr : DWORD) : Byte;  stdcall;
procedure SetPortByte( HW32 : THANDLE; PortAddr : DWORD; nNewValue : Byte); stdcall;
function  GetPortWord( HW32 : THANDLE; PortAddr : DWORD) : Word;            stdcall;
procedure SetPortWord( HW32 : THANDLE; PortAddr : DWORD; nNewValue : Word); stdcall;
function  GetPortLong( HW32 : THANDLE; PortAddr : DWORD): LongInt;          stdcall;
procedure SetPortLong( HW32 : THANDLE; PortAddr : DWORD; nNewValue : Longint); stdcall;

function  MapPhysToLinear( HW32: THANDLE; PhAddr: DWORD; PhSize: DWORD) : Pointer;  stdcall;
procedure UnmapMemory( HW32: THANDLE; PhAddr : DWORD; PhSize: DWORD); stdcall;
function  GetLockedMemory( HW32 : THANDLE ): Pointer;   stdcall;
function  GetTempVar( HW32 : THANDLE ): Longint;   stdcall;

function  GetMemByte(HW32 : THANDLE; MappedAddr : DWORD ;  Offset : DWORD) : Byte; stdcall;
procedure SetMemByte(HW32 : THANDLE; MappedAddr : DWORD ;  Offset : DWORD; nNewValue : Byte); stdcall;
function  GetMemWord(HW32 : THANDLE;MappedAddr : DWORD ;  Offset : DWORD) : Word; stdcall;
procedure SetMemWord(HW32 : THANDLE;MappedAddr : DWORD ;  Offset : DWORD; nNewValue : Word); stdcall;
function  GetMemLong(HW32 : THANDLE;MappedAddr : DWORD ;  Offset : DWORD) : DWORD;           stdcall;
procedure SetMemLong(HW32 : THANDLE;MappedAddr : DWORD ;  Offset : DWORD; nNewValue : DWORD);stdcall;

function  IsIRQMasked(HW32 : THANDLE; IRQNumber : WORD) : BOOL;         stdcall;
procedure UnmaskIRQ(HW32 : THANDLE; IRQNumber : WORD; HWHandler : TOnHWInterrupt); stdcall;
procedure UnmaskIRQEx(HW32 : THANDLE;
                      IRQNumber : WORD;
                      IrqShared : DWORD;
                      HWHandler : TOnHWInterrupt;
                      ClearRec  : pIrqClearRec
                      ); stdcall;
procedure UnmaskDelphiIRQ(HW32 : THANDLE; TVic: THANDLE; IRQNumber : WORD; HWHandler : TOnDelphiInterrupt); stdcall;
procedure UnmaskDelphiIRQEx(HW32 : THANDLE;
                            TVic: THANDLE;
                            IRQNumber : WORD;
                            IrqShared : DWORD;
                            HWHandler : TOnDelphiInterrupt;
                            ClearRec  : pIrqClearRec
                            ); stdcall;

procedure MaskIRQ(HW32 : THANDLE; IRQNumber : WORD);                 stdcall;
function  GetIRQCounter(HW32: THANDLE; IRQNumber : WORD): DWORD;     stdcall;
procedure PulseIrqKernelEvent(HW32: THANDLE);                        stdcall;
procedure PulseIrqLocalEvent(HW32: THANDLE);                         stdcall;



procedure PutScanCode(HW32 : THANDLE; b : Byte);                     stdcall;
function  GetScanCode(HW32 : THANDLE):Word;                          stdcall;
procedure HookKeyboard(HW32 : THANDLE; KbdHandler : TOnKeystroke);   stdcall;
procedure HookDelphiKeyboard(HW32 : THANDLE; TVic : THANDLE; KbdHandler : TOnDelphiKeystroke);   stdcall;
procedure UnhookKeyboard(HW32 : THANDLE);                            stdcall;
procedure PulseKeyboard(HW32 : THANDLE);                             stdcall;
procedure PulseKeyboardLocal(HW32 : THANDLE);                        stdcall;

function GetLPTNumber  (HW32 : THANDLE) : Byte;                     stdcall;
procedure SetLPTNumber (HW32 : THANDLE; nNewValue : Byte);          stdcall;
function GetLPTNumPorts(HW32 : THANDLE) : Byte;                     stdcall;
function GetLPTBasePort(HW32 : THANDLE) : DWORD;                    stdcall;
function AddNewLPT     (HW32 : THANDLE; PortBaseAddress : Word):Byte;    stdcall;


function GetPin( HW32 : THANDLE; nPin : Byte) : BOOL;                stdcall;
procedure SetPin( HW32 : THANDLE; nPin : Byte; bNewValue : BOOL);    stdcall;

function GetLPTAckwl (HW32 : THANDLE) : BOOL;                        stdcall;
function GetLPTBusy(HW32 : THANDLE) : BOOL;                          stdcall;
function GetLPTPaperEnd(HW32 : THANDLE) : BOOL;                      stdcall;
function GetLPTSlct(HW32 : THANDLE) : BOOL;                          stdcall;
function GetLPTError(HW32 : THANDLE) : BOOL;                         stdcall;
procedure LPTInit(HW32 : THANDLE);                                   stdcall;
procedure LPTSlctIn(HW32 : THANDLE);                                 stdcall;
procedure LPTStrobe(HW32 : THANDLE);                                 stdcall;
procedure LPTAutofd( HW32 : THANDLE; Flag : BOOL);                   stdcall;

procedure SetLPTReadMode( HW32 : THANDLE );                          stdcall;
procedure SetLPTWriteMode( HW32 : THANDLE );                         stdcall;

procedure ForceIrqLPT( HW32 : THANDLE; IrqEnable : BOOL);            stdcall;

procedure   ReadPortFIFO  ( HW32 : THANDLE; pBuffer : pPortByteFIFO);stdcall;
procedure   ReadPortWFIFO ( HW32 : THANDLE; pBuffer : pPortWordFIFO);stdcall;
procedure   ReadPortLFIFO ( HW32 : THANDLE; pBuffer : pPortLongFIFO);stdcall;
procedure   WritePortFIFO ( HW32 : THANDLE; pBuffer : pPortByteFIFO);stdcall;
procedure   WritePortWFIFO( HW32 : THANDLE; pBuffer : pPortWordFIFO);stdcall;
procedure   WritePortLFIFO( HW32 : THANDLE; pBuffer : pPortLongFIFO);stdcall;

procedure   GetHDDInfo(HW32      : THANDLE;
		           IdeNumber : Word;
                       Master    : Word;
                       Info      : pHDDInfo);  stdcall;

function    GetLastPciBus(HW32      : THANDLE) : Word; stdcall;
function    GetHardwareMechanism(HW32      : THANDLE) : Word; stdcall;

function    GetPciDeviceInfo( HW32            : THANDLE;
                              Bus,Device,Func : Word;
                              CfgInfo         : pPciCfg) : BOOL;  stdcall;

function    GetPciHeader ( HW32              : THANDLE;
                           VendorId,DeviceId : DWord;
                           OffsetInBytes     : DWord;
                           LengthInBytes     : DWord;
                           CfgInfo           : pPciCfg) : BOOL; stdcall;

function    SetPciHeader ( HW32              : THANDLE;
                           VendorId,DeviceId : DWord;
                           OffsetInBytes     : DWord;
                           LengthInBytes     : DWord;
                           CfgInfo           : pPciCfg) : BOOL; stdcall;


function    GetSysDmaBuffer      ( HW32   : THANDLE;
	 		           BufReq : pDmaBufferRequest) : BOOL; stdcall;

function    GetBusmasterDmaBuffer( HW32   : THANDLE;
	 		           BufReq : pDmaBufferRequest) : BOOL; stdcall;

function    FreeDmaBuffer        ( HW32   : THANDLE;
	 		           BufReq : pDmaBufferRequest) : BOOL; stdcall;

function  AcquireLPT  ( HW32 : THANDLE; LPTNumber : Word) : Word; stdcall;
procedure ReleaseLPT  ( HW32 : THANDLE; LPTNumber : Word);        stdcall;
function IsLPTAcquired( HW32 : THANDLE; LPTNumber : Word) : Word; stdcall;

function  RunRing0Function (HW32                : THANDLE;
                            Ring0FunctionAddress: TRing0Function;
                            pParm               : Pointer) : Longint;
                            stdcall; 


function  DebugCode(HW32 : THANDLE): Longint; stdcall;
function  GetLocalInstance: Longint; stdcall;
procedure GetMsrValue( HW32 : THANDLE; RegNumberr : DWORD; var data: TMSR_DATA);          stdcall;
procedure CPUID( HW32: THANDLE; var Rec: CPUID_RECORD); stdcall;



{==} implementation {==}

const
  DllName = 'TVicHW32.dll';

function  OpenTVicHW : THANDLE;
                 stdcall; external DllName name '_OpenTVicHW@0';

function  OpenTVicHW32(HW32 : THANDLE;
                       ServiceName : PChar;
                       EntryPoint : PChar) : THANDLE;
                 stdcall; external DllName name '_OpenTVicHW32@12';


function  CloseTVicHW32(HW32 : THANDLE) : THANDLE;
                 stdcall; external DllName name '_CloseTVicHW32@4';


function  GetActiveHW(HW32 : THANDLE) : BOOL;
                 stdcall; external DllName name '_GetActiveHW@4';

function  GetHardAccess(HW32 : THANDLE) : BOOL;
                 stdcall; external DllName name '_GetHardAccess@4';

procedure SetHardAccess(HW32 : THANDLE; bNewValue : BOOL);
                 stdcall; external DllName name '_SetHardAccess@8';

function  GetPortByte( HW32 : THANDLE; PortAddr : DWORD) : Byte;
                 stdcall; external DllName name '_GetPortByte@8';
procedure SetPortByte( HW32 : THANDLE; PortAddr : DWORD; nNewValue : Byte);
                 stdcall; external DllName name '_SetPortByte@12';
function  GetPortWord( HW32 : THANDLE; PortAddr : DWORD) : Word;
                 stdcall; external DllName name '_GetPortWord@8';
procedure SetPortWord( HW32 : THANDLE; PortAddr : DWORD; nNewValue : Word);
                 stdcall; external DllName name '_SetPortWord@12';
function  GetPortLong( HW32 : THANDLE; PortAddr : DWORD): LongInt;
                 stdcall; external DllName name '_GetPortLong@8';
procedure SetPortLong( HW32 : THANDLE; PortAddr : DWORD; nNewValue : Longint);
                 stdcall; external DllName name '_SetPortLong@12';

function  MapPhysToLinear( HW32 : THANDLE; PhAddr : DWORD; PhSize: DWORD) : Pointer;
                 stdcall; external DllName name '_MapPhysToLinear@12';
procedure UnmapMemory( HW32 : THANDLE; PhAddr : DWORD; PhSize: DWORD);
                 stdcall; external DllName name '_UnmapMemory@12';
function  GetLockedMemory( HW32 : THANDLE ): Pointer;
                 stdcall; external DllName name '_GetLockedMemory@4';
function  GetTempVar( HW32 : THANDLE ): Longint;
                 stdcall; external DllName name '_GetTempVar@4';


function  GetMemByte(HW32 : THANDLE; MappedAddr : DWORD ;  Offset : DWORD) : Byte;
                 stdcall; external DllName name '_GetMem@12';
procedure SetMemByte(HW32 : THANDLE; MappedAddr : DWORD ;  Offset : DWORD; nNewValue : Byte);
                 stdcall; external DllName name '_SetMem@16';
function  GetMemWord(HW32 : THANDLE;MappedAddr : DWORD ;  Offset : DWORD) : Word;
                 stdcall; external DllName name '_GetMemW@12';
procedure SetMemWord(HW32 : THANDLE;MappedAddr : DWORD ;  Offset : DWORD; nNewValue : Word);
                 stdcall; external DllName name '_SetMemW@16';
function  GetMemLong(HW32 : THANDLE;MappedAddr : DWORD ;  Offset : DWORD) : DWORD;
                 stdcall; external DllName name '_GetMemL@12';
procedure SetMemLong(HW32 : THANDLE;MappedAddr : DWORD ;  Offset : DWORD; nNewValue : DWORD);
                 stdcall; external DllName name '_SetMemL@16';


function  IsIRQMasked(HW32 : THANDLE; IRQNumber : WORD) : BOOL;
                 stdcall; external DllName name '_IsIRQMasked@8';
procedure UnmaskIRQ(HW32 : THANDLE; IRQNumber : WORD; HWHandler : TOnHWInterrupt);
                 stdcall; external DllName name '_UnmaskIRQ@12';
procedure UnmaskDelphiIRQ(HW32 : THANDLE; TVic : THANDLE; IRQNumber : WORD; HWHandler : TOnDelphiInterrupt);
                 stdcall; external DllName name '_UnmaskDelphiIRQ@16';
procedure UnmaskIRQEx(HW32 : THANDLE;
                      IRQNumber : WORD;
                      IrqShared : DWORD;
                      HWHandler : TOnHWInterrupt;
                      ClearRec  : pIrqClearRec
                      );
                 stdcall; external DllName name '_UnmaskIRQEx@20';

procedure UnmaskDelphiIRQEx(HW32 : THANDLE;
                            TVic: THANDLE;
                            IRQNumber : WORD;
                            IrqShared : DWORD;
                            HWHandler : TOnDelphiInterrupt;
                            ClearRec  : pIrqClearRec
                            );
                 stdcall; external DllName name '_UnmaskDelphiIRQEx@24';


procedure MaskIRQ(HW32 : THANDLE; IRQNumber : WORD);
                 stdcall; external DllName name '_MaskIRQ@8';
function  GetIRQCounter(HW32: THANDLE; IRQNumber : WORD):DWORD;
                 stdcall; external DllName name '_GetIRQCounter@8';
procedure PulseIrqKernelEvent(HW32: THANDLE);                        stdcall;
external DllName name '_PulseIrqKernelEvent@4';
procedure PulseIrqLocalEvent(HW32: THANDLE);                         stdcall;
external DllName name '_PulseIrqLocalEvent@4';


procedure PutScanCode(HW32 : THANDLE; b : Byte);
                 stdcall; external DllName name '_PutScanCode@8';

function  GetScanCode(HW32 : THANDLE):Word;
                 stdcall; external DllName name '_GetScanCode@4';

procedure HookKeyboard(HW32 : THANDLE; KbdHandler : TOnKeystroke);
                 stdcall; external DllName name '_HookKeyboard@8';
procedure HookDelphiKeyboard(HW32 : THANDLE; TVic : THANDLE; KbdHandler : TOnDelphiKeystroke);
                 stdcall; external DllName name '_HookDelphiKeyboard@12';
procedure UnhookKeyboard(HW32 : THANDLE);
                 stdcall; external DllName name '_UnhookKeyboard@4';
procedure PulseKeyboard(HW32 : THANDLE);
                 stdcall; external DllName name '_PulseKeyboard@4';
procedure PulseKeyboardLocal(HW32 : THANDLE);
                 stdcall; external DllName name '_PulseKeyboardLocal@4';

function GetLPTNumber (HW32 : THANDLE) : Byte;
                 stdcall; external DllName name '_GetLPTNumber@4';
procedure SetLPTNumber( HW32 : THANDLE; nNewValue : Byte);
                 stdcall; external DllName name '_SetLPTNumber@8';
function GetLPTNumPorts (HW32 : THANDLE) : Byte;
                 stdcall; external DllName name '_GetLPTNumPorts@4';
function GetLPTBasePort (HW32 : THANDLE) : DWORD;
                 stdcall; external DllName name '_GetLPTBasePort@4';
function AddNewLPT     (HW32 : THANDLE; PortBaseAddress : Word):Byte;
                 stdcall; external DllName name '_AddNewLPT@8';

function GetPin( HW32 : THANDLE; nPin : Byte) : BOOL;
                 stdcall; external DllName name '_GetPin@8';
procedure SetPin( HW32 : THANDLE; nPin : Byte; bNewValue : BOOL);
                 stdcall; external DllName name '_SetPin@12';

function GetLPTAckwl (HW32 : THANDLE) : BOOL;
                 stdcall; external DllName name '_GetLPTAckwl@4';
function GetLPTBusy(HW32 : THANDLE) : BOOL;
                 stdcall; external DllName name '_GetLPTBusy@4';
function GetLPTPaperEnd(HW32 : THANDLE) : BOOL;
                 stdcall; external DllName name '_GetLPTPaperEnd@4';
function GetLPTSlct(HW32 : THANDLE) : BOOL;
                 stdcall; external DllName name '_GetLPTSlct@4';
function GetLPTError(HW32 : THANDLE) : BOOL;
                 stdcall; external DllName name '_GetLPTError@4';

procedure LPTInit(HW32 : THANDLE);
                 stdcall; external DllName name '_LPTInit@4';
procedure LPTSlctIn(HW32 : THANDLE);
                 stdcall; external DllName name '_LPTSlctIn@4';
procedure LPTStrobe(HW32 : THANDLE);
                 stdcall; external DllName name '_LPTStrobe@4';
procedure LPTAutofd( HW32 : THANDLE; Flag : BOOL);
                 stdcall; external DllName name '_LPTAutofd@8';

procedure SetLPTReadMode( HW32 : THANDLE );
                 stdcall; external DllName name '_SetLPTReadMode@4';

procedure SetLPTWriteMode( HW32 : THANDLE );
                 stdcall; external DllName name '_SetLPTWriteMode@4';

procedure ForceIrqLPT( HW32 : THANDLE; IrqEnable : BOOL);
                 stdcall; external DllName name '_ForceIrqLPT@8';

procedure   ReadPortFIFO ( HW32 : THANDLE; pBuffer : pPortByteFIFO);
                 stdcall; external DllName name '_ReadPortFIFO@8';
procedure   ReadPortWFIFO( HW32 : THANDLE; pBuffer : pPortWordFIFO);
                 stdcall; external DllName name '_ReadPortWFIFO@8';
procedure   ReadPortLFIFO( HW32 : THANDLE; pBuffer : pPortLongFIFO);
                 stdcall; external DllName name '_ReadPortLFIFO@8';

procedure   WritePortFIFO( HW32 : THANDLE; pBuffer : pPortByteFIFO);
                 stdcall; external DllName name '_WritePortFIFO@8';
procedure   WritePortWFIFO( HW32 : THANDLE; pBuffer : pPortWordFIFO);
                 stdcall; external DllName name '_WritePortWFIFO@8';
procedure   WritePortLFIFO( HW32 : THANDLE; pBuffer : pPortLongFIFO);
                 stdcall; external DllName name '_WritePortLFIFO@8';

procedure   GetHDDInfo(HW32      : THANDLE;
		       IdeNumber : Word;
                       Master    : Word;
                       Info      : pHDDInfo);
                 stdcall; external DllName name '_GetHDDInfo@16';

function    GetLastPciBus(HW32      : THANDLE) : Word;
                 stdcall; external DllName name '_GetLastPciBus@4';
function    GetHardwareMechanism(HW32      : THANDLE) : Word;
                 stdcall; external DllName name '_GetHardwareMechanism@4';
function    GetPciDeviceInfo( HW32      : THANDLE;
                              Bus,Device,Func : Word;
                              CfgInfo         : pPciCfg) : BOOL;
                 stdcall; external DllName name '_GetPciDeviceInfo@20';

function    GetPciHeader ( HW32              : THANDLE;
                           VendorId,DeviceId : DWord;
                           OffsetInBytes     : DWord;
                           LengthInBytes     : DWord;
                           CfgInfo           : pPciCfg) : BOOL;
                 stdcall; external DllName name '_GetPciHeader@24';

function    SetPciHeader ( HW32      : THANDLE;
                           VendorId,DeviceId : DWord;
                           OffsetInBytes     : DWord;
                           LengthInBytes     : DWord;
                           CfgInfo         : pPciCfg) : BOOL; 

                 stdcall; external DllName name '_SetPciHeader@24';
  

function    GetSysDmaBuffer      ( HW32   : THANDLE;
	 		           BufReq : pDmaBufferRequest) : BOOL;
                 stdcall; external DllName name '_GetSysDmaBuffer@8';

function    GetBusmasterDmaBuffer( HW32   : THANDLE;
	 		           BufReq : pDmaBufferRequest) : BOOL;
                 stdcall; external DllName name '_GetBusmasterDmaBuffer@8';

function    FreeDmaBuffer        ( HW32   : THANDLE;
	 		           BufReq : pDmaBufferRequest) : BOOL;
                 stdcall; external DllName name '_FreeDmaBuffer@8';

function  AcquireLPT  ( HW32 : THANDLE; LPTNumber : Word) : Word; 
                 stdcall; external DllName name '_AcquireLPT@8';
procedure ReleaseLPT  ( HW32 : THANDLE; LPTNumber : Word);
                 stdcall; external DllName name '_ReleaseLPT@8';
function IsLPTAcquired( HW32 : THANDLE; LPTNumber : Word) : Word;
                 stdcall; external DllName name '_IsLPTAcquired@8';

function DebugCode(HW32 : THANDLE): Longint; 
                 stdcall; external DllName name '_DebugCode@4';

function  RunRing0Function        (HW32                : THANDLE;
                                   Ring0FunctionAddress: TRing0Function;
                                   pParm               : Pointer) : Longint;
                 stdcall; external DllName name '_RunRing0Function@12';

function  GetLocalInstance: Longint; stdcall;
       external DllName name '_GetLocalInstance@0';

procedure  GetMsrValue( HW32 : THANDLE; RegNumberr : DWORD; var data: TMSR_DATA);
       stdcall; external DllName name '_GetMsrValue@12';
procedure CPUID( HW32: THANDLE; var Rec: CPUID_RECORD);
       stdcall; external DllName name '_CPUID@8';

end.