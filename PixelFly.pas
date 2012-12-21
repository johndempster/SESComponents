unit PixelFly;

interface

type

TINITBOARD = function(
             Board : Integer ;
             var Handle : Integer ) : Integer ;

TINITBOARDP = function(
             Board : Integer ;
             var Handle : Integer ) : Integer ;


TCLOSEBOARD = function(
              var Handle : Integer ) : Integer ;

TRESETBOARD = function(
              Handle : Integer) : Integer ;


TGETBOARDPAR = function(
               Handle : Integer ;
               var Buf : Array of Char ;
               Len : Integer ) : Integer ;


TSETMODE = function(
           Handle : Integer ;
           mode : Integer ;
           explevel : Integer ;
           exptime : Integer ;
           hbin : Integer ;
           vbin : Integer ;
           gain : Integer ;
           offset : Integer ;
           bit_pix : Integer ;
           shift  : Integer
           ) : Integer ;

TWRRDORION = function(
             Handle : Integer ;
             cmnd : Integer ;
             var Data : Integer
             ) : Integer ;

TSET_EXPOSURE = function(
                Handle : Integer ;
                Time : Integer
                ) : Integer ;


TTRIGGER_CAMERA = function(
                  Handle : Integer) : Integer ;

TSTART_CAMERA = function(
                Handle : Integer
                ) : Integer ;

TSTOP_CAMERA = function(
                Handle : Integer
                ) : Integer ;

TGETSIZES = function(
            Handle : Integer ;
            var ccdxsize : Integer ;
            var ccdysize : Integer ;
            var actualxsize : Integer ;
            var actualysize : Integer ;
            var bit_pix : Integer
            ) : Integer ;


TREADTEMPERATURE = function(
                   Handle : Integer ;
                   var ccd : Integer
                   ) : Integer ;


TREADVERSION = function(
               Handle : Integer ;
               typ : Integer ;
               var Vers : Array of Char ;
               len : Integer
               ) : Integer ;


TGETBUFFER_STATUS = function(
                    Handle : Integer ;
                    bufnr : Integer ;
                    mode : Integer ;
                    var stat : Integer ;
                    len : Integer
                    ) : Integer ;

TADD_BUFFER_TO_LIST = function(
                      Handle : Integer ;
                      bufnr : Integer ;
                      size : Integer ;
                      offset : Integer ;
                      data : Integer ;
                      ) : Integer ;


TREMOVE_BUFFER_FROM_LIST = function(
                           Handle : Integer ;
                           bufnr  : Integer ;
                           ) : Integer ;


TALLOCATE_BUFFER = function(
                   Handle : Integer,
                   var bufnr : Integer ;
                   var size  : Integer
                   ) : Integer ;


TFREE_BUFFER = function(
               Handle : Integer ;
               int bufnr : Integer
               ) : Integer ;


TSETBUFFER_EVENT = function(
                   Handle : Integer ;
                   bufnr : Integer ;
                   var hPicEvent : Integer ;
                   ) : Integer ;


TMAP_BUFFER = function(
              Handle : Integer ;
              int bufnr : Integer ;
              int size : Integer ;
              int offset : Integer ;
              var linadr : Pointer
              ) : Integer ;

TUNMAP_BUFFER = function(
                Handle : Integer ;
                bufnr  : Integer
                ) : Integer ;


TSETORIONINT = function(
               Handle : Integer ;
               bufnr : Integer ;
               mode : Integer ;
               var Array of Byte ;
               len : Integer
               ) : Integer ;


TREADEEPROM = function(
              Handle : Integer,
              int mode : Integer ;
              int adr : Integer ;
              var data : Byte
              ) : Integer ;

TWRITEEEPROM = function(
              Handle : Integer ;
              int mode : Integer ;
              int adr : Integer ;
              var data : Byte
              ) : Integer ;


TSETTIMEOUTS = function(
               Handle : Integer ;
               DWORD dman : Cardinal ;
               DWORD proc : Cardinal ;
               DWORD head : Cardinal
               ) : Integer ;

TSETDRIVER_EVENT = function(
                   Handle : Integer ;
                   int mode : Integer ;
                   var hHeadEvent : Integer ;
                   ) : Integer ;


implementation

end.
