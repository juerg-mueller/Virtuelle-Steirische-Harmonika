//
// Copyright (C) 2020 Jürg Müller, CH-5524
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program. If not, see http://www.gnu.org/licenses/ .
//

unit UMyMidiStream;

{$ifdef FPC}
  {$MODE Delphi}
{$endif}

interface

uses
  SysUtils, Classes, Types,
  UMyMemoryStream, UMidiEvent;
type

  TMyMidiStream = class(TMyMemoryStream)
  public
    time: TDateTime;
    MidiHeader: TMidiHeader;
    ChunkSize: Cardinal;
    InPull: boolean;

    function ReadByte: byte;
    procedure StartMidi;
    procedure MidiWait(Delay: integer);
    procedure WriteVariableLen(c: cardinal);
  {$if defined(CONSOLE)}
    function Compare(Stream: TMyMidiStream): integer;
  {$endif}
    class function IsEndOfTrack(const d: TInt4): boolean;
  end;

implementation

procedure TMyMidiStream.MidiWait(Delay: integer);
var
  NewTime: TDateTime;
begin
  if (Delay > 0) and (MidiHeader.Details.DeltaTimeTicks > 0) then
  begin
    Delay := trunc(2*Delay*192.0 / MidiHeader.Details.DeltaTimeTicks);
    if Delay > 2000 then
      Delay := 1000;
{$if false}
  if Delay > 16 then
      dec(Delay, 16)
    else
      Delay := 1;  
    
    Sleep(Delay);
{$else}
    NewTime := time + round(Delay/(24.0*3600*1000.0));
    while now < NewTime do
      Sleep(1);
    time := NewTime;
{$endif}
  end;
end;

procedure TMyMidiStream.StartMidi;
begin
  time := now;
end;

function TMyMidiStream.ReadByte: byte;
begin
  result := inherited;
  if ChunkSize > 0 then
    dec(ChunkSize);  
end;

{$if defined(CONSOLE)}
function TMyMidiStream.Compare(Stream: TMyMidiStream): integer;
var
  b1, b2: byte;
  Err: integer;
begin
  result := 0;
  Err := 0;
  repeat
    if (result >= Size) and (result >= Stream.Size) then
      break;
    b1:= GetByte(result);
    b2 := Stream.GetByte(result);
    if (b1 <> b2) then
    begin
      system.writeln(Format('%x (%d): %d   %d', [result, result, b1, b2]));
      inc(Err);
    end;
     // break;
    inc(result);
  until false;
  system.writeln('Err: ', Err);
end;
{$endif}

procedure TMyMidiStream.WriteVariableLen(c: cardinal);
var
  buffer: cardinal;
begin
  buffer := c and $7f;
  while (c shr 7) <> 0 do
  begin
    c := c shr 7;
    buffer := (buffer shl 8) + (c and $7f) + $80;
  end;
  while (true) do
  begin
    WriteByte(buffer and $ff);
    if (buffer and $80) <> 0 then
      buffer := buffer shr 8
    else
      break;
  end;
end;


class function TMyMidiStream.IsEndOfTrack(const d: TInt4): boolean;
begin
  result :=  (d[1] = $ff) and (d[2] = $2f) and (d[3] = 0);
end;


end.

