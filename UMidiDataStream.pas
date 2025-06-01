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

unit UMidiDataStream;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  UInstrument,
{$IFnDEF FPC}
  windows,
{$ELSE}
  LCLIntf, LCLType, LMessages,
{$ENDIF}
  Classes, SysUtils,
  UMyMidiStream, UEventArray, UMidiEvent;

const
  CopyPrep = AnsiString('juerg5524.ch');

type
  TMidiSaveStream = class;
   
  // Zur Analyse von Midi-Files (.mid).
  // Zur Generierung von Midi-Files aus einem einfachen Text-File (simple file).
  TMidiDataStream = class(TMyMidiStream)
  public
    constructor Create;
    function ReadVariableLen: cardinal;
    procedure WriteVariableLen(c: cardinal);
    procedure WriteHeader(const Header: TMidiHeader);
    procedure WriteTrackHeader(Delta: integer);
  
    function ReadMidiHeader(RaiseExcept: boolean = false): boolean;
    function ReadMidiTrackHeader(var Header: TTrackHeader; RaiseExcept: boolean = false): boolean;
    function ReadMidiEvent(var event: TMidiEvent): boolean;
    function TranslateEvent(var d1: byte;
                            toDo: eTranslate;
                            const Instrument: PInstrument): boolean;

    function MakeMidiEventsArr(var Events: TMidiEventArray): boolean;
    function MakeMidiTrackEvents(var Tracks: TTrackEventArray): boolean;
    function MakeEventArray(var EventArray: TEventArray; Lyrics: boolean = false): boolean;
//    function MakePartitur(SimpleFile: TSimpleDataStream): boolean;
  end;

  // Zur Analyse von einfachen Text-Files (.txt).
  // Zur Generierung von einfachen Text-Files aus Midi-Files.
  TSimpleDataStream = class(TMyMidiStream)
  public
    // analysieren
    procedure ReadLine;
    function NextNumber: integer;
    function ReadNumber: integer;
    function EOF: boolean;

    function ReadSimpleHeader: boolean;
    function ReadSimpleTrackHeader(var TrackHeader: TTrackHeader): boolean;
    function ReadSimpleMidiEvent(var Event: TMidiEvent): boolean ;
    class function MakeSimpleDataStream(MidiDataStream: TMidiSaveStream): TSimpleDataStream;
    class function SaveMidiToSimpleFile(FileName: string; MidiDataStream: TMidiSaveStream): boolean;
    function ReadCross: boolean;
    function NextString: AnsiString;
    function ReadString: AnsiString;

    // generieren
    procedure WriteHeader(const Header: TMidiHeader);
    procedure WriteTrackHeader(Delta: integer);

    function MakeMidiFromSimpleStream: TMidiSaveStream;
  end;

  TMidiSaveStream = class(TMidiDataStream)
  public
      Titel: string;
      trackOffset: cardinal;
      constructor Create;
      procedure SetHead(DeltaTimeTicks: integer = 192);
      procedure AppendTrackHead(delay: integer = 0);
      procedure AppendHeaderMetaEvents(const Details: TDetailHeader);
      procedure AppendTrackEnd(IsLastTrack: boolean);
      procedure AppendEvent(const Event: TMidiEvent); overload;
      procedure AppendEvent(command, d1, d2: byte); overload;
      procedure AppendEvents(const Events: TMidiEventArray);
      procedure AppendTrack(const Events: TMidiEventArray);
      procedure AppendMetaEvent(EventNr: byte; b: AnsiString);

      procedure MakeMidiFile(const Events: TMidiEventArray; Details: PDetailHeader = nil);
      procedure MakeMidiTracksFile(const Tracks: TTrackEventArray);
      procedure MakeMultiTrackMidiFile(const Events: TMidiEventArray; count: integer);
      procedure MakeOergeliMidiFile(const Events: TMidiEventArray);

      class procedure SaveStreamToFile(FileName: string; var SaveStream: TMidiSaveStream);
  end;

var
  RunningWine: boolean = false;

{$if defined(CONSOLE)}
procedure MidiConverterTest(const FileName: string; var Text: System.Text);
procedure MidiConverterDirTest(const DirName: string; var Text: System.Text);
{$endif}
implementation

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
{$endif}

constructor TMidiDataStream.Create;
begin
  BigEndian := true;
end;

procedure TMidiDataStream.WriteHeader(const Header: TMidiHeader);
begin
  WriteString('MThd');
  WriteCardinal(6);     
  WriteWord(Header.FileFormat);   
  WriteWord(Header.TrackCount);
  WriteWord(Header.Details.DeltaTimeTicks);
end;

function TMidiDataStream.ReadVariableLen: cardinal;
var 
  c: byte;
begin 
  result := ReadByte;
  if (result and $80) <> 0 then
  begin
    result := result and $7f;
    repeat
      c := ReadByte;
      result := cardinal(result shl 7) + byte(c and $7f);
    until (c < $80);
  end;
end;

procedure TMidiDataStream.WriteVariableLen(c: cardinal);
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


procedure TMidiDataStream.WriteTrackHeader(Delta: integer);
begin
  WriteString('MTrk');
  WriteCardinal(0);
  WriteVariableLen(Delta);   
end;
  
function TMidiDataStream.ReadMidiHeader(RaiseExcept: boolean): boolean;
var
  Signature: cardinal;
begin
  result := false;
  
  Signature := ReadCardinal;
  if Signature <> $4D546864 then   // MThd
  begin
    if RaiseExcept then
      raise Exception.Create('Falsche Header-Signatur!');
    exit;
  end;
  ChunkSize := ReadCardinal;
  if Size - Position < ChunkSize then
  begin
    if RaiseExcept then
      raise Exception.Create('Restliche Dateigr�sse kleiner als die angegebene Chunkgr�sse!');
    exit;
  end;
  MidiHeader.Clear;
  MidiHeader.FileFormat := ReadWord;             
  MidiHeader.TrackCount := ReadWord;
  MidiHeader.Details.DeltaTimeTicks := ReadWord;

  result := ChunkSize = 6;
end;

function TMidiDataStream.ReadMidiEvent(var event: TMidiEvent): boolean;
begin
  result := false;
  // Command byte
  event.Clear;
  event.command := ReadByte;
  while (event.command < $80) and (ChunkSize > 0) do
    event.command := ReadByte;
  if ChunkSize = 0 then
    exit;
  event.d1 := ReadByte;
  if not (event.event in [$c, $d]) and (NextByte < $80) and
     (event.command <> $f0) then
    event.d2 := ReadByte;
  if not (event.event in [$f]) then
    event.var_len := ReadVariableLen;  // eigentlich auch f�r den Meta-Event ff

  result := true;
end;

function TMidiDataStream.TranslateEvent(var d1: byte;
                                        toDo: eTranslate;
                                        const Instrument: PInstrument): boolean;
var
  iCol, i, Index: integer;
begin
  iCol := 0;
  i := -1;
  if (toDo <> nothing) and (Instrument <> nil) then
  begin
    if toDo = toSound then
      i := Instrument^.GriffToSound(d1, InPull, CrossTest)
    else
      i := Instrument^.SoundToGriff(d1, InPull, iCol, Index);
    if i >= 0 then
      d1 := i;
  end;
  result := i > 0;
end;


function TMidiDataStream.ReadMidiTrackHeader(var Header: TTrackHeader; RaiseExcept: boolean = false): boolean;
var
  Signature: cardinal;
begin
  Signature := ReadCardinal;
  if Signature <> $4D54726B then              // MTrk
  begin
    if RaiseExcept then
      raise Exception.Create('Wrong Track Signatur!');
  end;

  Header.ChunkSize := ReadCardinal;
  ChunkSize := Header.ChunkSize;
  Header.DeltaTime := ReadVariableLen;
  if (Size - Position + 2 < Header.ChunkSize) then
  begin
//    if RaiseExcept then
//      raise Exception.Create('Restliche Dateigr��e kleiner als die angegebene Chunkgr��e!');
  end;
  result := true;
end;

function TMidiDataStream.MakeMidiEventsArr(var Events: TMidiEventArray): boolean;
var
  iEvent: integer;
  TrackHeader: TTrackHeader;
begin
  Position := 0;
  result := false;

  if not ReadMidiHeader(false) then
    exit;

  if MidiHeader.TrackCount <> 1 then
    exit;

  iEvent := 0;
  SetLength(Events, 10000);
  if not ReadMidiTrackHeader(TrackHeader, true) then
    exit;

  while ChunkSize > 0 do
  begin
    if iEvent > High(Events) then
      SetLength(Events, 2*Length(Events));
    if not ReadMidiEvent(Events[iEvent]) then
      break;
    if Events[iEvent].Event in [8, 9, 11, 12] then
    begin
      if (Events[iEvent].Event = 9) and (Events[iEvent].d2 = 0) then
      begin
        Events[iEvent].command := Events[iEvent].command xor $10;
        Events[iEvent].d2 := $40;
      end;
      inc(iEvent);
    end;
  end;

  SetLength(Events, iEvent);
  result := iEvent > 0;
end;

function TMidiDataStream.MakeMidiTrackEvents(var Tracks: TTrackEventArray): boolean;
var
  iEvent: integer;
  iTrack: integer;
  delay: integer;
  Event: TMidiEvent;
  TrackHeader: TTrackHeader;
begin
  Position := 0;
  result := false;
  SetLength(Tracks, 0);

  iTrack := 0;
  if not ReadMidiHeader(false) then
    exit;

  while Position < Size do
  begin
    iEvent := 0;
    if not ReadMidiTrackHeader(TrackHeader, true) then
      break;

    delay := TrackHeader.DeltaTime;
    while ChunkSize > 0 do
    begin
      if not ReadMidiEvent(Event) then
        break;

      if (iEvent = 0) and (Event.Event = 9) then
      begin
        inc(iTrack);
        SetLength(Tracks, iTrack);
        SetLength(Tracks[iTrack-1], 10000);
        with Tracks[iTrack-1][iEvent] do
        begin
          Clear;
          var_len := delay;
        end;
        inc(iEvent);
      end;

      if (iEvent > 0) and ((Event.Event in [8, 9]) or Event.IsPushPull) then
      begin
        if (Event.Event = 9) and (Event.d2 = 0) then
        begin
          Event.command := Event.command xor $10;
          Event.d2 := $40;
        end;
        Tracks[iTrack-1][iEvent] := Event;
        inc(iEvent);
      end else
      if Event.Event in [8..14] then
      begin
        if iEvent > 0 then
          inc(Tracks[iTrack-1][iEvent-1].var_len, Event.var_len)
        else
          inc(delay, event.var_len);
      end;
    end;
    if iEvent > 0 then
      SetLength(Tracks[iTrack-1], iEvent);
  end;
  result := true;
end;

function TMidiDataStream.MakeEventArray(var EventArray: TEventArray; Lyrics: boolean): boolean;
var
  iEvent: integer;
  iTrack: integer;
  Event: TMidiEvent;
  TrackHeader: TTrackHeader;
  i: integer;
  RunningStatus: byte;
  offset: integer;

  procedure AppendEvent;
  begin
    if (Event.Event = 9) and (Event.d2 = 0) then
    begin
      dec(Event.command, $10);
      Event.d2 := $40;
    end;
    inc(iEvent);
    inc(offset, Event.var_len);
    SetLength(EventArray.TrackArr[iTrack-1], iEvent);
    EventArray.TrackArr[iTrack-1][iEvent-1] := Event;
    Event.Clear;
  end;

begin
  Position := 0;
  result := false;
  EventArray.Clear;
  BigEndian := true;

  iTrack := 0;
  if not ReadMidiHeader(false) then
    exit;

  EventArray.DetailHeader := MidiHeader.Details;
  while Position + 16 < Size do
  begin
    if not ReadMidiTrackHeader(TrackHeader, true) then
      break;

    inc(iTrack);
    EventArray.SetNewTrackCount(iTrack);
    iEvent := 0;
    offset := 0;
    Event.Clear;
    Event.var_len := TrackHeader.DeltaTime;
    AppendEvent;
    while ChunkSize > 0 do
    begin
      Event.Clear;
      if not ReadMidiEvent(Event) then
        break;

      if (Event.d1 > 127) or (Event.d2 > 127) then
      begin
        NextByte;
        continue;
      end;

      if event.command = $f0 then  // universal system exclusive
      begin
        if Event.d1 = $7f then  // master volume/balance
        begin
          ReadByte; // device id
          Event.d1 := ReadByte;
        end;
        for i := 1 to event.d1-1 do
          ReadByte;
        while ReadByte <> $f7 do ;
        Event.var_len := ReadVariableLen;
        inc(EventArray.TrackArr[iTrack-1][iEvent-1].var_len, Event.var_len);
        inc(offset, Event.var_len);
        continue;
      end;

      if (Event.command = $ff) and (Event.d1 = $2f) and (Event.d2 = 0) then
      begin
       if not Lyrics and not TEventArray.HasSound(EventArray.TrackArr[iTrack-1]) then
       begin
        SetLength(EventArray.TrackArr[iTrack-1], 0);
        dec(iTrack);
        EventArray.SetNewTrackCount(iTrack);
        end;
        break;
      end;

      if event.Event = $F then
      begin
        SetLength(event.Bytes, event.d2);
        if event.d2 + 3 > ChunkSize then
          event.d2 := ChunkSize - 3;
        for i := 1 to event.d2 do
        begin
          event.Bytes[i-1] := ReadByte;
        end;
        if (event.d2 > 0) then
          Event.var_len := ReadVariableLen;
        if (event.command = $ff) then
        begin
          case event.d1 of
            1: EventArray.Text_ := BytesToAnsiString(event.Bytes);
            2: EventArray.copyright := BytesToAnsiString(event.Bytes);
            3: EventArray.TrackName[length(EventArray.TrackName)-1] := BytesToAnsiString(event.Bytes);
            4: EventArray.Instrument := BytesToAnsiString(event.Bytes);
    {        5,   // Lyrics
            51:  // set tempo
               begin
                 Event.bytes := Bytes;
                 AppendEvent;
               end;  }
            else
               EventArray.DetailHeader.SetParams(Event, event.Bytes);
          end;
        end;
        AppendEvent;
      end else
      if event.Event in [8..14] then
      begin
        RunningStatus := Event.command;
        AppendEvent;

        i := NextByte;
        if i < 0 then
          break;

        while (0 <= i) and (i < $80) do
        begin
          Event.Clear;
          Event.command := RunningStatus;
          Event.d1 := ReadByte;
          if (NextByte < $80) then
            Event.d2 := ReadByte;
          Event.var_len := ReadVariableLen;

          AppendEvent;
          i := NextByte;
        end;
      end;
    end;
  end;
  result := true;
end;

////////////////////////////////////////////////////////////////////////////////

function TSimpleDataStream.MakeMidiFromSimpleStream: TMidiSaveStream;
var
  d: TInt4;
  t: integer;
  TrackHeader_: TTrackHeader;
  NextString_: AnsiString;
  Event: TMidiEvent;
begin
  result := TMidiSaveStream.Create;

  Position := 0;
  if not ReadSimpleHeader then
    exit;

  result.MidiHeader := MidiHeader;
  result.AppendHeaderMetaEvents(MidiHeader.Details);

  while (Position + 20 < Size) do
  begin
    if not ReadSimpleTrackHeader(TrackHeader_) then
    begin
      FreeAndNil(result);
      exit;
    end;

    result.AppendTrackHead(TrackHeader_.DeltaTime);
    repeat
      Event.Clear;
      NextString_ := NextString;
      if CompareText(NextString_, cSimpleTrackHeader) = 0 then
          break;

      if (CompareText(NextString_, cPush) = 0) or
         (CompareText(NextString_, cPull) = 0) then
      begin
        Event.MakeSustain(CompareText(NextString_, cPush) = 0);
        ReadString;
        t := ReadNumber;
        if t >= 0 then
          Event.var_len := t;
        result.AppendEvent(Event);
        continue;
      end;

      if not ReadSimpleMidiEvent(Event) then
      begin
        FreeAndNil(result);
        exit;
      end;
      Readline;
      if not Event.IsEndOfTrack then
        result.AppendEvent(Event);
    until (NextByte = 0) or Event.IsEndOfTrack;
    result.AppendTrackEnd(false);
  end;
  result.Size := result.Position;
end;

function TSimpleDataStream.NextNumber: integer;
var
  pos: cardinal;
begin
  pos := Position;
  result := ReadNumber;
  Position := pos;
end;

function TSimpleDataStream.ReadNumber: integer;
var
  b: byte;
  factor: integer;
begin
  while (Position < Size) and (NextByte = ord(' ')) do
    ReadByte;

  factor := 10;
  b := NextByte;
  if b = ord('0') then
  begin
    ReadByte;
    if NextByte = ord('x') then
      b := ord('$')
    else
      Position := Position - 1;
  end;
  if b = ord('$') then
  begin
    factor := 16;
    ReadByte
  end else
  if (b < ord('0')) or (b > ord('9')) then
  begin 
    result := -1;
    exit;
  end;
  result := 0;

  repeat
    if NextByte in [ord('0')..ord('9')] then
      result := factor*result + ReadByte - ord('0')
    else
    if (factor = 16) then
      if NextByte in [ord('A')..ord('F')] then
        result := factor*result + ReadByte - ord('A') + 10
      else
      if NextByte in [ord('a')..ord('f')] then
        result := factor*result + ReadByte - ord('a') + 10
      else
        break
    else
      break;
  until (false);         
end;   

procedure TSimpleDataStream.ReadLine;
begin
  while NextByte >= ord(' ') do
    ReadByte;
  while (NextByte <> 0) and (NextByte <= ord(' ')) do   // skip empty lines
  begin
    while NextByte in [1..ord(' ')] do
      ReadByte;
  end;
end;

function TSimpleDataStream.EOF: boolean;
begin
  result := (Position >= Size) or (NextByte = 0);
end;

procedure TSimpleDataStream.WriteHeader(const Header: TMidiHeader);
begin
  with Header do
  begin
    WritelnString(cSimpleHeader + ' ' + IntToStr(ord(FileFormat)) + ' ' + 
                  IntToStr(TrackCount) + ' ' + IntToStr(Details.DeltaTimeTicks) +
                  ' ' + IntToStr(Details.beatsPerMin));
  end;
end;

procedure TSimpleDataStream.WriteTrackHeader(Delta: integer);
begin
  WritelnString(cSimpleTrackHeader + ' ' + IntToStr(Delta));
end;

class function TSimpleDataStream.MakeSimpleDataStream(MidiDataStream: TMidiSaveStream): TSimpleDataStream;
var
  TrackHeader: TTrackHeader;
  event: TMidiEvent;
  i: integer;
  b: byte;
  ba: array of byte;
  Offset, takt: integer;
  d: double;
begin
  result := TSimpleDataStream.Create;

  result.SetSize(10000000);
  result.Position := 0;
  MidiDataStream.Position := 0;

  try
    result.MidiHeader := MidiDataStream.MidiHeader;
    if not MidiDataStream.ReadMidiHeader(false) then
      exit;
      
    result.WriteHeader(MidiDataStream.MidiHeader);
    result.MidiHeader.Details.DeltaTimeTicks := MidiDataStream.MidiHeader.Details.DeltaTimeTicks;
    MidiDataStream.MidiHeader := result.MidiHeader;
    Offset := 0;

    while MidiDataStream.Position < MidiDataStream.Size do
    begin
      if not MidiDataStream.ReadMidiTrackHeader(TrackHeader, true) then
        exit;

      result.WriteTrackHeader(TrackHeader.DeltaTime);
      Offset := TrackHeader.DeltaTime;

      while MidiDataStream.ChunkSize > 0 do
      begin
        if not MidiDataStream.ReadMidiEvent(event) then
          break;

        case event.Event of
          $F: begin
              SetLength(ba, 0);
              result.WriteString(cSimpleMetaEvent + ' ' + IntToStr(event.command) + ' ' + 
                IntToStr(event.d1) + ' ' + IntToStr(event.d2));
              for i := 1 to event.d2 do begin
                b := MidiDataStream.ReadByte;
                result.WriteString(' ' + IntToStr(b));
                SetLength(ba, Length(ba)+1);
                ba[Length(ba)-1] := b;
              end;
              if event.d2 > 0 then 
              begin
                i := MidiDataStream.ReadVariableLen;
                result.WriteString(' ' + IntToStr(i));
                inc(Offset, i);
              end;
              if event.d1 <= 6 then
              begin
                result.WriteString('  ');
                for i := 0 to Length(ba)-1 do
                  if (ba[i] >= ord(' ')) and (ba[i] <= 126) then
                    result.WriteString(AnsiChar(ba[i]))
                  else
                    result.WriteString('.');
              end;
              result.MidiHeader.Details.SetTimeSignature(event, ba);
              result.MidiHeader.Details.SetBeatsPerMin(event, ba);
              result.MidiHeader.Details.SetDurMinor(event, ba);
            end;
          8..14: begin
              if HexOutput then
                result.WriteString(Format('%5d $%2.2x $%2.2x $%2.2x', 
                                   [event.var_len, event.command, event.d1, event.d2]))
              else
                result.WriteString(Format('%5d %3d %3d %3d', 
                                   [event.var_len, event.command, event.d1, event.d2]));
              if event.Event = 9 then
              begin
                takt := Offset div result.MidiHeader.Details.DeltaTimeTicks;
                if result.MidiHeader.Details.measureDiv = 8 then
                  takt := 2*takt;
                d := result.MidiHeader.Details.measureFact;
                result.WriteString(Format('  Takt: %.2f', [takt / d + 1]));
              end;
              inc(Offset, event.var_len);
            end;
          else begin end;
        end;
        if event.command >= $80 then begin
          repeat
            if MidiDataStream.ChunkSize = 0 then
              break;
            b := MidiDataStream.NextByte;
            if (b < $80) then
              result.WriteString(Format(' %d', [MidiDataStream.ReadByte]));
          until b >= $80;
          if event.Event = 9 then
          begin
            result.WriteString(MidiNote(event.d1));
          end;
          result.WritelnString('');
        end;
      end;
    end;        
 
  except
    on E: Exception do
    begin
    {$if defined(CONSOLE)}
      system.writeln('Fehler: ' + E.Message + ' an Position $' + IntToHex(MidiDataStream.Position, 0));
    {$endif}
    end;
  end;
  result.SetSize(result.Position);
end;

class function TSimpleDataStream.SaveMidiToSimpleFile(FileName: string; MidiDataStream: TMidiSaveStream): boolean;
var
  SimpleDataStream: TSimpleDataStream;
begin
  result := false;
  try
    SimpleDataStream := TSimpleDataStream.MakeSimpleDataStream(MidiDataStream);
    result := SimpleDataStream <> nil;
    if result then
      SimpleDataStream.SaveToFile(FileName + '.txt');
  finally
    SimpleDataStream.Free;
  end;
end;

function TSimpleDataStream.ReadSimpleHeader: boolean;
begin
  result := NextByte = ord('H');
  if result then
  begin
    SkipBytes(length(cSimpleHeader));

    MidiHeader.FileFormat := ReadNumber;
    MidiHeader.TrackCount := ReadNumber;
    MidiHeader.Details.DeltaTimeTicks := ReadNumber;
    MidiHeader.Details.beatsPerMin := ReadNumber;
  end;
  ReadLine;
end;

function TSimpleDataStream.ReadSimpleTrackHeader(var TrackHeader: TTrackHeader): boolean;
begin
  result := NextByte = ord('N');
  if result then 
  begin
    SkipBytes(length(cSimpleTrackHeader));
    TrackHeader.DeltaTime := ReadNumber;
    ReadLine;
  end;
end;

function TSimpleDataStream.ReadSimpleMidiEvent(var event: TMidiEvent): boolean;
var 
  i: integer;
  IsMeta: boolean;
begin
  result := true;

  event.Clear;
  IsMeta := NextString = cSimpleMetaEvent;
  if IsMeta  then
    SkipBytes(length(cSimpleMetaEvent));
  if not IsMeta then
    event.var_len := ReadNumber;
  event.command := ReadNumber;   // command
  event.d1 := ReadNumber;   // d1
  event.d2 := ReadNumber; // d2

  if IsMeta then
  begin
    SetLength(event.bytes, event.d2);
    for i := 0 to event.d2-1 do
      event.bytes[i] := ReadNumber;
    event.var_len := ReadNumber;
  end;
end;

function TSimpleDataStream.ReadString: AnsiString;
begin
  while NextByte = ord(' ') do
    ReadByte;
  result := '';
  while AnsiChar(NextByte) in ['A'..'Z', '-', '_', 'a'..'z'] do
    result := result + AnsiChar(ReadByte); 
end;

function TSimpleDataStream.NextString: AnsiString;
var
  pos: cardinal;
begin
  pos := Position;
  result := ReadString;
  Position := pos;
end;

function TSimpleDataStream.ReadCross: boolean;
var
  s: AnsiString;
begin
  s := ReadString;
  result := s = 'Cross';
end;


////////////////////////////////////////////////////////////////////////////////

constructor TMidiSaveStream.Create;
begin
  inherited;

  Titel := '';
  self.SetSize(1000000);
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
  SetSize(1000000);
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

procedure TMidiSaveStream.AppendEvents(const Events: TMidiEventArray);
var
  i: integer;
  count: integer;
begin
  count := Length(Events);
  if count < 2 then
    exit;

  i := 0;
  if Events[0].command = 0 then
  begin
    Position := Position-1;
    WriteVariableLen(Events[0].var_len);
    inc(i);
  end;

  while i < count do
  begin
    //if Events[i].command <> 0 then
      AppendEvent(Events[i]);
    inc(i);
  end;
end;

procedure TMidiSaveStream.AppendTrack(const Events: TMidiEventArray);
begin
  AppendTrackHead;
  AppendEvents(Events);
  AppendTrackEnd(false);
end;

procedure TMidiSaveStream.MakeMidiFile(const Events: TMidiEventArray;
  Details: PDetailHeader);
begin
  SetHead;
  if Details <> nil then
    AppendHeaderMetaEvents(Details^);
  AppendTrack(Events);
  Size := Position;
end;

procedure TMidiSaveStream.MakeMidiTracksFile(const Tracks: TTrackEventArray);
var
  iTrack: integer;
begin
  SetHead;
  for iTrack := 0 to Length(Tracks)-1 do
    AppendTrack(Tracks[iTrack]);
  Size := Position;
end;

procedure TMidiSaveStream.MakeMultiTrackMidiFile(const Events: TMidiEventArray; count: integer);
var
  channel: byte;
  delay: integer;
  i, iMyEvent: integer;
  MyEvents: TMidiEventArray;
begin
  SetHead;
  SetLength(MyEvents, count);
  for channel := 0 to 15 do
  begin
    iMyEvent := 0;
    delay := 0;
    for i := 0 to count-1 do
    begin
      if (i = 0) and (Events[0].command = 0) then
      begin
//        delay := Events[0].var_len; // mit wave synchronisieren
      end else
      if (Events[i].Channel = channel) and (Events[i].Event in [8, 9, 11]) then
      begin
        MyEvents[iMyEvent] := Events[i];
        inc(iMyEvent);
      end else
      if iMyEvent > 0 then
        inc(MyEvents[iMyEvent - 1].var_len, Events[i].var_len)
      else
        inc(delay, Events[i].var_len);
    end;
    if iMyEvent > 0 then begin
      SetLength(MyEvents, iMyEvent);
      AppendTrackHead(delay);
      AppendEvent($c0 + channel, $15, 0);   // accordion
      AppendEvents(MyEvents);
      AppendTrackEnd(true);
    end;
  end;
  SetLength(MyEvents, 0);
end;

procedure TMidiSaveStream.MakeOergeliMidiFile(const Events: TMidiEventArray);
var
  channel: byte;
  delay: integer;
  i, iMyEvent: integer;
  MyEvents: TMidiEventArray;
  count: integer;
begin
  count := Length(Events);
  SetHead;
  SetLength(MyEvents, count);
  for channel := 0 to 15 do
  begin
    iMyEvent := 0;
    delay := 0;
    for i := 0 to count-1 do
    begin
      if (i = 0) and (Events[0].command = 0) then
      begin
        delay := Events[0].var_len; // mit wave synchronisieren
      end else
      if (Events[i].Channel = channel) and (Events[i].Event in [8, 9, 11]) then
      begin
        MyEvents[iMyEvent] := Events[i];
        inc(iMyEvent);
      end else
      if iMyEvent > 0 then
        inc(MyEvents[iMyEvent - 1].var_len, Events[i].var_len)
      else
        inc(delay, Events[i].var_len);
    end;
    if iMyEvent > 0 then begin
      SetLength(MyEvents, iMyEvent);
      AppendTrackHead(delay);
      AppendEvent($c0 + channel, $15, 0);   // accordion
      AppendEvents(MyEvents);
      AppendTrackEnd(true);
    end;
  end;
  SetLength(MyEvents, 0);
end;

class procedure TMidiSaveStream.SaveStreamToFile(FileName: string; var SaveStream: TMidiSaveStream);
begin
  if SaveStream <> nil then
    SaveStream.SaveToFile(FileName);
  SaveStream.Free;
  SaveStream := nil;
end;

////////////////////////////////////////////////////////////////////////////////

{$if defined(CONSOLE)}
procedure MidiConverterTest(const FileName: string; var Text: System.Text);
var
  SimpleFile: TSimpleDataStream;
  MidiFile, NewMidi: TMidiDataStream;
  pos: integer;
  Instrument: PInstrument;
begin
  SimpleFile := TSimpleDataStream.Create;
  MidiFile := TMidiDataStream.Create;
  NewMidi := TMidiDataStream.Create;
  try
    Instrument := @b_Oergeli;
    writeln(Text, '---> ' + Filename);
    MidiFile.LoadFromFile(FileName);
    {
    if not SimpleFile.MakeSimpleFile(MidiFile, toSound, Instrument) then
    begin
      writeln(Text, 'File not converted to simple file: ' + Filename);
      exit;
    end;

    if not NewMidi.MakeMidiFile(SimpleFile, toGriff, Instrument) then begin
      writeln(Text, 'File not converted to midi file: ' + Filename);
      exit;
    end;
    }
    pos := NewMidi.Compare(MidiFile);
    if (pos < NewMidi.Size) or (pos < MidiFile.Size) then
      writeln(Text, Format('%x (%d) %x  %x', [pos, pos, NewMidi.size, MidiFile.Size]));
  finally
    SimpleFile.Free;
    MidiFile.Free;
    NewMidi.Free;
  end;
end;

procedure MidiConverterDirTest(const DirName: string; var Text: System.Text);
var
  SR: TSearchRec;
  s: string;
begin
  if FindFirst(DirName + '*.*', faAnyFile, SR) = 0 then
  begin
    repeat
      s := DirName + SR.Name;
      if SR.Name[1] = '.' then
      else
      if SR.Attr = faDirectory then
        MidiConverterDirTest(s + '/', Text)
      else 
      if SysUtils.ExtractFileExt(SR.Name) = '.mid' then
        MidiConverterTest(s, Text);
    until FindNext(SR) <> 0;
    SysUtils.FindClose(SR);
  end;
end;
{$endif}

initialization

finalization

end.
