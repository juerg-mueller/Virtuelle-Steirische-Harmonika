//
// Copyright (C) 2020 J�rg M�ller, CH-5524
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

unit UMidiEvent;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, Types, UMyMemoryStream;

Const
  cSimpleHeader = AnsiString('Header');
  cSimpleTrackHeader = AnsiString('New_Track');
  cSimpleMetaEvent = AnsiString('Meta-Event');
  cPush = AnsiString('Push');
  cPull = AnsiString('Pull');

  PushTest = true;
  CrossTest = true;

  HexOutput = true;

  MidiC0 = 12;
  FlatNotes  : array [0..11] of string = ('C', 'Des', 'D', 'Es', 'E', 'F', 'Ges', 'G', 'As', 'A', 'B', 'H');
  SharpNotes : array [0..11] of string = ('C', 'Cis', 'D', 'Dis', 'E', 'F', 'Fis', 'G', 'Gis', 'A', 'B', 'H');

  Dur: array [-6..6] of string = ('Ges', 'Des','As', 'Es', 'B', 'F', 'C', 'G', 'D', 'A', 'E', 'H', 'Fis');

//  SustainPitch    = 26;
  ControlSustain  = $1f;   // + 3 f�r TRepeat
  ControlPartiturStart = $1e;

type
  TInt4 = array [0..3] of integer;

  eTranslate = (nothing, toGriff, toSound); 

  TPushPullSet = set of (push, pull);


  TMidiEvent = record
    command: byte;
    d1, d2: byte;
    var_len: integer;
    bytes: array of byte;

    constructor Create(a, b, c, l: integer);
    procedure Clear;
    function Event: byte;
    function Channel: byte;
    function IsSustain: boolean;
    function MakeNewSustain: boolean;
    function IsPush: boolean;
    procedure MakeSustain(Push: boolean);
    function IsEndOfTrack: boolean;
    function IsEqualEvent(const Event: TMidiEvent): boolean;
    procedure SetEvent(c, d1_, d2_: integer);
    procedure AppendByte(b: byte);
    procedure MakeMetaEvent(EventNr: byte; b: AnsiString);
    procedure FillBytes(const b: AnsiString);
    function GetBytes: string;
    function GetAnsi: AnsiString;
    function GetInt: cardinal;
    function GetAnsiChar(Idx: integer): AnsiChar;

    property str: String read GetBytes;
    property ansi: AnsiString read GetAnsi;
    property int: cardinal read GetInt;
    property char_[Idx: integer]: Ansichar read GetAnsiChar; default;
  end;
  PMidiEvent = ^TMidiEvent;

  TDetailHeader = record
    IsSet: boolean;
    // delta-time ticks pro Viertelnote
    DeltaTimeTicks: word;
    // Beats/min.  Viertelnoten/Min.
    beatsPerMin: integer;
    smallestFraction: integer;
    measureFact: integer;
    measureDiv: integer;
    CDur: integer;  // f-Dur: -1; g-Dur: +1
    Minor: boolean;

    procedure Clear;
    function GetMeasureDiv: double;
    function GetRaster(p: integer): integer;
    procedure SetRaster(var rect: TRect);
    function GetTicks: double;
    function GetSmallestTicks: integer;
    function MsDelayToTicks(MsDelay: integer): integer;
    function TicksPerMeasure: integer;
    function TicksToMs(Ticks: integer): double;
    function TicksToString(Ticks: integer): string;
    function SetTimeSignature(const Event: TMidiEvent; const Bytes: array of byte): boolean;
    function SetBeatsPerMin(const Event: TMidiEvent; const Bytes: array of byte): boolean;
    function SetDurMinor(const Event: TMidiEvent; const Bytes: array of byte): boolean;
    function SetParams(const Event: TMidiEvent; const Bytes: array of byte): boolean;
    function GetMetaBeats51: AnsiString;
    function GetMetaMeasure58: AnsiString;
    function GetMetaDurMinor59: AnsiString;
    function GetDur: string;
    function GetChordTicks(duration, dots: string): integer;

    property smallestNote: integer read GetSmallestTicks;
  end;
  PDetailHeader = ^TDetailHeader;

  TMidiHeader = record
    FileFormat: word;
    TrackCount: word;
    Details: TDetailHeader;
    procedure Clear;
  end;

  TTrackHeader = record
    ChunkSize: cardinal;
    DeltaTime: cardinal;
  end;

function MidiOnlyNote(Pitch: byte; Sharp: boolean = false): string;
function MidiNote(Pitch: byte): string;
function Min(a, b: integer): integer; inline;
function Max(a, b: integer): integer; inline;

function BytesToAnsiString(const Bytes: array of byte): AnsiString;

implementation

uses
  UGriffEvent;

function TMidiEvent.GetAnsi: AnsiString;
begin
  SetLength(result, Length(Bytes));
  Move(Bytes[0], result[1], Length(Bytes));
end;

function TMidiEvent.GetBytes: String;
var
  s: string;
  p, l: integer;
begin
  s := string(GetAnsi);
  l := 1;
  repeat
    p := Pos('&', Copy(s, l, length(s)));
    if p > 0 then
    begin
      Insert('amp;', s, p + l);
      l := p + l + 3;
    end;
  until p = 0;
  repeat
    p := Pos('<', s);
    if p > 0 then
    begin
      Delete(s, p, 1);
      Insert('&lt;', s, p);
    end;
  until p = 0;
  repeat
    p := Pos('>', s);
    if p > 0 then
    begin
      Delete(s, p, 1);
      Insert('&gt;', s, p);
    end;
  until p = 0;
{$ifdef FPC}
  result := '';
{$else}
  result := UTF8ToString(AnsiString(s));
{$endif}
end;

function TMidiEvent.GetInt: cardinal;
var
  i: integer;
begin
  result := 0;
  for i := 0 to Length(Bytes)-1 do
    result := (result shl 8) + Bytes[i];
end;

function TMidiEvent.GetAnsiChar(Idx: integer): AnsiChar;
begin
  result := #0;
  if (Idx >= 0) and (Idx < Length(bytes)) then
    result := AnsiChar(bytes[Idx]);
end;

function BytesToAnsiString(const Bytes: array of byte): AnsiString;
var
  i: integer;
begin
  SetLength(result, Length(Bytes));
  for i := 0 to Length(Bytes)-1 do
    result[i+1] := AnsiChar(Bytes[i]);
end;

function TDetailHeader.GetDur: string;
var
  c: integer;
begin
  c := shortint(CDur);
  while c < low(Dur) do
    inc(c, 12);
  while c > High(Dur) do
    dec(c, 12);
  if Minor then
    result := Dur[c] + '-Moll'
  else
    result := Dur[c] + '-Dur';
end;


function TDetailHeader.TicksPerMeasure: integer;
begin
  result := 4*DeltaTimeTicks*measureFact div measureDiv;
end;

function TDetailHeader.TicksToMs(Ticks: integer): double;
begin
  if DeltaTimeTicks = 0 then
    DeltaTimeTicks := 192;
  result := Ticks*60000.0 / (DeltaTimeTicks*beatsPerMin);
end;

function TDetailHeader.TicksToString(Ticks: integer): string;
var
  len: integer;
begin
  len := round(TicksToMs(Ticks)) div 1000;
  result := Format('%d:%2.2d', [len div 60, len mod 60]);
end;

function TDetailHeader.SetTimeSignature(const Event: TMidiEvent; const Bytes: array of byte): boolean;
var
  i: integer;
begin
  result := (Event.command = $ff) and (Event.d1 = $58) and (Event.d2 = 4) and (Length(Bytes) = 4);
  if result then
  begin
    measureFact := Bytes[0];
    case Bytes[1] of
      2: i := 4;
      3: i := 8;
      4: i := 16;
      5: i := 32;
      else i := 4;
    end;
    measureDiv := i;
  end;
end;

function TDetailHeader.SetDurMinor(const Event: TMidiEvent; const Bytes: array of byte): boolean;
begin
  result := (Event.command = $ff) and (Event.d1 = $59) and (Event.d2 = 2) and (Length(Bytes) = 2);
  if result then
  begin
    CDur := Bytes[0];
    if (CDur and $8) <> 0 then
      CDur := CDur or $f0;
    Minor := Bytes[1] <> 0;
  end;
end;

function TDetailHeader.SetBeatsPerMin(const Event: TMidiEvent; const Bytes: array of byte): boolean;
var
  bpm: double;
begin
  result := (Event.command = $ff) and (Event.d1 = $51) and (Event.d2 = 3) and (Length(Bytes) = 3);
  if result and
     not IsSet then // Cornelia Walzer
  begin
    bpm := (Bytes[0] shl 16) + (Bytes[1] shl 8) + Bytes[2];
    beatsPerMin := round(6e7 / bpm);
    IsSet := true;
  end;
end;

function TDetailHeader.SetParams(const Event: TMidiEvent; const Bytes: array of byte): boolean;
begin
  result := SetTimeSignature(Event, Bytes);
  if not result then
    result := SetBeatsPerMin(Event, Bytes);
  if not result then
    result := SetDurMinor(Event, Bytes);
end;

function TDetailHeader.GetSmallestTicks: integer;
begin
  if (smallestFraction < 1) then
    smallestFraction := 2;
  result := 4*DeltaTimeTicks div smallestFraction;
end;

function TDetailHeader.GetTicks: double;
var
  d: TDateTime;
  q: double;
begin
  d := now;
  d := 24.0*3600*(d - trunc(d)); // sek.
  if beatsPerMin < 20 then
    beatsPerMin := 20;
  q := d*DeltaTimeTicks*beatsPerMin / 60.0;
  result := q;
end;

function TDetailHeader.MsDelayToTicks(MsDelay: integer): integer;
begin
  result := round(MsDelay*DeltaTimeTicks*beatsPerMin / 60000.0); // MsDelay in ms
end;

function TDetailHeader.GetRaster(p: integer): integer;
var
  s: integer;
begin
  if p < 0 then
    result := -GetRaster(-p)
  else
  if p = DeltaTimeTicks  div 8 - 1 then
    result := DeltaTimeTicks  div 8
  else begin
    s := GetSmallestTicks;
    result := s*((p + 2*s div 3) div s);
  end;
end;

procedure TDetailHeader.SetRaster(var rect: TRect);
var
  w: integer;
  l: integer;
begin
  w := rect.Width;
  l := rect.Left;
  rect.Left := GetRaster(rect.Left);
  if rect.Left < l then
    inc(w, l - rect.Left);
  rect.Width := GetRaster(w);
end;

constructor TMidiEvent.Create(a, b, c, l: integer);
begin
  command := a;
  d1 := b; 
  d2 := c;
  var_len := 0;
end;

function TDetailHeader.GetMeasureDiv: double;
begin
  result := DeltaTimeTicks;
  if measureDiv >= 8 then
    result := result / (measureDiv div 4) ;
end;


procedure TDetailHeader.Clear;
begin
  IsSet := false;
  DeltaTimeTicks := 192;
  beatsPerMin := 120;
  smallestFraction := 32;  // 32nd
  measureFact := 4;
  measureDiv := 4;
  CDur := 0;
  Minor := false;
end;

function TDetailHeader.GetMetaBeats51: AnsiString;
var
  bpm: double;
  c: cardinal;
  beats: integer;
begin
  beats := 30;
  if beatsPerMin > beats then
    beats := beatsPerMin;
  bpm := trunc(6e7 / beats);
  c := round(bpm);
  result := AnsiChar(c shr 16) + AnsiChar((c shr 8) and $ff) + AnsiChar(c and $ff);
end;

function TDetailHeader.GetMetaMeasure58: AnsiString;
var
  d: integer;
begin
  result := #$04#$01#$18#$08; // Takt  4/2
  result[1] := AnsiChar(measureFact);
  d := measureDiv;
  while d > 2 do
  begin
    inc(result[2]);
    d := d div 2;
  end;
end;

function TDetailHeader.GetMetaDurMinor59: AnsiString;
begin
  result := AnsiChar(ShortInt(CDur and $f)) + AnsiChar(ord(Minor));
end;

function TDetailHeader.GetChordTicks(duration, dots: string): integer;
var
  h, d, p: integer;
  n, f: string;
begin
  if LowerCase(duration) = 'measure' then
  begin
    result := TicksPerMeasure;
    exit;
  end;
  result := GetFraction_(duration);
  if result > 0 then   // 128th
  begin
    result := 4*DeltaTimeTicks div result;
  end else begin
    p := Pos('/', duration);
    if p > 0 then
    begin
      n := Copy(Duration, 1, p-1);
      f := Copy(Duration, p+1, length(duration));
      result := 4*DeltaTimeTicks*StrToInt(n) div StrToInt(f);
    end;
  end;
  d := StrToIntDef(dots, 0);
  h := result;
  while d > 0 do
  begin
    h := h div 2;
    inc(result, h);
    dec(d);
  end;
end;


////////////////////////////////////////////////////////////////////////////////

procedure TMidiHeader.Clear;
begin
  FileFormat := 0;
  TrackCount := 0;
  Details.Clear;
end;  

function Min(a, b: integer): integer;
begin
  result := a;
  if b < a then
    result := b;
end;
  
function Max(a, b: integer): integer;
begin
  result := a;
  if b > a then
    result := b;
end;

procedure TMidiEvent.FillBytes(const b: AnsiString);
var
  i: integer;
begin
  SetLength(Bytes, Length(b));
  for i := 1 to Length(b) do
    Bytes[i-1] := Byte(b[i]);
  d2 := Length(b);
end;

procedure TMidiEvent.MakeMetaEvent(EventNr: byte; b: AnsiString);
begin
  command := $ff;
  d1 := EventNr;
  d2 := Length(b);
  var_len := 0;
  FillBytes(b);
end;

function TMidiEvent.Event: byte;
begin
  result := command shr 4;
end;

function TMidiEvent.Channel: byte;
begin
  result := command and $f;
end;

procedure TMidiEvent.Clear;
begin
  command := 0;
  d1 := 0;
  d2 := 0;
  var_len := 0;
  SetLength(bytes, 0);
end;
  
function TMidiEvent.IsSustain: boolean;
begin
  result := ((Event = 11) and (d1 in [64, ControlSustain]));
end;

function TMidiEvent.MakeNewSustain: boolean;
var
  Push: boolean;
begin
  result := IsSustain;
  if not result then
    exit;
  Push := IsPush;
  command := $b0;
  d1 := ControlSustain;
  if Push then
    d2 := 127
  else
    d2 := 0;
end;

function TMidiEvent.IsPush: boolean;
begin
  result := IsSustain and (d2 > 0);
end;

procedure TMidiEvent.SetEvent(c, d1_, d2_: integer);
begin
  command := c;
  d1 := d1_;
  d2 := d2_;
end;

procedure TMidiEvent.AppendByte(b: byte);
begin
  SetLength(bytes, Length(bytes)+1);
  bytes[Length(bytes)-1] := b;
end;

procedure TMidiEvent.MakeSustain(Push: boolean);
begin
  command := $b0;
  d1 := ControlSustain;
  if Push then
    d2 := 127
  else
    d2 := 0;
  var_len := 0;
//  MakeNewSustain;
end;

function MidiOnlyNote(Pitch: byte; Sharp: boolean): string;
begin
  if Sharp then
    result := Format('%s%d', [SharpNotes[Pitch mod 12], Pitch div 12])
  else
    result := Format('%s%d', [FlatNotes[Pitch mod 12], Pitch div 12])
end;

function MidiNote(Pitch: byte): string;
begin
  result := Format('%6s -  %d', [MidiOnlyNote(Pitch), Pitch])
end;

function TMidiEvent.IsEndOfTrack: boolean;
begin
  result :=  (command = $ff) and (d1 = $2f) and (d2 = 0);
end;

function TMidiEvent.IsEqualEvent(const Event: TMidiEvent): boolean;
begin
  result := (command = Event.command) and (d1 = Event.d1) and (d2 = Event.d2);
end;




end.

