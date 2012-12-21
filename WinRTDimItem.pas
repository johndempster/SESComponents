//  WinRTDimItem.pas
//  Copyright 1998 BlueWater Systems
//
//  Implementation of classes to keep track of shadow variables.
//
unit WinRTDimItem;

interface
uses
    Windows,
    WinRTCtl;

type
    tDimItem        = class
        fListNo     : integer;
        fData       : pointer;
        fsize       : integer;
        Constructor create(ListNo : pointer; var data; size : integer);
        Procedure Get(var buff : tWINRT_CONTROL_array); virtual;
        Procedure Put(var buff : tWINRT_CONTROL_array); virtual;
        end;

    tDimStrItem = class(tDimItem)
        Constructor create(ListNo : pointer; var s : string; size : integer);
        Procedure Get(var buff : tWINRT_CONTROL_array); override;
        Procedure Put(var buff : tWINRT_CONTROL_array); override;
        end;

implementation
var
    DimStrItemsav   : tDimStrItem;

{ ---------------------------------------------------------------------------- }
{                   tDimItem methods                                           }
{ ---------------------------------------------------------------------------- }
    // tDimItem.create - constructor for the dimitem
    // Inputs:  ListNo - pseudo pointer to a shadow variable
    //          Data - Pascal variable being shadowed
    //          size - size of the Pascal variable, in bytes
    // Outputs: none
Constructor tDimItem.create(ListNo : pointer; var Data; size : integer);
begin
    inherited create;
    fListNo := integer(ListNo);
    fData := @Data;
    fsize := size
    end;    { create }

    // tDimItem.Get - copy data from a WINRT_CONTROL_array into the pascal variable
    // Inputs:  buff - the buffer to copy data from
    // Outputs: none
Procedure tDimItem.Get(var buff : tWINRT_CONTROL_array);
begin
    system.move(buff[fListNo].value, fData^, fsize);
    end;    { Get }

    // tDimItem.Put - copy data from the Pascal variable into a WINRT_CONTROL_array
    // Inputs:  buff - buffer to copy data into
    // Outputs: none
Procedure tDimItem.Put(var buff : tWINRT_CONTROL_array);
begin
    system.move(fData^, buff[fListNo].value, fsize);
    end;    { Put }

{ --------------------------------------------------------------------------- }
{                               tDimStrItem methods                           }
{ --------------------------------------------------------------------------- }

    // tDimStrItem.create - constructor for the tDimStrItem class
    // Inputs:  ListNo - pseudo pointer to the shadow variable
    //          s - Pascal string to be shadowed
    //          size - length of the string
    // Outputs: none
Constructor tDimStrItem.create(ListNo : pointer; var s : string; size : integer);
begin
    inherited create(ListNo, pointer(s), size);
    DimStrItemsav := self;
    end;    { create }

    // tDimStrItem.Get - copy data from a WINRT_CONTROL_array into the pascal variable
    // Inputs:  buff - the buffer to copy data from
    // Outputs: none
Procedure tDimStrItem.Get(var buff : tWINRT_CONTROL_array);
var
    arrayp  : pchar;
begin
    arrayp := pchar(@buff[flistNo].value);
    arrayp[fsize] := #0;
    string(fdata^) := arrayp;
    end;    { Get }

    // tDimStrItem.Put - copy data from the Pascal variable into a WINRT_CONTROL_array
    // Inputs:  buff - buffer to copy data into
    // Outputs: none
Procedure tDimStrItem.Put(var buff : tWINRT_CONTROL_array);
begin
    if pointer(fdata^) <> nil then          { nothing to move if an empty string }
        system.move(pointer(fdata^)^, buff[flistNo].value, fsize);
    end;    { Put }

end.
