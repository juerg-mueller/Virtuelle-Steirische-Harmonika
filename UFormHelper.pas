unit UFormHelper;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$ifdef FPC}
  LCLIntf, LCLType, LMessages,
{$else}
  Types, Windows,
{$endif}
  Forms;

var
  Sustain_: boolean = false; // midi keyboard flag
  iVirtualMidi: integer = -1;
  shiftIsPush: boolean = true;

  RunningWine: boolean = false;


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

{$ifdef dcc}

function IsRunningInWine: boolean;
type
  TWineVers = function: PAnsiChar; cdecl;
var
  hnd: HModule;
  pwine_get_version: TWineVers;
begin
  hnd := GetModuleHandle('ntdll.dll');
  pwine_get_version := nil;
  if (hnd <> 0) then
    pwine_get_version := GetProcAddress(hnd, 'wine_get_version');
  result := @pwine_get_version <> nil;
{$if defined(CONSOLE)}
  if result then
    writeln('wine version: ', pwine_get_version);
{$endif}
  RunningWine := result;
end;

initialization
  IsRunningInWine;

finalization

{$endif}

end.
