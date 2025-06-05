//
// Copyright (C) 2021 Jürg Müller, CH-5524
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
unit UEventArray;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  UMyMidiStream, SysUtils, Classes, UMidiEvent;

const
  CopyrightGriff = AnsiString('Griffschrift - Copyright by juerg5524.ch');
  CopyrightNewGriff = AnsiString('new Griffschrift - Copyright by juerg5524.ch');
  Copyrightreal  = AnsiString('real Griffschrift Noten - Copyright by juerg5524.ch');


type
  TCopyright = (noCopy, prepCopy, griffCopy, realCopy, newCopy);

  TMidiEventArray = array of TMidiEvent;
  PMidiEventArray = ^TMidiEventArray;
  TChannelEventArray = array [0..15] of TMidiEventArray;
  TTrackEventArray = array of TMidiEventArray;
  TAnsiStringArray = array of AnsiString;


  TEventArray = class
  protected
    TrackName_: TAnsiStringArray; // 03
    TrackArr_: TTrackEventArray;
  public
    Text_: AnsiString;     // 01
    Copyright: AnsiString; // 02
                           // Melodie / Bass
    Instrument: AnsiString;// 04
    DetailHeader: TDetailHeader;
    SingleTrack: TMidiEventArray;
    ChannelArray: TChannelEventArray;

    constructor Create;
    destructor Destroy; override;
    function LoadMidiFromFile(FileName: string; Lyrics: boolean): boolean;
    function LoadMidiFromSimpleFile(FileName: string; Lyrics: boolean): boolean;
    function LoadMidiFromDataStream(Midi: TMyMidiStream; Lyrics: boolean): boolean;
    function SaveMidiToStream(Lyrics: boolean): TMemoryStream; overload;
    class function SaveMidiToStream(
      const TrackArr: TTrackEventArray; const DetailHeader: TDetailHeader;
      Lyrics: boolean): TMemoryStream; overload;
    function SaveSimpleMidiToFile(FileName: string; Lyrics: boolean = false): boolean; overload;
    class function SaveSimpleMidiToFile(FileName: string;
      const TrackArr: TTrackEventArray; const DetailHeader: TDetailHeader;
      Lyrics: boolean = false): boolean; overload;
    procedure Clear;
    procedure Move_var_len; overload;
    function Transpose(Delta: integer): boolean; overload;
    function GetCopyright: TCopyright;
    procedure SetNewTrackCount(Count: integer);
    function TrackCount: integer;
    function CheckMysOergeli: boolean;
    function MakeNewSingleTrack: boolean;
    procedure Repair;

    property TrackName: TAnsiStringArray read TrackName_;
    property TrackArr: TTrackEventArray read TrackArr_;
    property Track: TTrackEventArray read TrackArr_;

    class procedure ClearEvents(var Events: TMidiEventArray);
    class procedure AppendEvent(var MidiEventArray: TMidiEventArray;
                                const MidiEvent: TMidiEvent);
    class function SplitEventArray(var ChannelEvents: TChannelEventArray;
                                   const Events: TMidiEventArray;
                                   count: cardinal): boolean;
    class function MakePairs(var Events: TMidiEventArray): boolean;
    class procedure MakeOergeliEvents(var ChannelEvents: TChannelEventArray);
    class procedure MakeHarmonikaEvents(var ChannelEvents: TChannelEventArray);
    class procedure Move_var_len(var Events: TMidiEventArray); overload;
    class procedure MakeSingleTrack(var Events: TMidiEventArray; const ChannelEvents: TChannelEventArray); overload;
    class procedure MergeTracks(var Events1: TMidiEventArray; const Events2: TMidiEventArray);
    class procedure ReduceBass(var Events: TMidiEventArray);
    class function GetDuration(const Events: TMidiEventArray; Index: integer): integer;
    class function Transpose(var Events: TMidiEventArray; Delta: integer): boolean; overload;
    class function HasSound(const MidiEventArr: TMidiEventArray): boolean;
    class function LyricsCount(const MidiEventArr: TMidiEventArray): integer;
    class function InstrumentIdx(const MidiEventArr: TMidiEventArray): integer;
    class function PlayLength(const MidiEventArr: TMidiEventArray): integer;
    class function MakeSingleTrack(var MidiEventArray: TMidiEventArray; const TrackArr: TTrackEventArray): boolean; overload;
    class function GetDelayEvent(const EventTrack: TMidiEventArray; iEvent: integer): integer;
    class procedure MoveLyrics(var Events: TMidiEventArray);
    class function EraseFirst(var MidiEventArray: TMidiEventArray): boolean;

    class procedure MakeNice(var MidiEvents: TMidiEventArray);
    class procedure RemoveIndex(Index: integer; var MidiEvents: TMidiEventArray);
  end;

  PSetEvent = procedure (const Event: TMidiEvent) of object;
{$ifdef LINUX}
  TMidiEventPlayer = class
{$else}
  TMidiEventPlayer = class(TThread)
{$endif}
  public
    Pos: PString;
    Playing: PBoolean;
    DetailHeader: TDetailHeader;
    MidiEventArr: TMidiEventArray;

    SetPlayEvent: PSetEvent;

  {$ifndef LINUX}
    procedure Execute; override;
    procedure StopPlay;
    function Terminated_: boolean;
  {$else}
    procedure Execute;
  {$endif}
  end;


  procedure CopyEventArray(var OutArr: TMidiEventArray; const InArr: TMidiEventArray);


implementation

uses
  umidi,
{$ifndef mswindows}
  urtmidi,
{$else}
  Midi,
{$endif}
{$ifdef dcc}
  AnsiStrings,
{$endif}
  UMidiDataStream, UInstrument;

constructor TEventArray.Create;
begin
  inherited;

  DetailHeader.Clear;
  Clear;
end;

destructor TEventArray.Destroy;
begin
  Clear;

  inherited;
end;

procedure TEventArray.Clear;
begin
  Text_ := '';
  Copyright := '';
  Instrument := '';

  DetailHeader.Clear;
  SetNewTrackCount(0);
end;

procedure TEventArray.SetNewTrackCount(Count: integer);
var
  i: integer;
begin
  for i := Count to Length(TrackArr)-1 do
  begin
    ClearEvents(TrackArr[i]);
    TrackName[i] := '';
  end;
  SetLength(TrackArr_, Count);
  SetLength(TrackName_, Count);
end;

function TEventArray.TrackCount: integer;
begin
  result := Length(TrackArr_);
end;

function TEventArray.LoadMidiFromFile(FileName: string; Lyrics: boolean): boolean;
var
  Midi: TMidiDataStream;
begin
  result := false;
  Midi := TMidiDataStream.Create;
  try
    Midi.LoadFromFile(FileName);
    result := LoadMidiFromDataStream(Midi, Lyrics);
  finally
    Midi.Free;
  end;
end;

function TEventArray.LoadMidiFromSimpleFile(FileName: string; Lyrics: boolean): boolean;
var
  Midi: TMidiDataStream;
  SimpleFile: TSimpleDataStream;
begin
  result := false;
  try
    Midi := TMidiDataStream.Create;
    SimpleFile := TSimpleDataStream.Create;
    SimpleFile.LoadFromFile(FileName);
    Midi := SimpleFile.MakeMidiFromSimpleStream;
    if Midi <> nil then
      result := LoadMidiFromDataStream(Midi, Lyrics);
  finally
    SimpleFile.Free;
    Midi.Free;
  end;
end;

function TEventArray.LoadMidiFromDataStream(Midi: TMyMidiStream; Lyrics: boolean): boolean;
begin
  result := false;
  try
    result := (Midi as TMidiDataStream).MakeEventArray(self, Lyrics);
    MakeSingleTrack(SingleTrack, TrackArr);
    EraseFirst(SingleTrack);
    SplitEventArray(ChannelArray, SingleTrack, Length(SingleTrack));
  finally
    if not result then
      Clear;
  end;
end;

class function TEventArray.SaveSimpleMidiToFile(FileName: string;
  const TrackArr: TTrackEventArray; const DetailHeader: TDetailHeader; Lyrics: boolean): boolean;
var
  iTrack, iEvent: integer;
  Simple: TSimpleDataStream;
  Event: TMidiEvent;
  i: integer;
  d: double;
  takt, offset: integer;
  Events: TMidiEventArray;
  bpm: double;
  l, k: integer;

  procedure WriteMetaEvent(const Event: TMidiEvent);
  var
    i: integer;
  begin
    with Simple do
    begin
      WriteString(Format('%5d Meta-Event %d %3d %3d',
                         [event.var_len, event.command, event.d1, event.d2]));
      for i := 0 to Length(event.Bytes)-1 do
        WriteString(' ' +IntToStr(event.bytes[i]));
      WriteString('   ');
      for i := 0 to Length(event.Bytes)-1 do
        if (event.bytes[i] > ord(' ')) or
           ((event.bytes[i] = ord(' ')) and
            (i > 0) and (i < Length(event.Bytes)-1)) then
          WriteString(Char(event.bytes[i]))
        else
          WriteString('.');
    end;
  end;

begin
  Simple := TSimpleDataStream.Create;
  try
    with Simple do
    begin
      with MidiHeader do
      begin
        Clear;
        FileFormat := 1;
        TrackCount := Length(TrackArr) + 1;
        Details := DetailHeader;
      end;
      WriteHeader(MidiHeader);

      if not Lyrics then
      begin
        WriteTrackHeader(0);
        if DetailHeader.QuarterPerMin > 0 then
        begin
          bpm := 6e7 / DetailHeader.QuarterPerMin;
          l := round(bpm);
          WriteString('    0 ' + cSimpleMetaEvent + ' 255 81 3 '); // beats
          WritelnString(IntToStr(l shr 16) + ' ' + IntToStr((l shr 8) and $ff) + ' ' +
                        IntToStr(l and $ff) + ' 0');
        end;

        WriteString('    0 ' + cSimpleMetaEvent + ' 255 88 4 ' + IntToStr(DetailHeader.measureFact)); // time signature
        i := DetailHeader.measureDiv;
        k := 0;
        while i > 0 do
        begin
          i := i div 2;
          inc(k);
        end;
        WritelnString(' ' + IntToStr(k-1) + ' 24 8 0');

        WritelnString('    0 ' + cSimpleMetaEvent + ' 255 47 0'); // end of track
      end;

      for iTrack := 0 to Length(TrackArr)-1 do
      begin
        WriteTrackHeader(TrackArr[iTrack][0].var_len);
        offset := TrackArr[iTrack][0].var_len;
        for iEvent := 1 to Length(TrackArr[iTrack])-1 do
        begin
          Event := TrackArr[iTrack][iEvent];
          if Event.Event = $f then
          begin
            WriteMetaEvent(Event);
          end else
          if Event.Event in [8..14] then
          begin
            if HexOutput then
              WriteString(Format('%5d $%2.2x $%2.2x $%2.2x',
                                 [event.var_len, event.command, event.d1, event.d2]))
            else
              WriteString(Format('%5d %3d %3d %3d',
                                 [event.var_len, event.command, event.d1, event.d2]));
          end;
          if Event.Event = 9 then
          begin
            takt := Offset div MidiHeader.Details.TicksPerQuarter;
            if MidiHeader.Details.measureDiv = 8 then
              takt := 2*takt;
            d := MidiHeader.Details.measureFact;
            WriteString(Format('  Takt: %.2f', [takt / d + 1]));
          end;
          inc(offset, Event.var_len);
          WritelnString('');
        end;
        WritelnString('    0 ' + cSimpleMetaEvent + ' 255 47 0'); // end of track
      end;
    end;
    Simple.SaveToFile(FileName);
    result := true;
  finally
    Simple.Free;
  end;
end;

function TEventArray.SaveSimpleMidiToFile(FileName: string; Lyrics: boolean = false): boolean;
begin
  result := SaveSimpleMidiToFile(FileName, TrackArr, DetailHeader, Lyrics);
end;

function TEventArray.SaveMidiToStream(Lyrics: boolean): TMemoryStream;
begin
  result := SaveMidiToStream(TrackArr_, DetailHeader, Lyrics);
end;

class function TEventArray.SaveMidiToStream(
  const TrackArr: TTrackEventArray; const DetailHeader: TDetailHeader;
  Lyrics: boolean): TMemoryStream;
var
  i: integer;
  SaveStream: TMidiSaveStream;
begin
  SaveStream := TMidiSaveStream.Create;

    SaveStream.SetHead(DetailHeader.TicksPerQuarter);
  SaveStream.AppendTrackHead;
  SaveStream.AppendHeaderMetaEvents(DetailHeader);
  SaveStream.AppendTrackEnd(false);
  for i := 0 to Length(TrackArr)-1 do
  begin
    SaveStream.AppendTrackHead;
    SaveStream.AppendEvents(TrackArr[i]);
    SaveStream.AppendTrackEnd(false);
  end;
  SaveStream.Size := SaveStream.Position;

  result := SaveStream;
end;

procedure TEventArray.Move_var_len;
var
  i: integer;
begin
  for i := 0 to Length(TrackArr)-1 do
    TEventArray.Move_var_len(TrackArr[i]);
end;

function TEventArray.Transpose(Delta: integer): boolean;
var
  i: integer;
begin
  result := true;
  if Delta <> 0 then
    for i := 0 to Length(TrackArr)-1 do
      if not TEventArray.Transpose(TrackArr[i], Delta) then
        result := false;
end;


function TEventArray.GetCopyright: TCopyright;
begin
{$ifdef fpc}
  result := noCopy;
  if AnsiStrLComp(PAnsiChar(Copyright), PAnsiChar(Copyrightreal), Length('real Griffschrift - Copyright')) = 0 then
    result := realCopy
  else
  if AnsiStrLComp(PAnsiChar(Copyright), PAnsiChar(CopyrightGriff), Length('Griffschrift - Copyright')) = 0 then
    result := griffCopy
  else
  if AnsiStrLComp(PAnsiChar(Copyright), PAnsiChar(CopyrightNewGriff), Length('Griffschrift - Copyright')) = 0 then
    result := newCopy
  else
  if Copyright = CopyPrep then
    result := prepCopy;
{$else}
  result := noCopy;
  if AnsiStrings.AnsiStrLComp(PAnsiChar(Copyright), PAnsiChar(Copyrightreal), Length('real Griffschrift - Copyright')) = 0 then
    result := realCopy
  else
  if AnsiStrings.AnsiStrLComp(PAnsiChar(Copyright), PAnsiChar(CopyrightGriff), Length('Griffschrift - Copyright')) = 0 then
    result := griffCopy
  else
  if AnsiStrings.AnsiStrLComp(PAnsiChar(Copyright), PAnsiChar(CopyrightNewGriff), Length('Griffschrift - Copyright')) = 0 then
    result := newCopy
  else
  if Copyright = CopyPrep then
    result := prepCopy;
{$endif}
end;

function TEventArray.CheckMysOergeli: boolean;
var
  event: TMidiEvent;
  i, k: integer;
  count: array [0..15] of integer;
begin
  result := Copyright = 'VirtualHarmonica';
  if not result then
  begin
    for i := 0 to 15 do
      count[i] := 0;
    for i := 0 to Length(TrackArr_)-1 do
      for k := 0 to Length(TrackArr_[i])-1 do
      begin
        event := TrackArr_[i][k];
        case (event.command shr 4) of
          8, 9: inc(count[event.command and $f]);
          11:   if (event.command = $b7) and (event.d1 = $1f) then
                  inc(count[7]);
          else begin

          end;
        end;
      end;
    result := true; //count[7] > 0;
    for i := 0 to 15 do
      if (i in [0, 8..10, 12..15]) and (count[i] > 0) then
        result := false;
  end;

end;


////////////////////////////////////////////////////////////////////////////////

class function TEventArray.HasSound(const MidiEventArr: TMidiEventArray): boolean;
var
  i: integer;
begin
  result := false;
  i := 0;
  while (i < Length(MidiEventArr)) and not result do
    if MidiEventArr[i].Event = 9 then
      result := true
    else
      inc(i);
end;

class function TEventArray.LyricsCount(const MidiEventArr: TMidiEventArray): integer;
var
  i: integer;
begin
  result := 0;
  for i := 0 to Length(MidiEventArr)-1 do
    if (MidiEventArr[i].command = $ff) and (MidiEventArr[i].d1 = 5) then
      inc(result);
end;

class function TEventArray.InstrumentIdx(const MidiEventArr: TMidiEventArray): integer;
var
  i: integer;
begin
  result := -1;
  i := 0;
  while (i < Length(MidiEventArr)) do
    if MidiEventArr[i].Event = 12 then
    begin
      result := MidiEventArr[i].d1;
      break;
    end else
      inc(i);
end;

class function TEventArray.MakeSingleTrack(var MidiEventArray: TMidiEventArray; const TrackArr: TTrackEventArray): boolean;
var
  i: integer;
begin
  SetLength(MidiEventArray, 0);
  for i := 0 to Length(TrackArr)-1 do
    if Length(TrackArr[i]) > 0 then
      TEventArray.MergeTracks(MidiEventArray, TrackArr[i]);
  result := true;
end;

class function TEventArray.PlayLength(const MidiEventArr: TMidiEventArray): integer;
var
  i: integer;
begin
  result := 0;
  for i := 0 to Length(MidiEventArr)-1 do
    if MidiEventArr[i].var_len > 0 then
      inc(result, MidiEventArr[i].var_len);
end;

class procedure TEventArray.ClearEvents(var Events: TMidiEventArray);
var
  i: integer;
begin
  for i := 0 to Length(Events)-1 do
    SetLength(Events[i].bytes, 0);
  SetLength(Events, 0);
end;

class procedure TEventArray.AppendEvent(var MidiEventArray: TMidiEventArray;
                                        const MidiEvent: TMidiEvent);
begin
  SetLength(MidiEventArray, Length(MidiEventArray)+1);
  MidiEventArray[Length(MidiEventArray)-1] := MidiEvent;
end;

class function TEventArray.SplitEventArray(var ChannelEvents: TChannelEventArray;
                                           const Events: TMidiEventArray;
                                           count: cardinal): boolean;
var
  channel: byte;
  delay: integer;
  i, iMyEvent: integer;
begin
  result := false;
  for channel := 0 to 15 do
  begin
    SetLength(ChannelEvents[channel], 1000);
    ChannelEvents[channel][0].Clear;
    iMyEvent := 1;
    delay := 0;
    for i := 0 to count-1 do
    begin
      if (i = 0) and (Events[0].command = 0) then
      begin
        delay := Events[0].var_len; // mit wave synchronisieren
      end else
      if (Events[i].Channel = channel) and
         (Events[i].Event in [8..14]) then
      begin
        if High(ChannelEvents[channel]) < iMyEvent then
          SetLength(ChannelEvents[channel], 2*Length(ChannelEvents[channel]));

        ChannelEvents[channel][iMyEvent] := Events[i];
        inc(iMyEvent);
      end else
      if Events[i].Event in [8..14] then
      begin
        if iMyEvent > 1 then
          inc(ChannelEvents[channel][iMyEvent - 1].var_len, Events[i].var_len)
        else
          inc(delay, Events[i].var_len);
      end;
    end;
    if iMyEvent > 1 then
    begin
      ChannelEvents[channel][0].var_len := delay;
      SetLength(ChannelEvents[channel], iMyEvent);
      result := true;
    end else
      SetLength(ChannelEvents[channel], 0);
  end;
end;

class procedure TEventArray.MakeOergeliEvents(var ChannelEvents: TChannelEventArray);
const
  Diskant = 0;
  Bass1 = 1;
  Bass2 = 2;
var
  i, j, k: integer;
  max: integer;
  event: TMidiEvent;
  add: integer;
begin
  // Kanäle 0 und 3: diskant
  // Kanäle 1 und 4: 3-Klang Bass
  // Kanal 2:        Bass (monophon) / Grundton von Kanal 1 liegt eine Oktave höher
  // Kanal 5:        Kanal 2 genau eine Oktave höher

  // kurze Töne entfernen
  max := Length(ChannelEvents[Diskant]);
  i := 0;
  k := i;
  while (i < max) do
  begin
    event := ChannelEvents[Diskant][i];
    if (i+1 < max) and (event.Event = 9) and
       (event.var_len < 20) and
       (ChannelEvents[Diskant][i+1].command xor $10 = event.command) and
       (ChannelEvents[Diskant][i+1].d1 = event.d1) then
    begin
      if k > 0 then
      begin
        inc(ChannelEvents[Diskant][k-1].var_len, event.var_len);
        inc(ChannelEvents[Diskant][k-1].var_len, ChannelEvents[Diskant][i+1].var_len);
      end;
      inc(i, 2);
    end else begin
      ChannelEvents[Diskant][k] := event;
      inc(k);
      inc(i);
    end;
  end;
  SetLength(ChannelEvents[Diskant], k);

  // delete 3-Klang   (triad)
  ReduceBass(ChannelEvents[Bass1]);

  // Bass2 prellt!
  max := Length(ChannelEvents[Bass2]);
  if max > 0 then begin
    i := 0;
    while (i < max) and (ChannelEvents[Bass2][i].Event <> 9) do
      inc(i);
    k := i;
    while (i + 1 < max) do
    begin
      event := ChannelEvents[Bass2][i];
      j := i;
      while (j + 1 < max) and
            (event.d1 = ChannelEvents[Bass2][j + 1].d1) do
        inc(j);

      add := 0;
      while (j - i >= 3) do
      begin
        if (ChannelEvents[Bass2][i].var_len < 20) and
           (ChannelEvents[Bass2][i+1].var_len < 20) then
        begin
          inc(add, ChannelEvents[Bass2][i].var_len);
          inc(add, ChannelEvents[Bass2][i+1].var_len);
        end else
        if (ChannelEvents[Bass2][i+2].var_len < 20) then
        begin
          ChannelEvents[Bass2][k] := ChannelEvents[Bass2][i];
          inc (ChannelEvents[Bass2][k].var_len, add);
          inc (ChannelEvents[Bass2][k].var_len, ChannelEvents[Bass2][i+2].var_len);
          add := 0;
          ChannelEvents[Bass2][k+1] := ChannelEvents[Bass2][i+1];
          inc (ChannelEvents[Bass2][k+1].var_len, ChannelEvents[Bass2][i+3].var_len);
          inc(k, 2);
          inc(i, 2);
        end else begin
          ChannelEvents[Bass2][k] := ChannelEvents[Bass2][i];
          inc (ChannelEvents[Bass2][k].var_len, add);
          add := 0;
          ChannelEvents[Bass2][k+1] := ChannelEvents[Bass2][i+1];
          inc(k, 2);
        end;
        inc(i, 2);
      end;

      while i <= j do
      begin
        ChannelEvents[Bass2][k] := ChannelEvents[Bass2][i];
        inc (ChannelEvents[Bass2][k].var_len, add);
        add := 0;
        inc(i);
        inc(k);
      end;
    end;
    SetLength(ChannelEvents[Bass2], k);
    MergeTracks(ChannelEvents[Bass1], ChannelEvents[Bass2]);
    SetLength(ChannelEvents[Bass2], 0);
  end;


  for i := 3 to 15 do
    SetLength(ChannelEvents[i], 0);
end;

class procedure TEventArray.MakeHarmonikaEvents(var ChannelEvents: TChannelEventArray);
var
  i: integer;
begin
  MergeTracks(ChannelEvents[1], ChannelEvents[2]);
  SetLength(ChannelEvents[2], 0);

  for i := 3 to 15 do
    SetLength(ChannelEvents[i], 0);
end;


class procedure TEventArray.ReduceBass(var Events: TMidiEventArray);
var
  i, j, k, max, l, n: integer;
  event: array [0..3] of TMidiEvent;
  BassDone: boolean;

  procedure ExchangeD1(var e1, e2: TMidiEvent);
  var
    temp: byte;
  begin
    if e1.d1 > e2.d1 then
    begin
      temp := e1.d1; e1.d1 := e2.d1; e2.d1 := temp;
    end;
  end;

  procedure SetEvent(Idx: integer);
  begin
    if j + 1 < max then
    begin
      inc(j);
      event[Idx+1] := Events[j];
      if event[Idx].var_len < 8 then
      begin
        inc(event[Idx+1].var_len, event[Idx].var_len);
        event[Idx].var_len := 0;
      end;
    end;
  end;

begin
   max := Length(Events);
  i := 0;
  while (i < max) and (Events[i].Event <> 9) do
    inc(i);
  k := i;
  while (i < max) do
  begin
    for l := 0 to 3 do
      event[l].Clear;

    event[0] := Events[i];
    j := i;
    SetEvent(0);
    SetEvent(1);
    SetEvent(2);
    j := 1;
    while (j < 4) and
          (event[0].command = event[j].command) do
      inc(j);

    dec(j);
    for n := 0 to j-1 do
      if event[n].var_len <> 0 then
      begin
        j := n;
        break;
      end;


    for l := 0 to j-1 do
      for n := l + 1 to j do
        ExchangeD1(event[l], event[n]);

    BassDone := false;
    for l := 1 to j do
      if event[0].d1 + 12 = event[l].d1 then
      begin
        Events[k] := event[0];
        inc(k);
        inc(i);
        for n := 1 to j-1 do
          event[n-1] := event[n];
        dec(j);
        if j < 3 then
          inc(i);
        BassDone := true;
        break;
      end;

    if j >= 3 then
    begin
      if ((event[0].d1 + 4 = event[1].d1) and (event[1].d1 + 3 = event[2].d1)) or
         ((event[0].d1 + 3 = event[1].d1) and (event[1].d1 + 5 = event[2].d1)) or
         ((event[0].d1 + 5 = event[1].d1) and (event[1].d1 + 4 = event[2].d1)) then
      begin
        if (event[0].d1 + 3 = event[1].d1) and (event[1].d1 + 5 = event[2].d1) then
          dec(event[0].d1, 4)
        else
        if (event[0].d1 + 5 = event[1].d1) and (event[1].d1 + 4 = event[2].d1) then
          event[0].d1 := event[1].d1;
        if event[0].d1 > 56 then
          dec(event[0].d1, 12);
        event[0].var_len := event[2].var_len;
        inc(i, 3);
        Events[k] := event[0];
        inc(k);
        BassDone := true;
      end
    end;
    if not BassDone then
    begin
      Events[k] := Events[i];
      inc(k);
      inc(i);
    end;
  end;
  SetLength(Events, k);
end;

class procedure TEventArray.Move_var_len(var Events: TMidiEventArray);
var
  iEvent: integer;
begin
  for iEvent := length(Events)-1 downto 1 do
    if not (Events[iEvent].Event in [8, 9]) then
    begin
      inc(Events[iEvent-1].var_len, Events[iEvent].var_len);
      Events[iEvent].var_len := 0;
    end;
end;

class procedure TEventArray.MakeSingleTrack(var Events: TMidiEventArray; const ChannelEvents: TChannelEventArray);
var
  i: integer;
begin
  SetLength(Events, 0);
  for i := 0 to 15 do
  begin
    TEventArray.MergeTracks(Events, ChannelEvents[i]);
  end;
end;

class procedure TEventArray.MergeTracks(var Events1: TMidiEventArray; const Events2: TMidiEventArray);
var
  i, k: integer;
  Ev: TMidiEvent;
  iEvent: array [0..1] of integer;
  iOffset: array [0..1] of integer;
  Offset: integer;
  temp: TMidiEventArray;
  Events: array [0..1] of PMidiEventArray;

  function MidiEvent(i: integer): TMidiEvent;
  begin
    result := Events[i]^[iEvent[i]];
  end;

  function Valid(i: integer): boolean;
  begin
    result := iEvent[i] < Length(Events[i]^);
  end;

begin
  if Length(Events2) = 0 then
    exit;

  if not TEventArray.HasSound(Events1) then
  begin
    SetLength(Events1, 0);
    CopyEventArray(Events1, Events2);
    exit;
  end;
  CopyEventArray(temp, Events1);

  Events[0] := @temp;
  Events[1] := @Events2;
  SetLength(Events1, Length(Events1)+Length(Events2));

  for i := 0 to 1 do
  begin
    iEvent[i] := 0;
    iOffset[i] := 0;
  end;

  Offset := 0;
  k := 0;
  if (MidiEvent(0).command = 0) and
     (MidiEvent(1).command = 0) then
  begin
    for i := 0 to 1 do
    begin
      iOffset[i] := MidiEvent(i).var_len;
    end;
    if MidiEvent(0).var_len > MidiEvent(1).var_len then
      Events1[k].var_len := MidiEvent(1).var_len;
    Offset := Events1[k].var_len;
    inc(iEvent[0]);
    inc(iEvent[1]);
    inc(k);
  end;

  while Valid(0) and Valid(1) do
  begin
    for i := 0 to 1 do
    begin
      while Valid(i) and (iOffset[i] = Offset) do
      begin
        Ev := Events[i]^[iEvent[i]];
        if Ev.var_len > 0 then
          inc(iOffset[i], Ev.var_len);
        Ev.var_len := 0;
        Events1[k] := Ev;
        Events1[k+1].Clear;
        inc(iEvent[i]);
        if (i = 1) and (iEvent[i] = 82) then
          k := k;

        inc(k);
      end;
    end;
    inc(Offset);
    inc(Events1[k-1].var_len);
  end;

  i := 0;
  if Valid(1) then
    i := 1;
  if Valid(i) then
  begin
    if iOffset[i] > Offset then
      inc(Events1[k-1].var_len, iOffset[i] - Offset);
    while Valid(i) do
    begin
      Events1[k] := Events[i]^[iEvent[i]];
      inc(k);
      inc(iEvent[i]);
    end;
  end;

  SetLength(Events1, k);
  SetLength(temp, 0);
end;


class function TEventArray.MakePairs(var Events: TMidiEventArray): boolean;
const
  SmallestTicks = 60;
var
  i, k: integer;
  UsedEvents: integer;
begin
  UsedEvents := Length(Events);

  for i := 0 to UsedEvents-1 do
    if (Events[i].Event = 9) and (Events[i].d2 = 0) then
    begin
      Events[i].command := Events[i].command xor $10;
      Events[i].d2 := $40;
    end;
{
  i := 0;
  while i < UsedEvents do
  begin
    while (i < UsedEvents) and not (Events[i].event in [8, 9]) do
      inc(i);
    if i >= UsedEvents then
      break;

    ev := Events[i].event;
    k := i;
    while (k + 1 < UsedEvents) and (Events[k + 1].event = ev) do
      inc(k);
    while i < k do
    begin
      if Events[i].var_len > 0 then
      begin
        inc(Events[k].var_len, Events[i].var_len);
        Events[i].var_len := 0;
      end;
      inc(i);
    end;
    inc(i);
  end;
 }
  i := 0;
  while i < UsedEvents do
  begin
    while (i < UsedEvents) and not (Events[i].event <> 8) do
      inc(i);
    while (i < UsedEvents) and not (Events[i].event = 8) do
      inc(i);
    if i >= UsedEvents then
      break;

    if (i > 0) and (Events[i-1].event = 8) and (Events[i-1].var_len < 20) then
    begin
      k := i;
      while (k < UsedEvents) and not (Events[k].event = 8) and
            (Events[k].var_len = 0) do
        inc(k);
      if k >= UsedEvents then
        dec(k);
      if i < k then
      begin
        inc(Events[k].var_len, Events[i].var_len);
        Events[i].var_len := 0;
      end;
    end;
  end;
  //    Events[k].var_len := SmallestTicks*((Events[k].var_len  +
  //                         (SmallestTicks div 2)) div SmallestTicks);

  result := true;
end;

class function TEventArray.GetDuration(const Events: TMidiEventArray; Index: integer): integer;
var
  com, d1: integer;
begin
  result := 0;
  if (Index < 0) or (Index >= Length(Events)) or
     (Events[Index].Event <> 9) then
    exit;

  com := Events[Index].command xor $10;
  d1 := Events[Index].d1;
  repeat
    inc(result, Events[Index].var_len);
    inc(Index);
  until (Index >= Length(Events)) or
        ((Events[Index].command = com) and (Events[Index].d1 = d1));
end;

class function TEventArray.Transpose(var Events: TMidiEventArray; Delta: integer): boolean;
var
  i: integer;
begin
  result := true;
  if (Delta <> 0) and (abs(Delta) <= 20) then
    for i := 0 to Length(Events)-1 do
      if (Events[i].Event in [8, 9]) then
      begin
        if (Events[i].d1 + Delta > 20) and (Events[i].d1 + Delta <= 127) then
          Events[i].d1 := Events[i].d1 + Delta
        else
          result := false;
      end;
end;

class function TEventArray.GetDelayEvent(const EventTrack: TMidiEventArray; iEvent: integer): integer;
var
  i: integer;
  cmd: integer;
begin
  result := -1;
  cmd := EventTrack[iEvent].command;
  if (cmd shr 4) <> 9 then
    exit;

  result := EventTrack[iEvent].var_len;
  i := iEvent + 1;
  dec(cmd, $10);
  while (i < Length(EventTrack)) and
        ((EventTrack[i].command <> cmd) or
         (EventTrack[iEvent].d1 <> EventTrack[i].d1)) do
  begin
    inc(result, EventTrack[i].var_len);
    inc(i);
  end;
end;

class procedure TEventArray.MoveLyrics(var Events: TMidiEventArray);
var
  i, j1, j2, k: integer;
  dist1, dist2: integer;
  Event: TMidiEvent;
begin
  i := 0;
  while i < Length(Events) do
  begin
    Event := Events[i];
    if (Event.command = $ff) and (Event.d1 = 5) then
    begin
      if Event.var_len > 0 then
      begin
        dist1 := 0;
        j1 := i;
        while (j1 > 0) do
        begin
          dec(j1);
          inc(dist1, Events[j1].var_len);
          if Events[j1].Event = 9 then
            break;
        end;
        dist2 := 0;
        j2 := i;
        while (j2 < Length(Events)) do
        begin
          inc(dist2, Events[j2].var_len);
          if Events[j2].Event = 9 then
            break;
          inc(j2);
        end;

        inc(Events[i-1].var_len, Event.var_len);
        Event.var_len := 0;

        if dist2 <= dist1 then
        begin
          if (j2 < Length(Events)) and (dist2 < 10) then
          begin
            dec(j2);
            for k := i to j2-1 do
              Events[k] := Events[k+1];
            Events[j2] := Event;
          end;
        end else
        if (j1 > 1) and (dist1 < 10) then
        begin
          for k := i-1 downto j1 do
            Events[k+1] := Events[k];
          Events[j1] := Event;
        end;
      end;
    end;
    inc(i);
  end;
end;

// Löscht alle MIDI-Events bis zum ersten Push/Pull
class function TEventArray.EraseFirst(var MidiEventArray: TMidiEventArray): boolean;
var
  i, k, j: integer;
begin
  result := false;
  i := 0;
  while (i < Length(MidiEventArray)) and not result do
  begin
    result := MidiEventArray[i].IsPushPull;
    inc(i);
  end;
  if result then
  begin
    dec(i);
    k := 0;
    while (k < i) do
      if MidiEventArray[k].Event = 9 then
        break
      else
        inc(k);
    if k < i then
    begin
      for j := 0 to Length(MidiEventArray)-1-i do
        MidiEventArray[k+j] := MidiEventArray[i+j];
      SetLength(MidiEventArray, Length(MidiEventArray)-i+k);
    end;
  end;
end;

procedure CopyEventArray(var OutArr: TMidiEventArray; const InArr: TMidiEventArray);
var
  i: integer;
begin
  SetLength(OutArr, Length(InArr));
  for i := Low(InArr) to High(InArr) do
    OutArr[i] := InArr[i];

end;


class procedure TEventArray.MakeNice(var MidiEvents: TMidiEventArray);
var
  k, q: integer;
begin
  // unnötige Push/Pull entfernen
  k := 0;
  while k < Length(MidiEvents)-1 do
  begin
    if MidiEvents[k].IsPushPull and MidiEvents[k+1].IsPushPull then
      RemoveIndex(k, MidiEvents)
    else
      inc(k);
  end;

  // erste On-Note finden
  q := 0;
  while q < Length(MidiEvents)-1 do
  begin
    if MidiEvents[q].Event = 9 then
      break;
    inc(q);
  end;
  // var_len an den Anfang schieben
  k := q-1;
  while k > 0 do begin
    inc(MidiEvents[k-1].var_len, MidiEvents[k].var_len);
    MidiEvents[k].var_len := 0;
    dec(k);
  end;
end;

class procedure TEventArray.RemoveIndex(Index: integer; var MidiEvents: TMidiEventArray);
var
  i: integer;
begin
  if (Index < 0) or (Index >= Length(MidiEvents)) then
    exit;

  if Index > 0 then
    inc(MidiEvents[Index-1].var_len, MidiEvents[Index].var_len);

  for i := Index+1 to Length(MidiEvents)-1 do
    MidiEvents[i-1] := MidiEvents[i];

  SetLength(MidiEvents, Length(MidiEvents)-1);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TMidiEventPlayer.Execute;
var
  Ticks, TickOffset: double;
  Offset: double;
  NewOffset: integer;
  iEvent: integer;
  Event: TMidiEvent;
  i: integer;
  len: integer;
  P: boolean;
begin
  if Playing = nil then
    Playing := @P;
  Playing^ := true;

  len := TEventArray.PlayLength(MidiEventArr);
  Offset := MidiEventArr[0].var_len;
  NewOffset := 0;
  TickOffset := DetailHeader.GetTicks;
  iEvent := 1;
  while (iEvent < Length(MidiEventArr)) and Playing^ do
  begin
    Event := MidiEventArr[iEvent];
    inc(iEvent);
    if Event.Event <> 15 then
    begin
      MidiOutput.Send(MicrosoftIndex, Event.command, Event.d1, Event.d2);
    end;

    if Assigned(SetPlayEvent) then
      SetPlayEvent(Event);

    if Event.var_len > 0 then
      inc(NewOffset, Event.var_len);
    while (NewOffset > trunc(Offset)) and
          (iEvent < Length(MidiEventArr)) and
          Playing^ do
    begin
      Ticks := DetailHeader.GetTicks;
      Offset := Offset + (Ticks - TickOffset);
      TickOffset := Ticks;
      if Pos <> nil then
        Pos^ := DetailHeader.TicksToString(round(Offset)) +
                  ' of ' + DetailHeader.TicksToString(len);
      sleep(4);
    {$ifdef LINUX}
//      UfrmSelector.Channel_Selection.lbPlayLength.Caption := Pos^;
//      Application.ProcessMessages;
    {$endif}
    end;
  end;
  Playing^ := false;

  Event.Clear;
  if @SetPlayEvent <> nil then
    for i := 0 to 15 do
    begin
      Event.command := $80 + i;
      SetPlayEvent(Event);
    end;

  ResetMidiOut;
{$ifndef LINUX}
  Terminate;
  while not Terminated_ do
    Sleep(1);
{$endif}
end;

{$ifndef LINUX}
procedure TMidiEventPlayer.StopPlay;
begin
  if @Playing <> nil then
    Playing^ := false;
end;

function TMidiEventPlayer.Terminated_: boolean;
begin
  result := Terminated;
end;
{$endif}

function TEventArray.MakeNewSingleTrack: boolean;
var
  iEvent, iTrack: integer;
  MidiEvents: array [0..1] of TMidiEventArray;
  Event: TMidiEvent;
  GriffPitch: integer;
  Cross: boolean;
  channel: byte;
  InstrName: boolean;
  idx: integer;
  Instr: TInstrument;
  PitchArray: PPitchArray;
  InPush_: boolean;
  channels: array [0..255] of byte;

  procedure AddEvent;
  var
    l: integer;
  begin
    l := Length(MidiEvents[iTrack]);
    SetLength(MidiEvents[iTrack],l+1);
    MidiEvents[iTrack][l] := Event;
  end;

  function PitchInArray(Pitch: byte): integer;
  begin
    result := High(TPitchArray);
    while result >= 0 do
    begin
      if Pitch = PitchArray[result] then
        break;
      dec(result);
    end;
  end;

begin
  result := false;
  SetLength(SingleTrack, 0);
  InstrName := false;

  if GetCopyright = newCopy then
  begin
    if Length(TrackArr_) = 1 then
    begin
      SingleTrack := Track[0];
      result := true;
    end;
    exit;
  end;

  if GetCopyright <> griffCopy then
    exit;

  for iTrack := 0 to 1 do
  begin
    SetLength(MidiEvents[iTrack], 0);
    GriffPitch := -1;
    for iEvent := 0 to Length(Track[iTrack])-1 do
    begin
      Event := Track[iTrack][iEvent];
      if Event.command = $ff then
      begin
        if Event.d1 = 3 then
          continue;
        if Event.d1 = 4 then
        begin
          if InstrName then
            continue;
          InstrName := true;
        end;
      end else
      if Event.Event = 12 then
      begin
        continue;
      end else
      if (Event.d1 = ControlPushPull+1) or (Event.d1 = ControlPushPull+2) then
      begin
        Cross := Event.d1 = ControlPushPull+2;
        GriffPitch := Event.d2;
        continue;
      end else
      if Event.Event = 9 then begin
        if iTrack = 1 then
        begin
          if Cross then
            channel := 6
          else
            channel := 5;
        end else begin
          if GriffPitch = 0 then
            GriffPitch := Event.d1;
          channel := 1;
          if not odd(cDurLine(GriffPitch, false)) then
            inc(channel);
          if Cross then
            inc(channel, 2);
        end;
        Event.command := (Event.Event << 4) + channel;
        Cross := false;
        GriffPitch := 0;
        channels[Event.d1] := channel;
      end else
      if Event.Event = 8 then begin
        // Beim Off gleichen Kanal wie beim On verwenden.
        Event.command := (Event.Event << 4) + channels[Event.d1];
      end;
      AddEvent;
    end;
  end;

  SingleTrack := MidiEvents[0];

  // Midi-Instrumente pro Kanal einfügen.
  // Dazu 8+1 MidiEvent verschieben.
  SetLength(SingleTrack, Length(SingleTrack)+9);
  for iEvent := Length(SingleTrack)-10 downto 2 do
    SingleTrack[iEvent+9] := SingleTrack[iEvent];

  Event.Clear;
  Event.command := $C0;
  Event.d1 := 21; // Akkordeon
  for iEvent := 3 to 10 do begin
    SingleTrack[iEvent] := Event;
    inc(Event.Command);
  end;
  SingleTrack[2] := SingleTrack[1];

  // Copyright einfügen
  Event.Clear;
  Event.MakeMetaEvent(2, CopyrightNewGriff);
  SingleTrack[1] := Event;

  MergeTracks(SingleTrack, MidiEvents[1]);

  result := true;
  idx := InstrumentIndex(Instrument);
  if idx >= 0 then
  begin
    InPush_ := false;
    Instr := InstrumentsList_[idx];
    for iEvent := 0 to Length(SingleTrack)-1 do
      with SingleTrack[iEvent] do
        if (Event = 11) and (d1 = ControlPushPull) then
          InPush_ := (d2 <> 0)
        else
        if Event = 9 then
        begin
          PitchArray := nil;
          if Channel in [1..4] then
          begin
            if InPush_ then
              PitchArray := @Instr.Push.Col[Channel]
            else
              PitchArray := @Instr.Pull.Col[Channel];
          end else
          if (Command and $f) in [5..6] then
            if not Instr.BassDiatonic or InPush_ then
              PitchArray := @Instr.Bass[Channel = 6]
            else
              PitchArray := @Instr.PullBass[Channel = 6];
          if PitchArray <> nil then
          begin
            if PitchInArray(d1) < 0 then
            begin
              result := false;
          {$ifdef CONSOLE}
              writeln('error Pitch ', d1, '  row ', Channel);
          {$endif}
            end;
          end;
        end;
  end;
end;


procedure TEventArray.Repair;
var
  Instrument_: TInstrument;
  idx: integer;
  iTrack: integer;

  procedure RepairTrack(var MidiEvents: TMidiEventArray; Bass: boolean);
  var
    iEvent, iOff: integer;
    Event, NextEvent: TMidiEvent;
    InPush: boolean;
    Sound: integer;
    Cross: boolean;
    BassArr: TPitchArray;
  begin
    InPush := false;
    for iEvent := 0 to Length(MidiEvents)-2 do
    begin
      Event := MidiEvents[iEvent];
      if Event.IsPushPull then
      begin
        InPush := Event.IsPush;
        continue;
      end;

      if (Event.Event = 11) and (Event.d1 in [32, 33]) then
      begin
        NextEvent := MidiEvents[iEvent+1];
        Cross := Event.d1 = 33;
        if Bass then
        begin
          If not Instrument_.BassDiatonic or InPush then
            BassArr := Instrument_.Bass[Cross]
          else
            BassArr := Instrument_.PullBass[Cross];
          Sound := -1;
          if Event.d2 in [1..High(TPitchArray)] then
            Sound := BassArr[Event.d2];
        end else
          Sound := Instrument_.GriffToSound(Event.d2, InPush, Cross);
        if (Sound > 0) and (Sound <> NextEvent.d1) then
        begin
          iOff := iEvent+2;
          while (iOff < Length(MidiEvents)) do
            if (MidiEvents[iOff].command + 16 = NextEvent.command) and
               (MidiEvents[iOff].d1 = NextEvent.d1) then
            begin
              MidiEvents[iEvent+1].d1 := Sound;
              MidiEvents[iOff].d1 := Sound;
              break;
            end else
              inc(iOff);
        end;
      end;
    end;
  end;

begin
  if (GetCopyright <> griffCopy) or (Length(TrackArr_) <> 2) then
    exit;

  idx := InstrumentIndex(Instrument);
  if idx >= 0 then
    Instrument_ := InstrumentsList_[idx]
  else
    exit;

  for iTrack := 0 to 1 do
    RepairTrack(TrackArr_[iTrack], iTrack=1);
end;

end.

