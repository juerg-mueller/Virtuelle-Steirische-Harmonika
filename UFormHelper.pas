unit UFormHelper;

interface

uses
  Forms, Windows;

var
  Sustain_: boolean = false; // midi keyboard flag
  iVirtualMidi: integer = -1;
  shiftIsPush: boolean = true;

procedure ProcessMessages;
procedure ErrMessage(const err: string);
function Warning(const warn: string): cardinal;

function ShiftUsed: boolean;


implementation

procedure ProcessMessages;
begin
  Application.ProcessMessages;
end;

procedure ErrMessage(const err: string);
begin
  Application.MessageBox(PChar(err), 'Error', MB_OK);
end;

function Warning(const warn: string): cardinal;
begin
  result := Application.MessageBox(PChar(warn), 'Warning', MB_YESNO);
end;

function ShiftUsed: boolean;
begin
  result := (GetKeyState(vk_capital) = 1) or
            (GetKeyState(vk_shift) < 0) or
            Sustain_;
  result := result = shiftIsPush;
end;

end.
