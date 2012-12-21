{========================================================================}
{=================        TVicHW64  Version 6.0         =================}
{======         Copyright (c) 1997-2004 Victor I.Ishikeev           =====}
{========================================================================}
{=====             http://www.entechtaiwan.com/tools.htm          =======}
{==========             mailto:tools@entechtaiwan.com             =======}
{========================================================================}
{=====              The basic TVicHW6 data declarations            =====}
{========================================================================}

unit HW_Types;

{-------}   interface   {---------}

uses Windows;

type

  pMSR_DATA    =^TMSR_DATA;
  TMSR_DATA    = record
    MSR_LO: DWORD;
    MSR_HI: DWORD;
  end;

  CPUID_RECORD = record
    EAX: DWORD;
    EBX: DWORD;
    ECX: DWORD;
    EDX: DWORD;
  end;


  pIrqClearRec =^TIrqClearRec;
  TIrqClearRec = record
    ClearIrq       : Byte;   // 1 - Irq must be cleared, 0 - not
    TypeOfRegister : Byte;   // 0 - memory, 1 - port
    WideOfRegister : Byte;   // 1 - Byte, 2 - Word, 4 - Double Word
    ReadOrWrite    : Byte;   // 0 - read register to clear Irq, 1 - write
    RegBaseAddress : DWORD;  // Memory or port i/o register base address to clear
    RegOffset: DWORD;  // Register offset
    ValueToWrite   : DWORD;  // Value to write (if ReadOrWrite=1)
  end;

  pDmaBufferRequest = ^TDmaBufferRequest;
  TDmaBufferRequest   = packed record
    LengthOfBuffer : DWORD; // Length in Bytes
    AlignMask      : DWORD; // 0-4K, 1-8K, 3-16K, 7-32K, $0F-64K, $1F-128K
    PhysDmaAddress : DWORD; // returned physical address of DMA buffer
    LinDmaAddress  : Pointer; // returned linear address
    DmaMemHandle   : THANDLE; // returned memory handle (do not use and keep it!)
    Reserved1      : DWORD;
    KernelDmaAddress : DWORD; // do not use and keep it!
    Reserved2      : DWORD;
  end;

  pHDDInfo       =^THDDInfo;
  THDDInfo = packed record
    DoubleTransfer      : DWORD;
    ControllerType      : DWORD;
    BufferSize          : DWORD;
    ECCMode             : DWORD;
    SectorsPerInterrupt : DWORD;
    Cylinders           : DWORD;
    Heads               : DWORD;
    SectorsPerTrack     : DWORD;
    Model               : array [0..40] of Char;
    SerialNumber        : array [0..20] of Char;
    Revision            : array [0..8] of Char;
  end;

  pPortByteFifo  =^TPortByteFifo;
  TPortByteFifo  = record
    PortAddr     : DWORD;
    NumPorts     : DWORD;
    Buffer       : array[1..2] of Byte;
  end;

  pPortWordFifo  =^TPortWordFifo;
  TPortWordFifo  = record
    PortAddr     : DWORD;
    NumPorts     : DWORD;
    Buffer       : array[1..2] of Word;
  end;

  pPortLongFifo  =^TPortLongFifo;
  TPortLongFifo  = record
    PortAddr     : DWORD;
    NumPorts     : DWORD;
    Buffer       : array[1..2] of DWORD;
  end;

type
  TNonBridge = record
    base_address0      : DWORD;
    base_address1      : DWORD;
	  base_address2      : DWORD;
	  base_address3      : DWORD;
	  base_address4      : DWORD;
	  base_address5      : DWORD;
	  CardBus_CIS        : DWORD;
	  subsystem_vendorID : Word;
	  subsystem_deviceID : Word;
	  expansion_ROM      : DWORD;
	  cap_ptr            : Byte;
	  reserved1          : array[1..3] of Byte;
	  reserved2          : DWORD;
	  interrupt_line     : Byte;
	  interrupt_pin      : Byte;
	  min_grant          : Byte;
	  max_latency        : Byte;
	  device_specific    : array[1..48] of DWORD;
    ReservedByVictor   : array[1..5] of DWORD;
  end;

  TBridge = record
    base_address0       : DWORD;
    base_address1       : DWORD;
    primary_bus         : Byte;
    secondary_bus       : Byte;
    subordinate_bus     : Byte;
    secondary_latency   : Byte;
    IO_base_low         : Byte;
    IO_limit_low        : Byte;
    secondary_status    : Word;
    memory_base_low     : Word;
    memory_limit_low    : Word;
    prefetch_base_low   : Word;
    prefetch_limit_low  : Word;
    prefetch_base_high  : DWORD;
    prefetch_limit_high : DWORD;
    IO_base_high        : Word;
    IO_limit_high       : Word;
    reserved2           : DWORD;
    expansion_ROM       : DWORD;
    interrupt_line      : Byte;
    interrupt_pin       : Byte;
    bridge_control      : Word;
    device_specific     : array[1..48] of DWORD;
    ReservedByVictor   : array[1..5] of DWORD;
  end;

type TCardBus = record
    ExCa_base          : DWORD;
	  cap_ptr            : Byte;
	  reserved05         : Byte;
	  secondary_status   : Word;
	  PCI_bus            : Byte;
	  CardBus_bus        : Byte;
	  subordinate_bus    : Byte;
	  latency_timer      : Byte;
	  memory_base0       : DWORD;
	  memory_limit0      : DWORD;
	  memory_base1       : DWORD;
	  memory_limit1      : DWORD;
	  IObase_0low        : Word;
	  IObase_0high       : Word;
	  IOlimit_0low       : Word;
	  IOlimit_0high      : Word;
	  IObase_1low        : Word;
	  IObase_1high       : Word;
	  IOlimit_1low       : Word;
	  IOlimit_1high      : Word;
	  interrupt_line     : Byte;
	  interrupt_pin      : Byte;
    bridge_control     : Word;
    subsystem_vendorID : Word;
    subsystem_deviceID : Word;
    legacy_baseaddr    : DWORD;
    cardbus_reserved   : array[1..14] of DWORD;
    vendor_specific    : array[1..32] of DWORD;
    ReservedByVictor   : array[1..5] of DWORD;
  end;

  pPciCfg =^TPciCfg;
  TPciCfg = record

    vendorID       : Word;
    deviceID       : Word;
    command_reg    : Word;
    status_reg     : Word;
    revisionID     : Byte;
    progIF         : Byte;
    subclass       : Byte;
    classcode      : Byte;
    cacheline_size : Byte;
    latency        : Byte;
    header_type    : Byte;
    BIST           : Byte;
    case Integer of
      0 : (NonBridge : TNonBridge);
      1 : (Bridge    : TBridge);
      2 : (CardBus   : TCardBus);
  end;

  TPciRequestRecord = record
    cfg_mech        : Byte;
    bus_number      : Byte;
    dev_number      : Byte;
    func_number     : Byte;
  end;


  TOnHWInterrupt     = procedure (IRQNumber:WORD); stdcall;
  TRing0Function     = procedure;// stdcall;
  TOnDelphiInterrupt = procedure (TVic : THANDLE; IRQNumber:WORD); stdcall;
  TOnKeystroke       = procedure (scan_code: Byte); stdcall;
  TOnDelphiKeystroke = procedure (TVic : THANDLE; scan_code: Byte); stdcall;

{-------} implementation  {--------}

end.
