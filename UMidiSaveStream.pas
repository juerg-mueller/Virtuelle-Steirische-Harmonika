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

unit UMidiSaveStream;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$ifdef FPC}
  LCLIntf, LCLType, LMessages,
{$endif}
  Classes, SysUtils,
  UMyMidiStream, UMidiEvent, syncobjs;

type
  TMidiRecord = class
  private
    CriticalMidi: syncobjs.TCriticalSection;
  public
    InstrumentName: string;
    eventCount: integer;
    MidiEvents: array of TMidiEvent;
    hasOns: boolean;
    OldTime: TTime;
    Header: TDetailHeader;

    constructor Create(Name: string);
    destructor Destroy;
    procedure OnMidiInData(const Status, Data1, Data2: byte; Timestamp: int64);
  end;

  TMidiSaveStream = class(TMyMidiStream)
  public
    Instrument: string;
    trackOffset: cardinal;
    constructor Create;
    procedure SetHead(DeltaTimeTicks: integer = 192);
    procedure AppendTrackHead(delay: integer = 0);
    procedure AppendHeaderMetaEvents(const Details: TDetailHeader);
    procedure AppendTrackEnd(IsLastTrack: boolean);
    procedure AppendEvent(const Event: TMidiEvent); overload;
    procedure AppendEvent(command, d1, d2: byte); overload;
    procedure AppendMetaEvent(EventNr: byte; b: AnsiString);
    class function BuildSaveStream(var MidiRec: TMidiRecord): TMidiSaveStream;
  end;

implementation

constructor TMidiRecord.Create(Name: string);
begin
  CriticalMidi := TCriticalSection.Create;
  InstrumentName := Name;
  eventCount := 0;
  SetLength(MidiEvents, 1000000);
  hasOns := false;
  OldTime := 0;
  Header.Clear;
end;

destructor TMidiRecord.Destroy;
begin
  SetLength(MidiEvents, 0);
  CriticalMidi.Free;
end;

procedure TMidiRecord.OnMidiInData(const Status, Data1, Data2: byte; Timestamp: int64);
var
  Event: TMidiEvent;
  time: int64;
begin
  CriticalMidi.Acquire;
  try
    if eventCount >= Length(MidiEvents)-1 then
      SetLength(MidiEvents, 2*Length(MidiEvents));

    time := Timestamp;
    if eventCount = 0 then
      OldTime := time;
    Event.Clear;
    Event.command := Status;
    if Event.Event = 9 then
      hasOns := true;
    Event.d1 := Data1;
    Event.d2 := Data2;
    MidiEvents[eventCount] := Event;
    if eventCount > 0 then
      MidiEvents[eventCount-1].var_len := Header.MsDelayToTicks(trunc(time - OldTime));  // ms
    inc(eventCount);
    OldTime := time;
  finally
    CriticalMidi.Release;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TMidiSaveStream.Create;
begin
  inherited;

  BigEndian := true;
  Instrument := '';
end;

procedure TMidiSaveStream.AppendMetaEvent(EventNr: byte; b: AnsiString);
var
  i,  l: integer;
begin
  l := Length(b);
  WriteByte($ff);
  WriteByte(EventNr);
  WriteByte(l);
  if l > 0 then
  begin
    for i := 1 to l do
      WriteByte(byte(b[i]));
    WriteByte(0);
  end;
end;

procedure TMidiSaveStream.SetHead(DeltaTimeTicks: integer = 192);
begin
  Position := 0;
  WriteAnsiString('MThd');
  WriteCardinal(6);
  WriteWord(1);              // file format                          + 8
  WriteWord(0);              // track count                          + 10
  WriteWord(DeltaTimeTicks); // delta time ticks per quarter note    + 12
end;

procedure TMidiSaveStream.AppendHeaderMetaEvents(const Details: TDetailHeader);
begin
  AppendMetaEvent($51, Details.GetMetaBeats51);
  if (Details.CDur <> 0) or Details.Minor then
    AppendMetaEvent($59, Details.GetMetaDurMinor59);
  AppendMetaEvent($58, Details.GetMetaMeasure58);
  if Instrument <> '' then
    AppendMetaEvent(4, AnsiString(Instrument));
end;

procedure TMidiSaveStream.AppendTrackHead(delay: integer);
var
  count: word;
begin
  WriteAnsiString('MTrk');
  trackOffset := Position;
  WriteCardinal(0);           // chunck size
  WriteVariableLen(delay);
  count := GetWord(10) + 1;
  SetWord(count, 10); // increment track count
end;

procedure TMidiSaveStream.AppendTrackEnd(IsLastTrack: boolean);
begin
  AppendMetaEvent($2f, '');
  SetCardinal(position - trackOffset - 4, trackOffset);
  if IsLastTrack then
    SetSize(Position);
end;

procedure TMidiSaveStream.AppendEvent(const Event: TMidiEvent);
var
  b: byte;
  i: integer;
  var_len: integer;
begin
  AppendEvent(Event.command, Event.d1, Event.d2);
  var_len := Event.var_len;
  if var_len < 0 then
    var_len := 0;
  if Event.Event = $f then
  begin
    b := Length(Event.bytes);
    WriteByte(b);
    if b > 0 then
    begin
      for i := 0 to b-1 do
        WriteByte(Event.bytes[i]);
      WriteVariableLen(var_len);
    end;
  end else
    WriteVariableLen(var_len);
end;

procedure TMidiSaveStream.AppendEvent(command, d1, d2: byte);
begin
  WriteByte(command);
  WriteByte(d1);
  if (Command shr 4) in [8..11,14] then
    WriteByte(d2);
end;

class function TMidiSaveStream.BuildSaveStream(var MidiRec: TMidiRecord): TMidiSaveStream;
var
  i, k, newCount: integer;
  SaveStream: TMidiSaveStream;
  inpush, isEvent: boolean;
  lastTakt: integer;
  startEvent: TMidiEvent;
begin
  result := nil;
  inpush := true;
  lastTakt := -1;
  if not MidiRec.hasOns then
    exit;

  // stream bereinigen
  newCount := 0;
  // Instrumentenwahl
  while (newCount < MidiRec.eventCount) and (MidiRec.MidiEvents[newCount].Event = 12) do
  begin
    MidiRec.MidiEvents[newCount].var_len := 0;
    inc(newCount);
  end;

  // Balg- und Metronom-Angaben überspringen
  i := newCount;
  while (i < MidiRec.eventCount-2) and
        MidiRec.MidiEvents[i].IsSustain or (MidiRec.MidiEvents[i].Channel in [9, 10]) do
  begin
    if MidiRec.MidiEvents[i].Channel in [9, 10] then
      lastTakt := i;
    inc(i);
  end;

  // Am Ende des Stücks kürzen
  while (i < MidiRec.eventCount) and
        (MidiRec.MidiEvents[MidiRec.eventCount-1].IsSustain or
          (MidiRec.MidiEvents[MidiRec.eventCount-1].Channel in [9, 10])) do
    dec(MidiRec.eventCount);

  if lastTakt > 0 then
  begin
    i := lastTakt;
    startEvent.Clear;
    startEvent.command := $B0;
    startEvent.d1 := ControlPartiturStart;
    MidiRec.MidiEvents[newCount] := startEvent;
    inc(newCount);
  end;

  for k := newCount to i-1 do
    if MidiRec.MidiEvents[i].IsSustain then
      inpush := (MidiRec.MidiEvents[k].d2 <> 0);

  MidiRec.MidiEvents[i].var_len := 0;
  while i < MidiRec.eventCount do
  begin
    if MidiRec.MidiEvents[i].Channel = 9 then
    begin
      inc(i);
      continue;
    end;
    isEvent := MidiRec.MidiEvents[i].IsSustain;
    if not isEvent or (inpush <> (MidiRec.MidiEvents[i].d2 <> 0)) then
    begin
      if isEvent then
        inpush := (MidiRec.MidiEvents[i].d2 <> 0);
      MidiRec.MidiEvents[newCount] := MidiRec.MidiEvents[i];
      inc(newCount);
    end;
{$ifdef CONSOLE}
   // writeln(newCount, '  ', MidiEvents[i].command, '  ', MidiEvents[i].d1, '  ', MidiEvents[i].d2);
{$endif}
    inc(i);
  end;

  SaveStream := TMidiSaveStream.Create;
  try
    SaveStream.SetSize(6*newCount + 10000);
    SaveStream.Instrument := MidiRec.InstrumentName;
    SaveStream.SetHead;
    SaveStream.AppendTrackHead(0);
    SaveStream.AppendMetaEvent(2, 'juerg5524.ch');
    SaveStream.AppendHeaderMetaEvents(MidiRec.Header);
    SaveStream.AppendTrackEnd(false);
    SaveStream.AppendTrackHead(0);
    for i := 0 to newCount-1 do
      SaveStream.AppendEvent(MidiRec.MidiEvents[i]);
    SaveStream.AppendTrackEnd(true);
    result := SaveStream;
  except
    SaveStream.Free;
  end;

end;


initialization

finalization

end.
