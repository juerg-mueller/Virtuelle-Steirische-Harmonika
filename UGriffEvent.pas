//
// Copyright (C) 2022 Jürg Müller, CH-5524
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
unit UGriffEvent;

interface

uses
  SysUtils, Types,
  UMyMidiStream, UInstrument;

type

  TAmpelRec = record
    row: byte;
    index: integer;
  end;

  // da capo            anfang bis ende marke
  // da capo al fine
  // dal segno al fine
  // dal segno al coda   to coda marke    codab marke
  TRepeat = (rRegular, rStart, rStop, rVolta1Start, rVolta1Stop, rVolta2Start,
             rVolta2Stop {, rDaCapo, rSegno, rDalSegno, rCoda, rToCoda, rFine});
  TNoteType = (ntDiskant, ntBass, ntRest, ntRepeat);

  TEventPitchArr = array of integer;

  TDurationKind = (nonDur, pushDur);

  TGriffHeader = record
    Version: integer;
    UsedEvents: integer;
    Details: TDetailHeader;
  end;

  TGriffDuration = record
    Left: integer;
    Right: integer;

    constructor Create(Left_, Right_: integer); overload;
    constructor Create(const rect: TRect); overload;
    function IsZero: boolean;
    function IsIntersect(const Duration: TGriffDuration): boolean;
    function Intersect(const Duration: TGriffDuration): boolean;
    function IntersectWidth(const Duration: TGriffDuration): integer;
    procedure SetDuration(const rect: TRect);
    function IsEqual(const Duration: TGriffDuration): boolean;
    function Width: integer;
    function PointIsIn(const Point: integer): boolean;
  end;

  TGriffEvent = record
    NoteType: TNoteType;
    SoundPitch: byte;
    GriffPitch: byte; // für Bass 1..8
    Cross: boolean;   // für Bass2 true
    InPush: boolean;
    AbsRect: TRect;   // width = duration; für 5. und 6. Reihe: Height = 1  Top = -1
    Velocity: byte;
    Repeat_: TRepeat;

    function GetRow: byte;
    function GetIndex: integer;
    function SpecialBassWidth(const GriffHeader: TGriffHeader): integer;
    function IsEqual(const GriffEvent: TGriffEvent): boolean;
    function GetDuration: TGriffDuration;
    function SameChord(const Event: TGriffEvent): boolean;
    procedure Clear;
    procedure MakeRest;
    function GetAmpelRec: TAmpelRec;
    procedure Transpose(delta: integer);
    function Contains(P: TPoint): boolean;
    function GetBass: boolean;
    procedure SetBass(NewBass: boolean);
    function GetSteiBass: string;
    function IsAppoggiatura(const GriffHeader: TGriffHeader): boolean;
  {$if defined(__INSTRUMENTS__)}
    function IsDiatonic(const Instrument: TInstrument): boolean;
    function GriffToSound(const Instrument: TInstrument; diff: integer = 0): boolean;
    function InSet(const Instrument: TInstrument): TPushPullSet;
    function GetSoundPitch(const Instrument: TInstrument): byte;
    function SoundToGriff(const Instrument: TInstrument): boolean;
    function SetGriff(const Instrument: TInstrument; UsePush, FromGriffPartitur: boolean): integer;
    function SetGriffEvent(const Instrument: TInstrument; UsePush, FromGriffPartitur: boolean): boolean;
    function SoundToGriffBass(const Instrument: TInstrument; UsePush: boolean): integer; overload;
    function SoundToGriffBass(const Instrument: TInstrument): integer; overload;
    function SetEvent(Row, Index: integer; Push: boolean; const Instrument: TInstrument): boolean;
  {$endif}
  end;
  PGriffEvent = ^TGriffEvent;

  TGriffEventArray = array of TGriffEvent;

  PSelectedProc = procedure (SelectedEvent: PGriffEvent) of object;

const
  NoteNames: array [0..7] of string =
    ('whole', 'half', 'quarter', 'eighth', '16th', '32nd', '64th', '128th');

function GetFraction_(const sLen: string): integer; overload;
function GetFraction_(const sLen: integer): string; overload;
function GetLen_(var t32: integer; var dot: boolean; t32Takt: integer): integer;
function GetLen2_(var t32: integer; var dot: boolean; t32Takt: integer): integer;


function GetLen2(var t32: integer; var dot: boolean; t32Takt: integer): string;

function GetLyricLen(Len: string): integer;

implementation


function GetFraction_(const sLen: string): integer; overload;
var
  idx: integer;
begin
  result := 128;
  for idx := High(NoteNames) downto 1 do
    if sLen = NoteNames[idx] then
      break
    else
      result := result shr 1;
end;

function GetFraction_(const sLen: integer): string; overload;
var
  idx, i: integer;
begin
  result := '?';
  idx := 128;
  for i := High(NoteNames) downto 1 do
    if sLen = idx then
    begin
      result := NoteNames[i];
      break
    end else
      idx := idx shr 1;
end;

function GetLen_(var t32: integer; var dot: boolean; t32Takt: integer): integer;
// at most one dot
var
  t: integer;

  function Check: boolean;
  begin
    result := (t32 and t) <> 0;
  end;

  procedure DoCheck;
  begin
    while (result = 0) and (t <= 32) do
    begin
      if Check then
        result := t;
      t := t shl 1;
    end;
  end;


  procedure DoCheckBig;
  begin
    while (result = 0) and (t > 0) do
    begin
      if Check then
        result := t;
      t := t shr 1;
    end;
  end;

begin
  dot := false;
  result := 0;

  // als eine Note
  t := $20;
  while t >= 1 do
  begin
    if ((t and t32) <> 0) and
       ((t32 and not (t + t shr 1)) = 0) then
    begin
      result := t;
      dot := (t32 and (t shr 1)) <> 0;
      break;
    end else
      t := t shr 1;
  end;

  if (result = 0) and ((t32Takt mod 8) = 0) then
  begin
    t := 32;
    DoCheckBig;
  end;
  // whole   32
  // halfe   16
  // quarter: 8
  // eighth:  4
  // 16th:    2
  // 32nd:    1
  t := 1;
  if result = 0 then
  begin
    t := 1;
    DoCheck;
  end;
  dec(t32, result);
  if dot then
    dec(t32, result div 2);
end;

function GetLen2_(var t32: integer; var dot: boolean; t32Takt: integer): integer;
// no dot
begin
  dot := false;
  result := $20;
  while result >= 1 do
  begin
    if (result and t32) <> 0 then
    begin
      break;
    end else
      result := result shr 1;
  end;
  dec(t32, result);
end;

function GetLen2(var t32: integer; var dot: boolean; t32Takt: integer): string;
var
  val: integer;
begin
  dot := false;
  val := GetLen2_(t32, Dot, t32takt);
  if val = 0 then
    result := '?'
  else
    result := GetFraction_(32 div val);
end;

function GetLyricLen(Len: string): integer;
begin
  result := High(NoteNames);
  while (result >= 0) and (Len <> NoteNames[result]) do
    dec(result);
  if result < 0 then
    result := 2; // quarter

  case result of
    0: result := 58612;
    1: result := 58613;
    else inc(result, 58595);
  end;
end;


function TGriffEvent.GetSteiBass: string;
begin
  result := '?';
  if GriffPitch in [low(SteiBass[5]) .. high(SteiBass[5])] then
    if Cross then
      result := string(SteiBass[6, GriffPitch])
    else
      result := string(SteiBass[5, GriffPitch]);
end;

function TGriffEvent.SpecialBassWidth(const GriffHeader: TGriffHeader): integer;
begin
  result := AbsRect.Width;
  if NoteType = ntBass then
  begin
    if result < GriffHeader.Details.DeltaTimeTicks div 2 then
      result := GriffHeader.Details.DeltaTimeTicks div 2;
  end;
end;

function TGriffEvent.SetEvent(Row, Index: integer; Push: boolean; const Instrument: TInstrument): boolean;
begin
  result := false;
  Clear;
  SoundPitch := Instrument.GetPitch(Row, Index, Push);
  if SoundPitch = 0 then
    exit;

  if Row in [5,6] then
  begin
    NoteType := ntBass;
    GriffPitch := Index;
    InPush := Push and Instrument.BassDiatonic;
    AbsRect.Top := -1;
  end else begin
    GriffPitch := RowIndexToGriff(Row, Index);
    InPush := Push;
    AbsRect.Top := GetPitchLine(GriffPitch);
  end;
  Cross := Row in [3, 4, 6];
  AbsRect.Height := 1;
  result := true;
end;

function TGriffEvent.GetRow: byte;
var
  Line: integer;
begin
  result := 0;
  if NoteType = ntDiskant then
  begin
    Line := GetPitchLine(GriffPitch);
    if Line >= 0 then
    begin
      if odd(Line) then
        result := 2
      else
        result := 1;
      if Cross then
        inc(result, 2);
    end;
  end else
  if NoteType = ntBass then
  begin
    if Cross then
      result := 6
    else
      result := 5;
  end;
end;

function TGriffEvent.GetIndex: integer;
var
  Line: integer;
begin
  result := -1;
  if NoteType = ntDiskant then
  begin
    Line := GetPitchLine(GriffPitch);
    if Line >= 0 then
    begin
      result := Line div 2;
    end;
  end else
  if NoteType = ntBass then
  begin
    if GriffPitch > 0 then
      result := GriffPitch;
  end;
end;

procedure TGriffEvent.Clear;
begin
  NoteType := ntDiskant;
  SoundPitch := 0;
  GriffPitch := 0;
  Cross := false;
  InPush := false;
  AbsRect := TRect.Create(0, 0, 0, 0);
  Velocity := $7f;
  Repeat_ := rRegular;
end;

constructor TGriffDuration.Create(Left_, Right_: integer);
begin
  Left := Left_;
  Right := Right_;
end;

constructor TGriffDuration.Create(const rect: TRect);
begin
  Left := rect.Left;
  Right := rect.Right;
end;

function TGriffDuration.IsZero: boolean;
begin
  result := Left >= Right;
end;

function TGriffDuration.IsEqual(const Duration: TGriffDuration): boolean;
begin
  result := (Left = Duration.Left) and (Right = Duration.Right);
end;

function TGriffDuration.Width: integer;
begin
  result := Right - Left;
end;

function TGriffDuration.PointIsIn(const Point: integer): boolean;
begin
  result := (left <= Point) and (Point < right);
end;

function TGriffDuration.IsIntersect(const Duration: TGriffDuration): boolean;
var
  d: TGriffDuration;
begin
  d := self;
  result := d.Intersect(Duration);
end;

function TGriffDuration.IntersectWidth(const Duration: TGriffDuration): integer;
var
  d: TGriffDuration;
begin
  d := self;
  result := 0;
  if d.Intersect(Duration) then
    result := d.Width;
end;

function TGriffEvent.SameChord(const Event: TGriffEvent): boolean;
begin
  result := abs(GetDuration.IntersectWidth(Event.GetDuration) - AbsRect.Width) < 5
end;


function TGriffDuration.Intersect(const Duration: TGriffDuration): boolean;
begin
  if Left < Duration.Left then
    Left := Duration.Left;
  if Right > Duration.Right then
    Right := Duration.Right;

  result := not IsZero;
end;

procedure TGriffDuration.SetDuration(const rect: TRect);
begin
  Left := rect.Left;
  Right := rect.Right;
end;

function TGriffEvent.GetDuration: TGriffDuration;
begin
  result.SetDuration(AbsRect);
end;

function TGriffEvent.IsEqual(const GriffEvent: TGriffEvent): boolean;
begin
  result := (NoteType = GriffEvent.NoteType) and
            (SoundPitch = GriffEvent.SoundPitch) and
            (GriffPitch = GriffEvent.GriffPitch) and
            (Cross = GriffEvent.Cross) and
            (InPush = GriffEvent.InPush) and
            AbsRect.IntersectsWith(GriffEvent.AbsRect);
end;

function TGriffEvent.GetBass: boolean;
begin
  result := NoteType = ntBass;
end;

procedure TGriffEvent.SetBass(NewBass: Boolean);
begin
  if NoteType in [ntDiskant, ntBass] then
  begin
    if NewBass then
      NoteType := ntBass
    else
      NoteType := ntDiskant;
  end;
end;

function TGriffEvent.IsDiatonic(const Instrument: TInstrument): boolean;
begin
  result := (NoteType = ntDiskant) or
            ((NoteType = ntBass) and Instrument.BassDiatonic);
end;

function TGriffEvent.SoundToGriff(const Instrument: TInstrument): boolean;
var
  Pitch: integer;
  Push: boolean;
  Col, Index: integer;
begin
  result := false;
  if (NoteType = ntBass) then
  begin
    AbsRect.Top := -1;
    AbsRect.Height := 1;
    Push := InPush;
    Pitch := SoundToGriffBass(Instrument);
    if InPush = Push then
      result := Pitch > 0
    else
      InPush := Push;
  end else begin
    Pitch := Instrument.SoundToGriff(SoundPitch, InPush, Col, Index);
    if Pitch >= 0 then
    begin
      NoteType := ntDiskant;
      Cross := Col >= 3;
      GriffPitch := Pitch;
      AbsRect.Top := GetPitchLine(GriffPitch);
      AbsRect.Height := 1;
      result := true;
    end;
  end;
end;

function TGriffEvent.SoundToGriffBass(const Instrument: TInstrument; UsePush: boolean): integer;
begin
  if Instrument.BassDiatonic and not UsePush then
    result := SoundToGriff_(SoundPitch, Instrument.PullBass, Cross)
  else
    result := SoundToGriff_(SoundPitch, Instrument.Bass, Cross);
end;

function TGriffEvent.SoundToGriffBass(const Instrument: TInstrument): integer;
begin
  result := SoundToGriffBass(Instrument, InPush);
  if (result <= 0) then
  begin
    if Instrument.BassDiatonic then
    begin
      result := SoundToGriffBass(Instrument, not InPush);
      if result > 0 then
        InPush := not InPush;
    end else begin
      dec(SoundPitch, 12);
      result := SoundToGriffBass(Instrument, InPush);
      if result <= 0 then
        inc(SoundPitch, 12);
    end;
  end;
  if result > 0 then
    GriffPitch := result;
end;

function TGriffEvent.SetGriff(const Instrument: TInstrument; UsePush, FromGriffPartitur: boolean): integer;
var
  col, Index: integer;
begin
  if NoteType = ntBass then
  begin
    Cross := false;
    InPush := UsePush;
    result := SoundToGriffBass(Instrument);
    AbsRect.Top := -1;
    AbsRect.Height := 1;
    exit;
  end;
  if FromGriffPartitur then
  begin
    GriffPitch := SoundPitch;
    result := Instrument.GriffToSound(GriffPitch, UsePush, false);
    if result >= 0 then
    begin
      Cross := false;
      SoundPitch := result;
    end;
  end else begin
    result := Instrument.SoundToGriff(SoundPitch, UsePush, Col, Index);
    if result >= 0 then
    begin
      Cross := Col >= 3;
      GriffPitch := result;
    end;
  end;
  if result >= 0 then
  begin
    InPush := UsePush;
    AbsRect.Top := GetPitchLine(GriffPitch);
    AbsRect.Height := 1;
  end;
end;

function TGriffEvent.SetGriffEvent(const Instrument: TInstrument; UsePush, FromGriffPartitur: boolean): boolean;
var
  e: TGriffEvent;
begin
  result := false;
  if not (NoteType in [ntDiskant, ntBass]) then
    exit;

  if NoteType = ntBass then
  begin
    result := true;
    Cross := false;
    if Instrument.BassDiatonic then
      InPush := UsePush;
    SoundToGriffBass(Instrument);

    AbsRect.Top := -1;
    AbsRect.Height := 1;
  end else
  if (SetGriff(Instrument, UsePush, FromGriffPartitur) >= 0) or
     (SetGriff(Instrument, not UsePush, FromGriffPartitur) >= 0) then
  begin
    result := true;
  end else begin
    e := self;
    if e.SoundPitch < 60 then
      inc(e.SoundPitch, 12)
    else
      dec(e.SoundPitch, 12);
    if (e.SetGriff(Instrument, UsePush, FromGriffPartitur) >= 0) or
       (e.SetGriff(Instrument, not UsePush, FromGriffPartitur) >= 0) then
    begin
{$if defined(CONSOLE)}
      writeln('Pitch  ', SoundPitch, '  $', IntToHex(SoundPitch), ' transposed to ', e.SoundPitch);
{$endif}
      self := e;
      result := true;
    end;
  end;
{$if defined(CONSOLE)}
  if not result then
    writeln('Pitch failed ', SoundPitch, '  ( Note ', MidiOnlyNote(SoundPitch), ')');
{$endif}

end;

function TGriffEvent.GetSoundPitch(const Instrument: TInstrument): byte;
var
  res: integer;
begin
  result := 0;
  if NoteType = ntDiskant then
  begin
    res := Instrument.GriffToSound(GriffPitch, InPush, Cross);
    if res >= 0 then
      result := res;
  end else
    result := SoundPitch;
end;

function TGriffEvent.GetAmpelRec: TAmpelRec;
begin
  result.row := GetRow;
  result.index := GetIndex;
end;

function TGriffEvent.InSet(const Instrument: TInstrument): TPushPullSet;
var
  iCol, Index: integer;
begin
  result := [];
  if NoteType = ntBass then
  begin
    if Instrument.BassDiatonic and (GriffPitch <> 0) then
    begin
      if SoundToGriffBass(Instrument, true) > 0 then
        result := [push];
      if SoundToGriffBass(Instrument, false) > 0 then
        result := result + [pull];
    end else
      result := [push, pull]
  end else
  if IsDiatonic(Instrument) then
  begin
    if Instrument.SoundToGriff(SoundPitch, true, iCol, Index) >= 0 then
      result := [push];
    if Instrument.SoundToGriff(SoundPitch, false, iCol, Index) >= 0 then
      result := result + [pull];
  end;
end;

function TGriffEvent.GriffToSound(const Instrument: TInstrument; diff: integer): boolean;
var
  Index: integer;
begin
  Index := -1;
  if NoteType = ntBass then
  begin
    if GriffPitch in [1..8] then
    begin
      if not InPush and Instrument.BassDiatonic then
        Index := Instrument.PullBass[Cross, GriffPitch]
      else
        Index := Instrument.Bass[Cross, GriffPitch];
    end;
  end else
  if NoteType = ntDiskant then
    Index := Instrument.GriffToSound(GriffPitch, InPush, Cross);
  result := Index >= 0;
  if result then
    SoundPitch := Index;
end;

procedure TGriffEvent.Transpose(delta: integer);
var
  s: integer;
begin
  s := SoundPitch + delta;
  if (s < 0) or (s > 127) then
  begin
{$if defined(CONSOLE)}
    writeln('Transpose error ', s);
{$endif}
  end else
  if (NoteType = ntDiskant) or (GriffPitch in [1..8]) then
    SoundPitch := s;
end;

function TGriffEvent.Contains(P: TPoint): boolean;
begin
  if NoteType = ntBass then
    inc(P.Y);
  result := AbsRect.Contains(p);
end;

procedure TGriffEvent.MakeRest;
begin
  Clear;
  NoteType := ntRest;
  SoundPitch := 70;
  GriffPitch := 70;
  AbsRect.Width := 10;
  AbsRect.Height := 1;
end;

function TGriffEvent.IsAppoggiatura(const GriffHeader: TGriffHeader): boolean;
begin
  result := AbsRect.Width = GriffHeader.Details.DeltaTimeTicks div 8 - 1
end;

end.
