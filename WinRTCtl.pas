//  WinRTCtl.pas
//  Copyright 1998 BlueWater Systems
//
//  Global definitions for the WinRT package
//
unit WinRTCtl;

interface
uses
    sysutils,
    Windows;

const
    WINRT_MAXIMUM_SECTIONS = 6;
    LOGICAL_NOT_FLAG    = $1000;
    MATH_SIGNED         = $2000;
            // Dimension type flags
    DIMENSION_CONSTANT  = $1000;
    DIMENSION_ARRAY     = $2000;
    DIMENSION_GLOBAL    = $4000;
    DIMENSION_EXTERN    = $8000;
            // Array Move flags
    ARRAY_MOVE_INDIRECT = $8000;
            // Math MOVE_TO flags
    MATH_MOVE_TO_PORT   = $1000;
    MATH_MOVE_TO_VALUE  = $2000;
    MATH_MOVE_FROM_VALUE= $4000;

    FILE_ANY_ACCESS     = 0;
    FILE_READ_ACCESS    = 1;
    FILE_WRITE_ACCESS   = 2;

    METHOD_BUFFERED     = 0;
    METHOD_IN_DIRECT    = 1;
    METHOD_OUT_DIRECT   = 2;
    METHOD_NEITHER      = 3;

    WINRT_DEVICE_TYPE   = $8000;
    IOCTL_WINRT_PROCESS_BUFFER              = (Cardinal(WINRT_DEVICE_TYPE) shl 16)
                                              or (FILE_ANY_ACCESS shl 14)
                                              or ($800 shl 2) or METHOD_BUFFERED;
    IOCTL_WINRT_PROCESS_BUFFER_DIRECT       = (Cardinal(WINRT_DEVICE_TYPE) shl 16)
                                              or (FILE_ANY_ACCESS shl 14)
                                              or ($801 shl 2) or METHOD_IN_DIRECT;
    IOCTL_WINRT_PROCESS_DMA_BUFFER          = (Cardinal(WINRT_DEVICE_TYPE) shl 16)
                                              or (FILE_ANY_ACCESS shl 14)
                                              or ($802 shl 2) or METHOD_BUFFERED;
    IOCTL_WINRT_PROCESS_DMA_BUFFER_DIRECT   = (Cardinal(WINRT_DEVICE_TYPE) shl 16)
                                              or (FILE_ANY_ACCESS shl 14)
                                              or ($803 shl 2) or METHOD_IN_DIRECT;
    IOCTL_WINRT_GET_CONFIG                  = (Cardinal(WINRT_DEVICE_TYPE) shl 16)
                                              or (FILE_ANY_ACCESS shl 14)
                                              or ($804 shl 2) or METHOD_BUFFERED;
    IOCTL_WINRT_MAP_MEMORY                  = (Cardinal(WINRT_DEVICE_TYPE) shl 16)
                                              or (FILE_ANY_ACCESS shl 14)
                                              or ($806 shl 2) or METHOD_BUFFERED;
    IOCTL_WINRT_UNMAP_MEMORY                = (Cardinal(WINRT_DEVICE_TYPE) shl 16)
                                              or (FILE_ANY_ACCESS shl 14)
                                              or ($807 shl 2) or METHOD_BUFFERED;
    IOCTL_WINRT_AUTOINC_IO                  = (Cardinal(WINRT_DEVICE_TYPE) shl 16)
                                              or (FILE_ANY_ACCESS shl 14)
                                              or ($808 shl 2) or METHOD_BUFFERED;
    IOCTL_WINRT_WAIT_INTERRUPT              = (Cardinal(WINRT_DEVICE_TYPE) shl 16)
                                              or (FILE_ANY_ACCESS shl 14)
                                              or ($809 shl 2) or METHOD_BUFFERED;
    IOCTL_WINRT_SET_INTERRUPT               = (Cardinal(WINRT_DEVICE_TYPE) shl 16)
                                              or (FILE_ANY_ACCESS shl 14)
                                              or ($80A shl 2) or METHOD_IN_DIRECT;
    IOCTL_WINRT_SETUP_DMA_BUFFER            = (Cardinal(WINRT_DEVICE_TYPE) shl 16)
                                              or (FILE_ANY_ACCESS shl 14)
                                              or ($80C shl 2) or METHOD_BUFFERED;
    IOCTL_WINRT_FREE_DMA_BUFFER             = (Cardinal(WINRT_DEVICE_TYPE) shl 16)
                                              or (FILE_ANY_ACCESS shl 14)
                                              or ($80D shl 2) or METHOD_BUFFERED;

                        // commands for WINRT_CONTROL_ITEM command buffer
                        // Command naming convention:
                        //       data size
                        //     B - byte  8 bits,
                        //     W - word 16 bits,
                        //     L - long 32 bits
                        //       port or memory mapped I/O
                        //     P - port or I/O mapped
                        //         (equivalent to x86 inp() functions)
                        //     M - memory mapped
                        //       relative or absolute addressing
                        //     A - absolute addressing
                        //       - no letter is relative addressing
                        //         (relative to the
                        //          Section0/portAddress in the
                        //          registry.)
                        //  Example:  INP_B   port I/O,
                        //                    relative addressing,
                        //                    byte
                        //            INM_WA  memory mapped I/O,
                        //                    absolute addressing,
                        //                    word
                        //
                        //
                        //  Input & Output commands
                        //    port I/O commands
                        //                  param1            param2
    NOP=0;              //  No operation    0                   0
    INP_B=1;            //  input byte      port rel        byte input
    INP_W=2;            //  input word      port rel        word input
    INP_L=3;            //  input long      port rel        long input
    OUTP_B=4;           //  output byte     port rel        byte to output
    OUTP_W=5;           //  output word     port rel        word to output
    OUTP_L=6;           //  output long     port rel        long to output
    INP_BA=7;           //  input byte      port abs        byte input
    INP_WA=8;           //  input word      port abs        word input
    INP_LA=9;           //  input long      port abs        long input
    OUTP_BA=10;         //  output byte     port abs        byte to output
    OUTP_WA=11;         //  output word     port abs        word to output
    OUTP_LA=12;         //  output long     port abs        long to output
                        //    memory mapped I/O commands
                        //                  param1            param2
    INM_B=13;           //  input byte      address rel     byte input
    INM_W=14;           //  input word      address rel     word input
    INM_L=15;           //  input long      address rel     long input
    OUTM_B=16;          //  output byte     address rel     byte to output
    OUTM_W=17;          //  output word     address rel     word to output
    OUTM_L=18;          //  output long     address rel     long to output
    INM_BA=19;          //  input byte      address abs     byte input
    INM_WA=20;          //  input word      address abs     word input
    INM_LA=21;          //  input long      address abs     long input
    OUTM_BA=22;         //  output byte     address abs     byte to output
    OUTM_WA=23;         //  output word     address abs     word to output
    OUTM_LA=24;         //  output long     address abs     long to output
                        //
                            //  Interrupt commands
                            //                  param1            param2
    INTRP_ID_ALWAYS=25;     //  identifies interrupt as always ours.
                            //                  not used    not used
    INTRP_ID_IN=26;         //  inputs value read by INTRP_ID_xxx commands
                            //                  not used    value read in
                            //    Interrupt commands using port I/O
                            //                  param1            param2
    INTRP_ID_IF_SET_PB=27;  //  identifies interrupt if the port value and'ed
                            //    with mask is non-zero (port is byte)
                            //               port rel    mask for set bits
    INTRP_ID_IF_NSET_PB=28; //  identifies interrupt if the port value and'ed
                            //    with mask is zero     (port is byte)
                            //               port rel    mask for not set bits
    INTRP_ID_IF_SET_PW=29;  //  identifies interrupt if the port value and'ed
                            //    with mask is non-zero (port is word)
                            //               port rel    mask for set bits
    INTRP_ID_IF_NSET_PW=30; //  identifies interrupt if the port value and'd
                            //    with mask is zero     (port is word)
                            //               port rel    mask for not set bits
    INTRP_ID_IF_SET_PL=31;  //  identifies interrupt if the port value and'd
                            //    with mask is non-zero (port is long)
                            //               port rel    mask for set bits
    INTRP_ID_IF_NSET_PL=32; //  identifies interrupt if the port value and'd
                            //    with mask is zero     (port is long)
                            //               port rel    mask for not set bits
    INTRP_ID_IF_EQ_PB=33;   //  identifies interrupt if the port value equals value
                            //                 port rel    value(byte)
    INTRP_ID_IF_GT_PB=34;   //  identifies interrupt if the port value > value
                            //                 port rel    value(byte)
    INTRP_ID_IF_LT_PB=35;   //  identifies interrupt if the port value < value
                            //                 port rel    value(byte)
    INTRP_ID_IF_EQ_PW=36;   //  identifies interrupt if the port value equals value
                            //                 port rel    value(word)
    INTRP_ID_IF_GT_PW=37;   //  identifies interrupt if the port value > value
                            //                 port rel    value(word)
    INTRP_ID_IF_LT_PW=38;   //  identifies interrupt if the port value < value
                            //                 port rel    value(word)
    INTRP_ID_IF_EQ_PL=39;   //  identifies interrupt if the port value equals value
                            //                 port rel    value(long)
    INTRP_ID_IF_GT_PL=40;   //  identifies interrupt if the port value > value
                            //                 port rel    value(long)
    INTRP_ID_IF_LT_PL=41;   //  identifies interrupt if the port value < value
                            //                 port rel    value(long)
    INTRP_CLEAR_NOP=42;     //  clears interrupt with no operation
                            //                  not used    not used
    INTRP_CLEAR_IN=43;      //  inputs value read by INTRP_CLEAR_Rxxx commands
                            //                  not used    value read in
    INTRP_CLEAR_W_PB=44;    //  clears interrrupt by writing value to port(byte)
                            //                  port rel    byte to output
    INTRP_CLEAR_W_PW=45;    //  clears interrrupt by writing value to port(word)
                            //                  port rel    word to output
    INTRP_CLEAR_W_PL=46;    //  clears interrrupt by writing value to port(long)
                            //                  port rel    long to output
    INTRP_CLEAR_R_PB=47;    //  clears interrrupt by reading port(byte)
                            //                  port rel    byte input
    INTRP_CLEAR_R_PW=48;    //  clears interrrupt by reading port(word)
                            //                  port rel    word input
    INTRP_CLEAR_R_PL=49;    //  clears interrrupt by reading port(long)
                            //                  port rel    long input
    INTRP_CLEAR_RMW_SET_PB=50;//  clears interrupt with read modify write operation.
                              //  port is input, or'd with value and result is output
                              //            port rel    byte mask
    INTRP_CLEAR_RMW_SET_PW=51;//  clears interrupt with read modify write operation.
                              //  port is input, or'd with value and result is output
                              //            port rel    word mask
    INTRP_CLEAR_RMW_SET_PL=52;//  clears interrupt with read modify write operation.
                              //  port is input, or'd with value and result is output
                              //            port rel    long mask
    INTRP_CLEAR_RMW_NSET_PB=53;//  clears interrupt with read modify write operation.
                               //  port is input, and'd with value and result is output
                               //           port rel    byte mask
    INTRP_CLEAR_RMW_NSET_PW=54;//  clears interrupt with read modify write operation.
                               //  port is input, and'd with value and result is output
                               //           port rel    word mask
    INTRP_CLEAR_RMW_NSET_PL=55;//  clears interrupt with read modify write operation.
                               //  port is input, and'd with value and result is output
                               //           port rel    long mask
    INTRP_ID_IF_SET_PBA=56; //  identifies interrupt if the port value and'ed
                            //    with mask is non-zero (port is byte)
                            //              port abs    mask for set bits
    INTRP_ID_IF_NSET_PBA=57;//  identifies interrupt if the port value and'ed
                            //    with mask is zero     (port is byte)
                            //              port abs    mask for not set bits
    INTRP_ID_IF_SET_PWA=58; //  identifies interrupt if the port value and'ed
                            //    with mask is non-zero (port is word)
                            //              port abs    mask for set bits
    INTRP_ID_IF_NSET_PWA=59;//  identifies interrupt if the port value and'd
                            //    with mask is zero     (port is word)
                            //              port abs    mask for not set bits
    INTRP_ID_IF_SET_PLA=60; //  identifies interrupt if the port value and'd
                            //    with mask is non-zero (port is long)
                            //              port abs    mask for set bits
    INTRP_ID_IF_NSET_PLA=61;//  identifies interrupt if the port value and'd
                            //    with mask is zero     (port is long)
                            //              port abs    mask for not set bits
    INTRP_ID_IF_EQ_PBA=62;  //  identifies interrupt if the port value equals value
                            //                port abs    value(byte)
    INTRP_ID_IF_GT_PBA=63;  //  identifies interrupt if the port value > value
                            //                port abs    value(byte)
    INTRP_ID_IF_LT_PBA=64;  //  identifies interrupt if the port value < value
                            //                port abs    value(byte)
    INTRP_ID_IF_EQ_PWA=65;  //  identifies interrupt if the port value equals value
                            //                port abs    value(word)
    INTRP_ID_IF_GT_PWA=66;  //  identifies interrupt if the port value > value
                            //                port abs    value(word)
    INTRP_ID_IF_LT_PWA=67;  //  identifies interrupt if the port value < value
                            //                port abs    value(word)
    INTRP_ID_IF_EQ_PLA=68;  //  identifies interrupt if the port value equals value
                            //                port abs    value(long)
    INTRP_ID_IF_GT_PLA=69;  //  identifies interrupt if the port value > value
                            //                port abs    value(long)
    INTRP_ID_IF_LT_PLA=70;  //  identifies interrupt if the port value < value
                            //                port abs    value(long)
    INTRP_CLEAR_W_PBA=71;   //  clears interrrupt by writing value to port(byte)
                            //                 port abs    byte to output
    INTRP_CLEAR_W_PWA=72;   //  clears interrrupt by writing value to port(word)
                            //                 port abs    word to output
    INTRP_CLEAR_W_PLA=73;   //  clears interrrupt by writing value to port(long)
                            //                 port abs    long to output
    INTRP_CLEAR_R_PBA=74;   //  clears interrrupt by reading port(byte)
                            //                 port abs    byte input
    INTRP_CLEAR_R_PWA=75;   //  clears interrrupt by reading port(word)
                            //                 port abs    word input
    INTRP_CLEAR_R_PLA=76;   //  clears interrrupt by reading port(long)
                            //                 port abs    long input
    INTRP_CLEAR_RMW_SET_PBA=77; //  clears interrupt with read modify write operation.
                                //  port is input, or'd with value and result is output
                                //          port abs    byte mask
    INTRP_CLEAR_RMW_SET_PWA=78; //  clears interrupt with read modify write operation.
                                //  port is input, or'd with value and result is output
                                //          port abs    word mask
    INTRP_CLEAR_RMW_SET_PLA=79; //  clears interrupt with read modify write operation.
                                //  port is input, or'd with value and result is output
                                //          port abs    long mask
    INTRP_CLEAR_RMW_NSET_PBA=80;//  clears interrupt with read modify write operation.
                                //  port is input, and'd with value and result is output
                                //          port abs    byte mask
    INTRP_CLEAR_RMW_NSET_PWA=81;//  clears interrupt with read modify write operation.
                                //  port is input, and'd with value and result is output
                                //          port abs    word mask
    INTRP_CLEAR_RMW_NSET_PLA=82;//  clears interrupt with read modify write operation.
                                //  port is input, and'd with value and result is output
                                //          port abs    long mask
                           //
                           //  Interrupt commands
                           //    using memory mapped I/O
                           //               param1            param2
    INTRP_ID_IF_SET_MB=83; //  identifies interrupt if the address value and'ed
                           //    with mask is non-zero (address is byte)
                           //               address rel mask for set bits
    INTRP_ID_IF_NSET_MB=84;//  identifies interrupt if the address value and'ed
                           //    with mask is zero     (address is byte)
                           //               address rel mask for not set bits
    INTRP_ID_IF_SET_MW=85; //  identifies interrupt if the address value and'ed
                           //    with mask is non-zero (address is word)
                           //               address rel mask for set bits
    INTRP_ID_IF_NSET_MW=86;//  identifies interrupt if the address value and'd
                           //    with mask is zero     (address is word)
                           //               address rel mask for not set bits
    INTRP_ID_IF_SET_ML=87; //  identifies interrupt if the address value and'd
                           //    with mask is non-zero (address is long)
                           //               address rel mask for set bits
    INTRP_ID_IF_NSET_ML=88;//  identifies interrupt if the address value and'd
                           //    with mask is zero     (address is long)
                           //               address rel mask for not set bits
    INTRP_ID_IF_EQ_MB=89;   //  identifies interrupt if the memory value equals value
                            //                 address rel    value(byte)
    INTRP_ID_IF_GT_MB=90;   //  identifies interrupt if the memory value > value
                            //                 address rel value(byte)
    INTRP_ID_IF_LT_MB=91;   //  identifies interrupt if the memory value < value
                            //                 address rel value(byte)
    INTRP_ID_IF_EQ_MW=92;   //  identifies interrupt if the memory value equals value
                            //                 address rel    value(word)
    INTRP_ID_IF_GT_MW=93;   //  identifies interrupt if the memory value > value
                            //                 address rel value(word)
    INTRP_ID_IF_LT_MW=94;   //  identifies interrupt if the memory value < value
                            //                 address rel value(word)
    INTRP_ID_IF_EQ_ML=95;   //  identifies interrupt if the memory value equals value
                            //                 address rel    value(long)
    INTRP_ID_IF_GT_ML=96;   //  identifies interrupt if the memory value > value
                            //                 address rel value(long)
    INTRP_ID_IF_LT_ML=97;   //  identifies interrupt if the memory value < value
                            //                 address rel value(long)
    INTRP_CLEAR_W_MB=98;    //  clears interrrupt by writing value to address(byte)
                            //                  address rel byte to output
    INTRP_CLEAR_W_MW=99;    //  clears interrrupt by writing value to address(word)
                            //                 address rel word to output
    INTRP_CLEAR_W_ML=100;   //  clears interrrupt by writing value to address(long)
                            //                 address rel long to output
    INTRP_CLEAR_R_MB=101;   //  clears interrrupt by reading address(byte)
                            //                 address rel byte input
    INTRP_CLEAR_R_MW=102;   //  clears interrrupt by reading address(word)
                            //                 address rel word input
    INTRP_CLEAR_R_ML=103;   //  clears interrrupt by reading address(long)
                            //                 address rel long input
    INTRP_CLEAR_RMW_SET_MB=104; //  clears interrupt with read modify write operation.
                                //  address is input, or'd with value and result is output
                                //          address rel byte mask
    INTRP_CLEAR_RMW_SET_MW=105; //  clears interrupt with read modify write operation.
                                //  address is input, or'd with value and result is output
                                //          address rel word mask
    INTRP_CLEAR_RMW_SET_ML=106; //  clears interrupt with read modify write operation.
                                //  address is input, or'd with value and result is output
                                //          address rel long mask
    INTRP_CLEAR_RMW_NSET_MB=107;//  clears interrupt with read modify write operation.
                                //  address is input, and'd with value and result is output
                                //          address rel byte mask
    INTRP_CLEAR_RMW_NSET_MW=108;//  clears interrupt with read modify write operation.
                                //  address is input, and'd with value and result is output
                                //          address rel word mask
    INTRP_CLEAR_RMW_NSET_ML=109;//  clears interrupt with read modify write operation.
                                //  address is input, and'd with value and result is output
                                //          address rel long mask
    INTRP_ID_IF_SET_MBA=110;    //  identifies interrupt if the address value and'ed
                                //    with mask is non-zero (address is byte)
                                //              address abs mask for set bits
    INTRP_ID_IF_NSET_MBA=111;   //  identifies interrupt if the address value and'ed
                                //    with mask is zero     (address is byte)
                                //              address abs mask for not set bits
    INTRP_ID_IF_SET_MWA=112;    //  identifies interrupt if the address value and'ed
                                //    with mask is non-zero (address is word)
                                //              address abs mask for set bits
    INTRP_ID_IF_NSET_MWA=113;   //  identifies interrupt if the address value and'd
                                //    with mask is zero     (address is word)
                                //              address abs mask for not set bits
    INTRP_ID_IF_SET_MLA=114;    //  identifies interrupt if the address value and'd
                                //    with mask is non-zero (address is long)
                                //              address abs mask for set bits
    INTRP_ID_IF_NSET_MLA=115;   //  identifies interrupt if the address value and'd
                                //    with mask is zero     (address is long)
                                //              address abs mask for not set bits
    INTRP_ID_IF_EQ_MBA=116; //  identifies interrupt if the memory value equals value
                            //                address abs    value(byte)
    INTRP_ID_IF_GT_MBA=117; //  identifies interrupt if the memory value > value
                            //                address abs value(byte)
    INTRP_ID_IF_LT_MBA=118; //  identifies interrupt if the memory value < value
                            //                address abs value(byte)
    INTRP_ID_IF_EQ_MWA=119; //  identifies interrupt if the memory value equals value
                            //                address abs    value(word)
    INTRP_ID_IF_GT_MWA=120; //  identifies interrupt if the memory value > value
                            //                address abs value(word)
    INTRP_ID_IF_LT_MWA=121; //  identifies interrupt if the memory value < value
                            //                address abs value(word)
    INTRP_ID_IF_EQ_MLA=122; //  identifies interrupt if the memory value equals value
                            //                address abs    value(long)
    INTRP_ID_IF_GT_MLA=123; //  identifies interrupt if the memory value > value
                            //                address abs value(long)
    INTRP_ID_IF_LT_MLA=124; //  identifies interrupt if the memory value < value
                            //                address abs value(long)
    INTRP_CLEAR_W_MBA=125;  //  clears interrrupt by writing value to address(byte)
                            //                 address abs byte to output
    INTRP_CLEAR_W_MWA=126;  //  clears interrrupt by writing value to address(word)
                            //                 address abs word to output
    INTRP_CLEAR_W_MLA=127;  //  clears interrrupt by writing value to address(long)
                            //                 address abs long to output
    INTRP_CLEAR_R_MBA=128;  //  clears interrrupt by reading address(byte)
                            //                 address abs byte input
    INTRP_CLEAR_R_MWA=129;  //  clears interrrupt by reading address(word)
                            //                 address abs word input
    INTRP_CLEAR_R_MLA=130;  //  clears interrrupt by reading address(long)
                            //                 address abs long input
    INTRP_CLEAR_RMW_SET_MBA=131; //  clears interrupt with read modify write operation.
                                 //  address is input, or'd with value and result is output
                                 //          address abs byte mask
    INTRP_CLEAR_RMW_SET_MWA=132; //  clears interrupt with read modify write operation.
                                 //  address is input, or'd with value and result is output
                                 //          address abs word mask
    INTRP_CLEAR_RMW_SET_MLA=133; //  clears interrupt with read modify write operation.
                                 //  address is input, or'd with value and result is output
                                 //          address abs long mask
    INTRP_CLEAR_RMW_NSET_MBA=134;//  clears interrupt with read modify write operation.
                                 //  address is input, and'd with value and result is output
                                 //          address abs byte mask
    INTRP_CLEAR_RMW_NSET_MWA=135;//  clears interrupt with read modify write operation.
                                 //  address is input, and'd with value and result is output
                                 //          address abs word mask
    INTRP_CLEAR_RMW_NSET_MLA=136;//  clears interrupt with read modify write operation.
                                 //  address is input, and'd with value and result is output
                                 //          address abs long mask
                            //
                            // Miscellaneous commands
                            //
    _DELAY=137;             //  delay thread for count milliseconds (can NOT be used
                            //  in a wait for interrupt request)
                            //                  0           count in millisecond units
    _STALL=138;             //  stall processor for count microseconds (to follow
                            //  Microsoft's driver guidelines you should always
                            //  keep this value as small as possible and Never greater
                            //  than 50 microseconds.)
                            //                  0           count in microseconds

                            // Logical and Math items
    LOGICAL_IF = $10000;    //  logical If
                            //   PortHi - condition type
                            //   PortLo - relative jump on not condition
                            //   ValueHi - condition var 1 index
                            //   ValueLo - condition var 2 index
    DIM=$10001;             //  shadow variable dimension
                            //   PortHi - data size (1,2,4) plus flags
                            //   PortLo - number of entries
                            //   Value  - data entries
    JUMP_TO=$10002;         //  jump to
                            //   Port   - relative index
    MATH=$10003;            //  math operation
                            //   PortHi - operation type
                            //   PortLo - result index
                            //   ValueHi - operation var 1 index
                            //   ValueLo - operation var 2 index
    _WHILE=$10004;          //  while loop
                            //   PortHi - condition type
                            //   PortLo - relative jump on not condition
                            //   ValueHi - condition var 1 index
                            //   ValueLo - condition var 2 index
    ARRAY_MOVE=$10005;      //  move array item
                            //   PortHi - index of lvalue (plus flags)
                            //   PortLo - location of lvalue
                            //   ValueHi - index of rvalue (plus flags)
                            //   ValueLo - location of rvalue (plus flags)
    ARRAY_MOVE_TO=$10006;   //  move array item to port or value
                            //  combination of DIM, ARRAY_MOVE,
                            //  and MATH [MOVE_TO_PORT | MOVE_TO_VALUE]
                            //   PortHi - not used (allocated by backend)
                            //   PortLo - not used
                            //   ValueHi - index of rvalue (plus flags)
                            //   ValueLo - location of rvalue (plus flags)
    ARRAY_MOVE_FROM=$10007; //  MATH_MOVE_FROM_VALUE from temp to array
    INTERNAL_ELSE=$10008;   //  reserved
    INTERNAL_TAG=$10009;    //  reserved
    ISR_SETUP=$1000A;       //  Marks the beginning of the ISR setup code
                            //   Port - not used
                            //   Value - not used
    BEGIN_ISR=$1000B;       //  Marks beginning of ISR
                            //   Port - not used
                            //   Value - not used
    BEGIN_DPC=$1000C;       //  Marks beginning of DPC
                            //   Port - not used
                            //   Value - not used
    WINRT_BLOCK_ISR=$1000D; //  Mark section for synch with ISR
                            //   Port - not used
                            //   Value - not used
    WINRT_RELEASE_ISR=$1000E;//  Mark end of section for synch with ISR
                             //   Port - not used
                             //   Value - not used
    DMA_START=$1000F;       //  DMA Start Operation - causes the DMA to be started for slave DMA
                            //   Port - TRUE for a transfer from the host to the device
                            //          FALSE for a transfer from the device to the host
                            //   Value - location and flags of number of bytes rvalue
    DMA_FLUSH=$10010;       //  DMA Flush Operation - causes the flush and frees adapter channel
                            //   Port - not used
                            //   Value - not used
    WINRT_GLOBAL=$10011;    //  WinRT Global name
                            //   Port - length of name in bytes
                            //   Value - not used
    WINRT_EXTERN=$10012;    //  WinRT Global name
                            //   Port - length of name in bytes
                            //   Value - not used
    SET_EVENT=$10013;       //  Set an event
                            //   Port - Handle to the event returned in the pointer passed
                            //          to WinRTCreateEvent
                            //   Value - not used
    SCHEDULE_DPC=$10014;    //  Schedule a DPC
                            //   Port - not used
                            //   Value - not used
    REJECT_INTERRUPT=$10015;//  Reject an interrupt from within the ISR
                            //   Port - not used
                            //   Value - not used
    STOP_INTERRUPT=$10016;  //  Remove a repeating interrupt service routine
                            //   Port - not used
                            //   Value - not used
    SETUP_TIMER=$10017;     //  Establish a repeating or one shot timer
                            //   Port - Milliseconds
                            //   Value - 0 if one shot, non-zero if repeating
    START_TIMER=$10018;     //  Start a repeating or one shot timer
                            //   Port - not used
                            //   Value - not used
    STOP_TIMER=$10019;      //  Return from a timer
                            //   Port - not used
                            //   Value - not used
    WINRT_TRACE=$1001A;     //  Print a string to the WinRT Debug Buffer
                            //   Port    - value to use in print
                            //   ValueHi - Bit number in Debug bitmask to AND to determine
                            //          whether this string should be printed or not
                            //   ValueLo - number of characters in the string that follows
                            //          the control item containing this command

type
    pbyte       = ^byte;
    pword       = ^word;
    plong       = ^longint;

        // Configuration item for output from IOCTL_WINRT_GET_CONFIG
    PWINRT_FULL_CONFIGURATION = ^tWINRT_FULL_CONFIGURATION;
    tWINRT_FULL_CONFIGURATION = record
        Reserved : longint;
        MajorVersion,
        MinorVersion : word;
        BusType,
        BusNumber,
        PortSections,
        MemorySections,
        InterruptVector,
        InterruptLevel : longint;
        PortStart : array [0..WINRT_MAXIMUM_SECTIONS-1] of longint;
        PortLength : array [0..WINRT_MAXIMUM_SECTIONS-1] of longint;
        MemoryStart : array [0..WINRT_MAXIMUM_SECTIONS-1] of longint;
        MemoryLength : array [0..WINRT_MAXIMUM_SECTIONS-1] of longint;
        MemoryStart64 : array [0..(WINRT_MAXIMUM_SECTIONS * 2) - 1] of longint;
        end;    {WINRT_FULL_CONFIGURATION}

        // Logical conditions for LOGICAL_IF. WHILE and END_ISR statements
        // and operations for MATH statements
    tWINRT_LOGIC_MATH = (
        EQUAL_TO,
        NOT_EQUAL_TO,
        GREATER_THAN,
        GREATER_THAN_EQUAL,
        LESS_THAN,
        LESS_THAN_EQUAL,
        LOGICAL_AND,
        LOGICAL_OR,
        BITWISE_AND,
        BITWISE_OR,
        EXCLUSIVE_OR,
        LOGICAL_NOT,
        BITWISE_NOT,
        MOVE_TO,
        ADD,
        SUBTRACT,
        MULTIPLY,
        DIVIDE,
        MODULUS
    );  {WINRT_LOGIC_MATH}

        // Process buffer item for input to IOCTL_WINRT_PROCESS_BUFFER
        //                              and IOCTL_WINRT_WAIT_ON_INTERRUPT
    PWINRT_CONTROL_ITEM = ^tWINRT_CONTROL_ITEM;
    tWINRT_CONTROL_ITEM = record
        WINRT_COMMAND : longint;    // command to perform
        port,                       // port address
        value : longint;            // input or output data
        end;

    PCONTROL_ITEM_ex    = ^tCONTROL_ITEM_ex;
    tCONTROL_ITEM_ex    = record
        WINRT_COMMAND,              // command to perform
        port,                       // port address
        value       : integer;      // input or output data
        dsize   : integer;      // size of variable waiting for data
        end;

    pWINRT_CONTROL_array    = ^tWINRT_CONTROL_array;                
    tWINRT_CONTROL_array    = array[0..1000] of tWINRT_CONTROL_ITEM;        

        // Map memory specification for input to IOCTL_WINRT_MAP_MEMORY
    PWINRT_MEMORY_MAP = ^tWINRT_MEMORY_MAP;
    tWINRT_MEMORY_MAP = record
        address : pointer;                // physical address to be mapped
        length : longint;                 // number of bytes to be mapped (>0)
        end;

        // Auto Incrementing I/O buffer item for input to IOCTL_WINRT_AUTOINC_IO.
        //  The output buffer is placed in the union value.
    PWINRT_AUTOINC_ITEM = ^tWINRT_AUTOINC_ITEM;
    tWINRT_AUTOINC_ITEM = record
        command         : longint;      // command to perform - eg OUTP_B, INP_WA
        port            : longint;      // port address
        case integer of
            0:(byteval	: byte);
            1:(wordval	: word);
            2:(longval	: longint)
        end;

    PWINRT_DMA_BUFFER_INFORMATION = ^tWINRT_DMA_BUFFER_INFORMATION;
    tWINRT_DMA_BUFFER_INFORMATION = record
        pVirtualAddress : PByteArray;  // virtual address of DMA common buffer
        Length : longint;           // length of DMA common buffer
        LogicalAddressHi,
        LogicalAddressLo : integer; // logical address of DMA common buffer
        end;

    PINTERFACE_TYPE = ^tINTERFACE_TYPE;
    tINTERFACE_TYPE = (
        Internal,
        Isa,
        Eisa,
        MicroChannel,
        TurboChannel,
        PCIBus,
        VMEBus,
        NuBus,
        PCMCIABus,
        CBus,
        MPIBus,
        MPSABus,
        MaximumInterfaceType
    );  {INTERFACE_TYPE}

        // tStack keeps the position of the active (not closed) _While or _If/_Else
        // there is one stack structure for all _While's and another for all _IF/_Else
    tStack	= record
        data        : array[1..8] of integer;			// up to 8 pending _While's or _If's allowed
        sp          : integer;
        end;

const
    NOVALUE     = pointer(-1);

implementation

end.
