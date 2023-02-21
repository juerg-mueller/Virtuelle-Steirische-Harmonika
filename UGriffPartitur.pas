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
unit UGriffPartitur;

{$if defined(LAZARUS)}
  {$mode Delphi, objfpc}{$H+}
{$endif}

{$define _OldStyle}

interface

uses
{$if defined(DCC)}
  AnsiStrings,
{$endif}
  Classes, SysUtils, Types, Variants, Windows,
  UInstrument, UMyMemoryStream, UMyMidiStream, UEventArray,
  UGriffEvent, UFormHelper, UMidiEvent;

const
  row_height = 15;
  pitch_width = 64;//48; // quarter
  rows = 23;
  MoveVert = 20;
  LoadStartPush = true;
  MaxGriffIndex = 24;


const MuseScoreTPC : array [0..11] of byte =
      (14, 14, 16, 16, 18, 13, 13, 15, 15, 17, 19, 19);

type
  TColor = DWord;
   
  PPlayProc = procedure (Sender: TObject) of object;
  PPlayRectProc = procedure (rect: TRect) of object;
  PSaveProc = procedure (Sender: TObject) of object;


  // indices to GriffEvents
  TPlayRecord = record
    iEvent: integer;
    iVolta: integer;
    iStartEvent: integer;
    iStartVolta: integer;
    procedure Clear;
  end;


//  PGriffPartitur = ^TGriffPartitur;
  TGriffPartitur = class
  public
    fSelected: integer;
    function GetTotalDuration: integer;
    procedure AppendEvent(const Event: TGriffEvent);
    procedure DeleteEvent(Index: integer);
    function AufViertelnotenAufrunden: boolean;
  public
    PartiturLoaded: boolean;
    PartiturFileName: string;
    GriffHeader: TGriffHeader;
    GriffEvents: TGriffEventArray;
    CopyEvents: TGriffEventArray; // buffer for ctrl-x, -c, -v

    // Play-Variablen
    StopPlay: boolean;
    noSound: boolean;
    noTreble: boolean;
    noBass: boolean;
    trimNote: boolean;
    PlayFactor: double;
    PlayDelay: integer;
    playLocation: integer;
    iSkipEvent: integer;
    iAEvent, iBEvent: integer;
    Volume: double;
    IsPlaying: boolean;
    Instrument: TInstrument;

    Rubber_In_Push: boolean;
    rectRubberBand : TRect;
    bRubberBand : boolean;
    bRubberBandOk : boolean;
    BackEvent: integer;
    ColorNote: Tcolor;
    ColorSelected: TColor;
    UseEllipses: boolean;
    PlayEvent: TPlayRecord;

    DoPlay: PPlayProc;
    DoSave: PSaveProc;
    DoPlayRect: PPlayRectProc;

    constructor Create;
    destructor Destroy; override;

    procedure AppendGriffEvent(GriffEvent: TGriffEvent);
    procedure InsertNewEvent(Index: Integer; Mute: boolean = false);
    procedure DeleteGriffEvent(Index: integer);
    function GetDrawDuration(Index: integer; In__Push: boolean): integer;

    procedure Clear;
    procedure Unselect;
    procedure SetRubberOff;

    function LoadFromEventPartitur(const EventPartitur: TEventArray; AsGriffPartitur: boolean = false): boolean;
    function LoadFromRecorded(const EventPartitur: TEventArray): boolean;
    function AppendEventArray(const Events: TMidiEventArray): boolean;
    function LoadFromGriffFile(const FileName: string): boolean;
    procedure LoadChanges;
    function SaveToGriffFile(const FileName: string): boolean;
//    function SavePasFile(const FileName: string): boolean;
    function SaveToMidiFile(const FileName: string; realGriffschrift: boolean): boolean;
    function SaveToNewMidiFile(const FileName: string): boolean;

    function AppendFile(const FileName: string): boolean;
    procedure PurgeBass;
    procedure DelayBass(delay: integer);
  //  function IsTriole(iEvent: integer; Ticks: integer): boolean;
  //  function TriolenTest(iEvent: integer): integer;

{$if defined(__INSTRUMENTS__)}
    procedure OptimisePairs(iFirst, iLast: integer);
    function CheckSustain: boolean;
    procedure TransposeInstrument(delta: integer);
{$endif}
    procedure SortEvents;
    procedure RepeatToRest;
    procedure SetBassGriff;
    function GetRelTotalDuration: integer;
    function ScreenToNotePoint(var NotePoint: TPoint; ScreenPoint: TPoint): boolean;
    function SearchGriffEvent(const NotePoint: TPoint): integer;
    function SetInstrument(Name: AnsiString): boolean;
    procedure SetSelected(Index: integer);
    function SelectedEvent: PGriffEvent;
    procedure InsertNewSelected(const GriffEvent: TGriffEvent);
    function ChangeNote(Event: PGriffEvent; WithSound: boolean): boolean;
    function AlternateNote(Event: PGriffEvent): boolean;
    procedure MakeLongerPitches;
    procedure DoSoundPitch(Event: TGriffEvent);
    procedure DoSoundPitchs(const EventPitchs: TEventPitchArr);
    function TickToScreen(tick: integer): integer;

    function KeyDown(var Key: Word; Shift: TShiftState): boolean;

    procedure DoStopPlay;
    procedure StartPlay;
    procedure Play(var PlayEvent: TPlayRecord);
    procedure PlayAmpel(var PlayEvent: TPlayRecord; PlayDelay: integer);
    function PlayControl(CharCode: word; KeyData: LongInt): boolean;

    // MidiPartitur uses this
    function LoadFromTrackEventArray(const Partitur: TEventArray): boolean;
    function DeleteMp3(VelocityDelta: byte): boolean;
    procedure DeleteDouble;
    procedure BassSynch;

    // not used
    procedure NewVelocity;

    property UsedEvents: integer read GriffHeader.UsedEvents;
    property Selected: integer read fSelected write SetSelected;
    property quarterNote: word read GriffHeader.Details.DeltaTimeTicks;
  end;


var
  GriffPartitur_: TGriffPartitur;


implementation

uses
  System.Zip,
{$if defined(__AMPEL__)}
  UAmpel,
{$endif}
{$ifdef __FRM_GRIFF__}
  UfrmGriff,
{$endif}
  UGriffArray, Midi,  UXmlNode, UXmlParser;

////////////////////////////////////////////////////////////////////////////////

procedure SetAmpel(Event: TGriffEvent; On_: boolean);
begin
  with Event do
    frmAmpel.AmpelEvents.SetAmpel(GetRow, GetIndex, InPush and On_, On_);
end;


////////////////////////////////////////////////////////////////////////////////



procedure TGriffPartitur.AppendEvent(const Event: TGriffEvent);
begin
  if Length(GriffEvents) < 1000 then
    SetLength(GriffEvents, 1000)
  else
  if High(GriffEvents) <= UsedEvents then
    SetLength(GriffEvents, 2*Length(GriffEvents));

  GriffEvents[UsedEvents] := Event;
  inc(GriffHeader.UsedEvents);
end;

procedure TGriffPartitur.DeleteEvent(Index: integer);
var
  iEvent: integer;
begin
  if (Index >= 0) and (Index < UsedEvents) then
  begin
    for iEvent := Index to UsedEvents-2 do
      GriffEvents[iEvent] := GriffEvents[iEvent+1];
    dec(GriffHeader.UsedEvents);
  end;
end;

procedure TGriffPartitur.NewVelocity;
var
  i, k, d: integer;
  count: integer;
  max, iMax: integer;
  r: double;
  ind: array [0..1000] of integer;
begin
  count := 0;
  for i := 0 to 1000 do
    ind[i] := 0;

  i := 0;
  while (i < UsedEvents) and (GriffEvents[i].NoteType = ntDiskant) do
    inc(i);

  k := i + 1;
  while (k < UsedEvents) do
  begin
    while (k < UsedEvents) and (GriffEvents[k].NoteType = ntDiskant) do
      inc(k);

    if  k >= UsedEvents then
      break;

    d := abs(GriffEvents[k].AbsRect.Left - GriffEvents[i].AbsRect.Left);
    if d < 1000 then
      inc(ind[d]);
    inc(count);
    i := k;
    k := i + 1;
  end;
  iMax := 0;
  Max := 0;
  for i := 80 to 400 do
  begin
    d := 0;
    for k := -5 to 5 do
      inc(d, ind[i+k]*(10-abs(k)));
    if d > Max then
    begin
      Max := d;
      iMax := i;
    end;
  end;
{$if defined(CONSOLE)}
  writeln('iMax = ', iMax);
{$endif}
  if iMax > 300 then
    iMax := iMax div 2;

  if (abs(GriffHeader.Details.DeltaTimeTicks - iMax) > 4) and
     (count > 10) and (iMax > 60) then
  begin
    GriffHeader.Details.DeltaTimeTicks := 192;
    r := 192.0/iMax;
    for i := 0 to UsedEvents-1 do
      with GriffEvents[i].AbsRect do
      begin
        d := round(Width*r);
        Left := round(Left*r);
        Width := d;
      end;
    GriffHeader.Details.beatsPerMin := round(GriffHeader.Details.beatsPerMin*r);
    SortEvents;
  end;
end;

procedure TGriffPartitur.DoSoundPitch(Event: TGriffEvent);
begin
  if not noSound and
     (Event.NoteType in [ntDiskant, ntBass]) then
  begin
    SetAmpel(Event, true); // Selected: Ampel wird in Wine nicht angezeigt!
    Midi.DoSoundPitch(Event.GetSoundPitch(Instrument), true);
    Sleep(200);
    Midi.DoSoundPitch(Event.GetSoundPitch(Instrument), false);
    SetAmpel(Event, false);
  end
end;

procedure TGriffPartitur.DoSoundPitchs(const EventPitchs: TEventPitchArr);
var
  i: integer;
begin
  for i := 0 to High(EventPitchs) do
  begin
    SetAmpel(GriffEvents[EventPitchs[i]], true);
    Midi.DoSoundPitch(GriffEvents[EventPitchs[i]].GetSoundPitch(Instrument), true);
  end;
  Sleep(500);
  for i := 0 to High(EventPitchs) do
  begin
    SetAmpel(GriffEvents[EventPitchs[i]], false);
    Midi.DoSoundPitch(GriffEvents[EventPitchs[i]].GetSoundPitch(Instrument), false);
  end;  
end;
    
procedure TGriffPartitur.DeleteDouble;
var
  iEvent, k: integer;
begin
  for iEvent := 0 to UsedEvents-1 do
    GriffEvents[iEvent].AbsRect.Height := 1;
  for iEvent := 0 to UsedEvents-2 do
  begin
    k := iEvent+1;
    while k < UsedEvents do
      if GriffEvents[iEvent].IsEqual(GriffEvents[k]) then
      DeleteEvent(k)
    else
      inc(k);
  end;
end;

procedure TGriffPartitur.DeleteGriffEvent(Index: integer);
var
  i: integer;
begin
  i := Index;
  if UsedEvents > 1 then
  begin
    if (0 <= Index) and (Index < UsedEvents) then
    begin
      dec(GriffHeader.UsedEvents);
      while Index < UsedEvents do
      begin
        GriffEvents[Index] := GriffEvents[Index+1];
        inc(Index);
      end;
     // dec(i);
      if i >= 0 then
      begin
        ChangeNote(@GriffEvents[i], true);
      end;
    end;
  end;
end;

procedure TGriffPartitur.InsertNewEvent(Index: Integer; Mute: boolean);
var
  Event: TGriffEvent;
begin
  if (UsedEvents = 0) then
  begin
    with Event do
    begin
      Clear;
      SoundPitch := Instrument.Pull.Col[2][5];
      GriffPitch := 71;
      AbsRect.Top := 11;
      AbsRect.Height := 1;
      AbsRect.Width := GriffHeader.Details.DeltaTimeTicks;
    end;
    AppendEvent(Event);
  end else begin
    if Index >= UsedEvents then
      Index := UsedEvents-1;
    if Index < 0 then
      Event := GriffEvents[UsedEvents-1]
    else
      Event := GriffEvents[Index];

    with Event do
    begin
      if NoteType = ntBass then
        AbsRect.Top := -1
      else
      if AbsRect.Top > 1 then
        dec(AbsRect.Top, 2)
      else
        AbsRect.Top := 3; 
      AbsRect.Height := 1;
      Repeat_ := rRegular;
      if (GetKeyState(vk_capital) <> 1) then
      begin
        if NoteType = ntBass then
          AbsRect.Offset(GriffHeader.Details.DeltaTimeTicks, 0)
        else
          AbsRect.Offset(AbsRect.Width, 0);
      end;
    end;
    ChangeNote(@Event, not Mute);
    AppendEvent(Event);
    fSelected := UsedEvents-1;
    SortEvents;
  end;
end;


function TGriffPartitur.ChangeNote(Event: PGriffEvent; WithSound: boolean): boolean;
var
  Line: integer;
  col: byte;
  VocalArr : PVocalArray;
  PitchArr: PPitchArray;
begin
  result := false;
  // massgebend sind AbsRect.Top (Linie), Cross und Push

  with Event^ do
  begin
    if NoteType = ntBass then
    begin
      if Instrument.BassDiatonic and not Event.InPush then
        SoundPitch := Instrument.PullBass[Cross, GriffPitch]
      else
        SoundPitch := Instrument.Bass[Cross, GriffPitch];
    end else
    if NoteType = ntDiskant then    
    begin
      Line := AbsRect.Top;
      if not Line in [0..2*Instrument.GetMaxIndex(col)] then
        exit;
      if odd(Line) and not Instrument.bigInstrument then
        Cross := false;
      with Instrument do
      begin
        if InPush then
          VocalArr := @Push
        else
          VocalArr := @Pull;

        if odd(Line) then
        begin
          if bigInstrument and Cross then
            PitchArr := @VocalArr.Col[4]
          else
            PitchArr := @VocalArr.Col[2]
        end else
        if Cross then
          PitchArr := @VocalArr.Col[3]
        else
          PitchArr := @VocalArr.Col[1];

        if bigInstrument then
        begin
          if Line < 0 then
            Line := 0
          else
          if Line > 24 then
            Line := 24;
          if Cross then
          begin
            if Line < 2 then
              Line := 2
            else
            if Line > 22 then
              Line := 22;
          end;
        end;
        AbsRect.Top := Line;
        AbsRect.Height := 1;
        SoundPitch := PitchArr^[(Line div 2) {+ 1}];
        GriffPitch := IndexToGriff(Line);
      end;
    end;
    if WithSound and (SoundPitch > 0) then
      DoSoundPitch(Event^);
  end;
  result := true;
end;

function TGriffPartitur.AlternateNote(Event: PGriffEvent): boolean;
var
  Line, Col, i, c: integer;
  VocalArr : PVocalArray;
  BassArr: TBassArray;
  res : integer;

  function Find(Pitch: byte; const Arr: TPitchArray): integer;
  var
    i: integer;
  begin
    result := -1;
    for i := Low(TPitchArray) to High(TPitchArray) do
      if Pitch = Arr[i] then
      begin
        result := i;
        break;
      end;
  end;

begin
  result := false;
  Col := 0;
  if Event^.NoteType = ntBass then
  begin
    if Instrument.BassDiatonic and not Event.InPush then
      BassArr := Instrument.PullBass
    else
      BassArr := Instrument.Bass;

    res := -1;
    Line := Event.GriffPitch;
    for i := 0 to 9 do
      if BassArr[not Event.Cross, i] = Event.SoundPitch then
      begin
        res := i;
        if Col = 5 then
          Event.Cross := not Event.Cross;
        break;
      end;

    if res < 0 then
      for i := 0 to 9 do
        if (BassArr[Event.Cross, i] = Event.SoundPitch) and (i <> Line) then
        begin
          res := i;
          break;
        end;

    if res > 0 then
    begin
      Event.GriffPitch := res;
      ChangeNote(Event, true);
    end;

    exit;
  end;

  // massgebend sind AbsRect.Top (Linie), Cross und Push
  with Event^ do
  begin
    Line := AbsRect.Top;
    if odd(Line) then
    begin
      Col := 2;
      if Cross and Instrument.bigInstrument then
        Col := 4;
    end else begin
      Col := 1;
      if Cross then
        Col := 3;
    end;
    if InPush then
      VocalArr := @(Instrument.Push)
    else
      VocalArr := @(Instrument.Pull);

    res := -1;
    // in der gültigen Reihe weitersuchen
    for i := line + 1 to High(TPitchArray) do
      if SoundPitch = VocalArr^.Col[col, i] then
      begin
        res := 2*i;
        if not odd(col) then
          inc(res);
        Line := res;
        break;
      end;

    if res < 0 then
    begin
      // in allen anderen Reihen suchen
      for i := 1 to 3 do
      begin
        c := i + col;
        if c >= 5 then
          dec(c, 4);
        res := Find(SoundPitch, VocalArr^.Col[c]);
        if res >= 0 then begin
          res := 2*res;
          if not odd(c) then
            inc(res);
          Line := res;
          Cross := c >= 3;
          break;
        end;
      end;
    end;

    if res >= 0 then
    begin
      GriffPitch := IndexToGriff(Line);
      AbsRect.Top := Line;
      AbsRect.Height := 1;
      result := true;
    end;
  end;
end;

constructor TGriffPartitur.Create;
begin
  inherited;

  Clear;

  SetInstrument(InstrumentsList_[0].Name);
  StopPlay := false;
  noSound := false;
  noBass := false;
  trimNote := false;
  PlayDelay := 0;
  //In_Push := false;
  iVirtualMidi := -1;
  
  SetRubberOff;
  ColorNote := $ffffff;
  ColorSelected := $d0d0d0;
  UseEllipses := true;

  DoPlay := nil;
  DoSave := nil;
  DoPlayRect := nil;
  playLocation := -1;
  PlayFactor := 1.0;
  Volume := 0.7;
  IsPlaying := false;
end;

destructor TGriffPartitur.Destroy;
begin
  Clear;

  inherited;
end;

function TGriffPartitur.SelectedEvent: PGriffEvent;
begin
  result := nil;
  if Selected >= UsedEvents then
    fSelected := UsedEvents-1;
  if (Selected >= 0) then
    result := @GriffEvents[Selected];
end;

procedure TGriffPartitur.Clear;
begin
  SetLength(GriffEvents, 0);
  PartiturLoaded := false;
  PartiturFileName := '';
  GriffHeader.Version := 1;
  GriffHeader.UsedEvents := 0;
  GriffHeader.Details.Clear;
  
  Unselect;
end;

function TGriffPartitur.GetTotalDuration: integer;
var
  iEvent: integer;
begin
  result := 0;
  for iEvent := 0 to GriffHeader.UsedEvents-1 do
    if GriffEvents[iEvent].AbsRect.Right > result then
      result := GriffEvents[iEvent].AbsRect.Right;
end;

function TGriffPartitur.GetRelTotalDuration: integer;
begin
  result := GetTotalDuration;
  if GriffHeader.Details.measureDiv = 8 then
    result := 2*result;
  result := result div quarterNote;
end;

procedure TGriffPartitur.SortEvents;
var
  Sel: integer;
begin
  Sel := Selected;
  SetLength(GriffEvents, GriffHeader.UsedEvents);
  TGriffArray.SortGriffEvents(GriffEvents, Sel);

  fSelected := Sel;
end;

{$if false}
function TGriffPartitur.SavePasFile(const FileName: string): boolean;
var
  OutFile: System.Text;
  iEvent: integer;  

  function ToBool(b: boolean): string;
  begin
    if b then
      result := 'true'
    else
      result := 'false';
  end;
  
begin
  system.Assign(OutFile, FileName);
  system.Rewrite(OutFile);

  writeln(OutFile, 'unit GriffPartitur;');
  writeln(OutFile);
  writeln(OutFile, 'interface');
  writeln(OutFile);
  writeln(OutFile, 'uses UGriffPartitur;');
  writeln(OutFile);
  writeln(OutFile, 'const');
  writeln(OutFile);
{  with GriffHeader do
    writeln(OutFile, '  GriffHeader: TGriffHeader = (', ' UsedEvents: ', UsedEvents,
            '; quarterNote: ', quarterNote, '; smallestNote:', smallestNote,
            '; measureFact: ', measureFact, '; measureDiv: ', measureDiv, 
            '; Instrument: ''', Instrument, ''');');
 } writeln(OutFile);
  writeln(OutFile, '  Griff_Partitur: array [0..', GriffHeader.UsedEvents-1, '] of TGriffEvent ='); 
  writeln(OutFile, '    (');
  for iEvent := 0 to GriffHeader.UsedEvents-1 do
  begin
    with GriffEvents[iEvent] do
    begin
      write(OutFile,
        Format('      (SoundPitch: %d; GriffPitch: %d; Cross: %s; InPush: %s; AbsRect: (Left: %d; Top: %d; Right: %d; Bottom: %d))',
               [SoundPitch, GriffPitch, ToBool(Cross), ToBool(InPush), AbsRect.Left, AbsRect.Top, AbsRect.Right, AbsRect.Bottom]));
    end;        
    if iEvent <> GriffHeader.UsedEvents-1 then
      write(OutFile, ',');
    writeln(OutFile);
  end;
  writeln(OutFile, '    );');
  writeln(OutFile);
  writeln(OutFile, 'implementation');
  writeln(OutFile);
  writeln(OutFile);
  writeln(OutFile, ' end.');

  system.Close(OutFile);
  result := true;
end;
{$endif}
function TGriffPartitur.LoadFromEventPartitur(const EventPartitur: TEventArray; AsGriffPartitur: boolean): boolean;
var
  iEvent: integer;
  delay: integer;
  GriffEvent: TGriffEvent;
  In_Push: boolean;
  Guard: byte;
  iMidiTrack: integer;
  IsCross: boolean;
  copyright: TCopyright;
  _Repeat: TRepeat;
  PTrack: PMidiEventArray;
  Event: TMidiEvent;
begin
  Clear;
  
  result := EventPartitur.TrackCount > 0;
  if not result then
    exit;

  IsCross := false;
  iMidiTrack := 0;

  copyright := EventPartitur.GetCopyright;

  GriffHeader.Details := EventPartitur.DetailHeader;

  Guard := 0;
  _Repeat := rRegular;
  try
    while iMidiTrack < EventPartitur.TrackCount do
    begin
      PTrack := @EventPartitur.Track[iMidiTrack];
      begin
        delay := PTrack^[0].var_len;
        In_Push := LoadStartPush;
        for iEvent := 1 to Length(PTrack^)-1 do
        begin
          Event := PTrack^[iEvent];
          if Event.IsSustain then
            In_Push := Event.IsPush
          else
          if (Event.Event = 11) then
          begin
            case Event.d1-ControlSustain of
              4: with GriffEvent do
                 begin
                   Clear;
                   NoteType := TNoteType(Event.d2);
                   Repeat_ := _Repeat;
                   _Repeat := rRegular;
                   SoundPitch := 70;
                   GriffPitch := 70;
                   if UsedEvents > 0 then
                   begin
                     AbsRect.Left := GriffEvents[UsedEvents-1].AbsRect.Right;
                     AbsRect.Right := delay;
                     if AbsRect.Width < 10 then
                     begin
                       with GriffHeader.Details do
                         if measureDiv > 0 then
                           AbsRect.Width := TicksPerMeasure - (delay mod TicksPerMeasure)
                         else
                           AbsRect.Width := DeltaTimeTicks;
                     end;
                   end;
                   if Repeat_ <> rRegular then
                     AppendGriffEvent(GriffEvent);
                 end;
              3: _Repeat := TRepeat(Event.d2);
              1, 2:
                 begin
                   Guard := Event.d2;
                   IsCross := Event.d1 = ControlSustain+2;
                 end;
            end;
          end else
          if Event.Event = 9 then
          begin
            GriffEvent.Clear;
            if (copyright = prepCopy) then
            begin
              if Event.Channel in [5,6] then
                GriffEvent.NoteType := ntBass;
            end else
            if Event.Channel > 0 then
              GriffEvent.NoteType := ntBass;
            GriffEvent.SoundPitch := Event.d1;
            GriffEvent.AbsRect.Create(0,0,0,0);
            GriffEvent.AbsRect.Left := delay;
            GriffEvent.AbsRect.Width := TEventArray.GetDelayEvent(PTrack^, iEvent);
            if copyright in [griffCopy, realCopy] then
            begin
              if GriffEvent.NoteType = ntBass then
              begin
                GriffEvent.SetGriffEvent(Instrument, false, false);
                GriffEvent.AbsRect.Top := -1;
                GriffEvent.GriffPitch := Guard;
                if Instrument.BassDiatonic then
                begin
                  GriffEvent.InPush := In_Push;
                end;
                GriffEvent.Cross := IsCross;
              end else begin
                if Guard = 0 then
                begin
                  Guard := GriffEvent.SoundPitch;
                end else
                  GriffEvent.Cross := IsCross;
                GriffEvent.InPush := In_Push;
                if copyright = griffCopy then
                begin
                  GriffEvent.GriffPitch := Guard;
                end else
                if GriffEvent.NoteType = ntBass then
                  GriffEvent.GriffPitch := Guard
                else begin
                  GriffEvent.GriffPitch := GriffEvent.SoundPitch;
                  GriffEvent.SoundPitch := Guard;
                end;
                GriffEvent.AbsRect.Top := GetPitchLine(GriffEvent.GriffPitch);
              end;
              if AsGriffPartitur and (copyright = griffCopy) then
                GriffEvent.GriffToSound(Instrument);
              GriffEvent.AbsRect.Height := 1;
              GriffEvent.Repeat_ := _Repeat;
              AppendGriffEvent(GriffEvent);
              _Repeat := rRegular;
            end else
////////////////////////////////////////////////////// ==>
            if copyright = newCopy then begin
              GriffEvent.InPush := In_Push;
              GriffEvent.SetNewGriffEvent(Instrument, Event);
              GriffEvent.Repeat_ := _Repeat;
              AppendGriffEvent(GriffEvent);
              _Repeat := rRegular;
            end else
/////////////////////////////////////
            if GriffEvent.SetGriffEvent(Instrument, In_Push, false) then
              AppendGriffEvent(GriffEvent)
            else begin
              result := GriffEvent.NoteType = ntBass;
            end;
            Guard := 0;
            IsCross := false;
          end else begin
            Guard := 0;
            IsCross := false;
          end;
          if Event.Event in [8..14] then
            inc(delay, Event.var_len);
        end;
      end;
      inc(iMidiTrack);
    end;
  finally
    PartiturLoaded := false;
  end;
  SortEvents;
  PartiturLoaded := true;
  LoadChanges;
end;

////////////////////////////////////////////////////////////////////////////////

function TGriffPartitur.LoadFromRecorded(const EventPartitur: TEventArray): boolean;
var
  iEvent: integer;
  delay: integer;
  GriffEvent: TGriffEvent;
  In_Push: boolean;
  iMidiTrack: integer;
  _Repeat: TRepeat;
  PTrack: PMidiEventArray;
  Event: TMidiEvent;
begin
  Clear;

  result := EventPartitur.TrackCount > 0;
  if not result then
    exit;

  iMidiTrack := 0;

  GriffHeader.Details := EventPartitur.DetailHeader;

  _Repeat := rRegular;
  try
    while iMidiTrack < EventPartitur.TrackCount do
    begin
      PTrack := @EventPartitur.Track[iMidiTrack];
      begin
        delay := PTrack^[0].var_len;
        In_Push := LoadStartPush;
        for iEvent := 1 to Length(PTrack^)-1 do
        begin
          Event := PTrack^[iEvent];
          if Event.IsSustain then
            In_Push := Event.IsPush
          else
          if Event.Event = 9 then
          begin
            if Event.Channel <= 6 then
            begin
              GriffEvent.Clear;
              if Event.Channel in [5,6] then
                GriffEvent.NoteType := ntBass;
              GriffEvent.SoundPitch := Event.d1;
              GriffEvent.AbsRect.Create(0,0,0,0);
              GriffEvent.AbsRect.Left := delay;
              GriffEvent.AbsRect.Width := TEventArray.GetDelayEvent(PTrack^, iEvent);
              GriffEvent.InPush := In_Push;
              GriffEvent.SoundPitch := Event.d1;
              if GriffEvent.UniqueSoundToGriff(Instrument, Event.Channel) then
                AppendGriffEvent(GriffEvent)
              else begin
                result := false
              end;
            end;
          end;
          if Event.Event in [8..14] then
            inc(delay, Event.var_len);
        end;
      end;
      inc(iMidiTrack);
    end;
  finally
    PartiturLoaded := false;
  end;
//  SortEvents;

  PartiturLoaded := true;
  LoadChanges;
end;

function TGriffPartitur.LoadFromGriffFile(const FileName: string): boolean;
var
  i: integer;
  Stream: TMyMemoryStream;
begin
  Clear;
  LoadChanges;
  result := true;

  Stream := TMyMemoryStream.Create;
  try
    Stream.LoadFromFile(FileName);
    Stream.BulkRead(PByte(@GriffHeader), sizeof(TGriffHeader));
    SetLength(GriffEvents, GriffHeader.UsedEvents);
    Stream.Position := 1024;
    Stream.BulkRead(PByte(@Instrument), sizeof(Instrument));
    Stream.Position := 2048;
    for i := 0 to UsedEvents-1 do
      Stream.BulkRead(PByte(@GriffEvents[i]), sizeof(TGriffEvent));
    PartiturLoaded := true;
    PartiturFileName := FileName;
  finally
    Stream.Free;
  end;
  SortEvents;
end;

function TGriffPartitur.AppendFile(const FileName: string): boolean;
var
  Partitur: TGriffPartitur;
  duration: integer;
  iEvent: integer;
begin
  result := false;
  Partitur := TGriffPartitur.Create;
  try
    duration := GetTotalDuration;
    with GriffHeader do
      duration := quarterNote*((duration + quarterNote - 1) div quarterNote);
    if not Partitur.LoadFromGriffFile(FileName) then
      exit;
    for iEvent := 0 to Partitur.UsedEvents-1 do
    begin
      GriffEvents[iEvent].AbsRect.Offset(duration, 0);
      AppendGriffEvent(Partitur.GriffEvents[iEvent]);
    end;
  finally
    Partitur.Free;
  end;      
end;


function TGriffPartitur.SetInstrument(Name: AnsiString): boolean;
var
  index: integer;
  iEvent: integer;
  oldInstrument: TInstrument;
begin
  oldInstrument := Instrument;
  index := InstrumentIndex(Name);
  result := index >= 0;
  if result then
  begin
    Instrument := InstrumentsList_[index];
    if PartiturLoaded then
    begin
      if (OldInstrument.BassDiatonic <> Instrument.BassDiatonic) or
         (OldInstrument.bigInstrument <> Instrument.bigInstrument) then
      begin
        for iEvent := 0 to UsedEvents-1 do
          GriffEvents[iEvent].SoundToGriff(Instrument);
      end else begin
  //      diff := Instrument.Push.Col[2, 6] - Instrument.Push.Col[2, 6];
        for iEvent := 0 to UsedEvents-1 do
          GriffEvents[iEvent].GriffToSound(Instrument, 0);
      end;
    end;
  end;  
end;

function TGriffPartitur.SaveToGriffFile(const FileName: string): boolean;
var
  i: integer;
  Stream: TMyMemoryStream;
begin
  Stream := TMyMemoryStream.Create;
  try
    Stream.SetSize(2048 + UsedEvents*sizeof(TGriffEvent));
    Stream.Position := 0;
    Stream.BulkWrite(PByte(@GriffHeader), sizeof(TGriffHeader));
    Stream.Position := 1024;
    Stream.BulkWrite(PByte(@Instrument), sizeof(Instrument));
    Stream.Position := 2048;
    for i := 0 to UsedEvents-1 do
      Stream.BulkWrite(PByte(@GriffEvents[i]), sizeof(TGriffEvent));
    Stream.SaveToFile(FileName);
    result := true;
  finally
    Stream.Free;
  end;
end;

procedure TGriffPartitur.AppendGriffEvent(GriffEvent: TGriffEvent);
begin
  if Length(GriffEvents) < 10 then
    SetLength(GriffEvents, 100);
  if UsedEvents = Length(GriffEvents) then
    SetLength(GriffEvents, 2*Length(GriffEvents));
  GriffEvents[GriffHeader.UsedEvents] := GriffEvent;
  inc(GriffHeader.UsedEvents);
end;

procedure TGriffPartitur.InsertNewSelected(const GriffEvent: TGriffEvent);
begin
  AppendGriffEvent(GriffEvent);
  fSelected := GriffHeader.UsedEvents-1;
  SortEvents;
{$ifdef __FRM_GRIFF__}
  frmGriff.Invalidate;
{$endif}
end;

procedure TGriffPartitur.BassSynch;
var
  i, k: integer;
  d, delta: integer;
  takt: integer;
begin
  takt := GriffHeader.Details.DeltaTimeTicks*GriffHeader.Details.measureFact;
  delta := GriffHeader.Details.DeltaTimeTicks div 3;
  i := 0;
  while i < UsedEvents do
  begin
    while (i < UsedEvents) and (GriffEvents[i].NoteType = ntDiskant) do
      inc(i);
    if (i < UsedEvents) then
    begin
      d := GriffEvents[i].AbsRect.Left mod takt;
      if d > delta then
        d := d - takt;
      if (0 < d) and (d <= delta) then
        for k := i to UsedEvents-1 do
          GriffEvents[k].AbsRect.Offset(-d, 0);
    end;
    inc(i);
  end;
end;

procedure TGriffPartitur.MakeLongerPitches;
var
  i, k: integer;
  LastRight: integer;
begin
  i := 0;
  SortEvents;
  LastRight := 0;
  while (i < UsedEvents) do begin
    if GriffEvents[i].NoteType <> ntDiskant then
    begin
      inc(i);
      continue;
    end;
    k := i+1;
    while (k < UsedEvents) and
          (GriffEvents[i].GetDuration.IsEqual(GriffEvents[k].GetDuration) or
            (GriffEvents[k].NoteType <> ntDiskant))  do
      inc(k);
    if k >= UsedEvents then
      break;
    dec(k);
    if (GriffEvents[i].GetDuration.Width <= GriffHeader.Details.smallestNote) and
       (LastRight + GriffHeader.Details.smallestNote = GriffEvents[i].AbsRect.Left) then
    begin
      while i <= k do
      begin
        if GriffEvents[i].NoteType = ntDiskant then
        begin
          GriffEvents[i].AbsRect.Width := 2*GriffHeader.Details.smallestNote;
          GriffEvents[i].AbsRect.Offset(-GriffHeader.Details.smallestNote, 0);
        end;
        inc(i);
      end;
    end else
    if (GriffEvents[i].GetDuration.Width <= GriffHeader.Details.smallestNote) and
       //not odd(GriffEvents[i].AbsRect.Left mod GriffHeader.Details.smallestNote) and
       (GriffEvents[i].AbsRect.Right + GriffHeader.Details.smallestNote = GriffEvents[k+1].AbsRect.Left) then
    begin
      while i <= k do
      begin
        if GriffEvents[i].NoteType = ntDiskant then
          GriffEvents[i].AbsRect.Width := GriffEvents[i].AbsRect.Width + GriffHeader.Details.smallestNote;
        inc(i);
      end;
    end;
    LastRight := GriffEvents[i].AbsRect.Right;
    i := k + 1
  end;
  i := 0;
  while (i < UsedEvents) do begin
    if GriffEvents[i].NoteType <> ntDiskant then
    begin
      inc(i);
      continue;
    end;
    k := i+1;
    while (k < UsedEvents) and
          ((GriffEvents[k].NoteType <> ntDiskant) or GriffEvents[i].GetDuration.IsEqual(GriffEvents[k].GetDuration))  do
      inc(k);
    if k >= UsedEvents then
      break;
    dec(k);
    if not odd(GriffEvents[i].AbsRect.Left mod GriffHeader.Details.smallestNote) and
       (GriffEvents[i].AbsRect.Right + GriffHeader.Details.smallestNote = GriffEvents[k+1].AbsRect.Left) then
    begin
      while i <= k do
      begin
        if GriffEvents[i].NoteType <> ntDiskant then
          GriffEvents[i].AbsRect.Width := GriffEvents[i].AbsRect.Width + GriffHeader.Details.smallestNote;
        inc(i);
      end;
    end;
    i := k + 1
  end;

end;



function TGriffPartitur.ScreenToNotePoint(var NotePoint: TPoint; ScreenPoint: TPoint): boolean;
begin
  NotePoint.X := trunc(GriffHeader.Details.GetMeasureDiv*ScreenPoint.X / pitch_width);
  NotePoint.Y := MaxGriffIndex - (ScreenPoint.Y - MoveVert) div row_height;
  result := true;
end;

function TGriffPartitur.SearchGriffEvent(const NotePoint: TPoint): integer;
var
  iEvent: integer;
begin
  result := -1;
  SortEvents;
  for iEvent := 0 to UsedEvents-1 do
  begin
    with GriffEvents[iEvent] do
      if Contains(NotePoint) then
      begin
        result := iEvent;
//        exit;   Das oberste Rechteck ist sichtbar!
      end;
  end;
end;

 procedure TGriffPartitur.SetSelected(Index: integer);
 begin
   fSelected := Index;
   if (SelectedEvent <> nil) then
     DoSoundPitch(SelectedEvent^);

   if trimNote and (SelectedEvent <> nil) then
     with SelectedEvent^, GriffHeader.Details do
     begin
       SetRaster(AbsRect);
       if AbsRect.Width < smallestNote then
         AbsRect.Width := smallestNote;
     end;
 end;

function TGriffPartitur.KeyDown(var Key: Word; Shift: TShiftState): boolean;

  procedure NewDiskantEvent(Key: integer);
  begin
    InsertNewEvent(Selected, true);
    with SelectedEvent^ do
    begin
      NoteType := ntDiskant;
      case Key of
        ord('C'): AbsRect.Top := 0;
        ord('D'): AbsRect.Top := 1;
        ord('E'): AbsRect.Top := 2;
        ord('F'): AbsRect.Top := 3;
        ord('G'): AbsRect.Top := 4;
        ord('A'): AbsRect.Top := 5;
        ord('H'): AbsRect.Top := 6;
        else      AbsRect.Top := 0;
      end;
      inc(AbsRect.Top, 5);
      AbsRect.Height := 1;
    end;
  end;

  procedure NewBassEvent(Key: integer);
  begin
    InsertNewEvent(Selected, true);
    with SelectedEvent^ do
    begin
      NoteType := ntBass;
      AbsRect.Top := -1;
      AbsRect.Height := 1;
      AbsRect.Width := GriffHeader.Details.DeltaTimeTicks div 3;
      GriffPitch := Key - ord('0');
    end;
  end;

var
  w, x, i: integer;
  left, right: integer;
  iEvent: integer;
  NewEvent: TGriffEvent;
  EventPitchs: TEventPitchArr;
  selDur: TGriffDuration;
  Dur: TGriffDuration;
  FirstCopy: integer;
  iFirst, iLast: integer;
begin
  result := false;

  if (Key = ord(' ')) or
     ((Key = ord('S')) and (@DoSave <> nil) and (Shift = [ssCtrl])) then
    SetRubberOff;

  if bRubberBandOk then
  begin
    FirstCopy := -1;
    Left := rectRubberBand.Left mod (pitch_width div 4);
    w := rectRubberBand.Width mod (pitch_width div 4); 
    case Key of
      ord('C'),
      ord('X'),
      ord('I'),
      ord('O'),
      ord('P'),
      ord('U'):
        begin
          if Key in [ord('C'), ord('X')] then
          begin
            SetLength(CopyEvents, 0);
          end;
          left := trunc(GriffHeader.Details.GetmeasureDiv*rectRubberBand.Left / pitch_width);
          right := trunc(GriffHeader.Details.GetmeasureDiv*rectRubberBand.right / pitch_width);
          iFirst := -1;
          iLast := -1;
          for iEvent := 0 to UsedEvents-1 do
            with GriffEvents[iEvent] do
              if ((AbsRect.Left <= left) and (right <= AbsRect.Right)) or
                 ((left <= AbsRect.Left) and (AbsRect.Left < right)) or
                 ((left <= AbsRect.Right) and (AbsRect.Right < right)) then
              begin
                if iFirst < 0 then
                  iFirst := iEvent;
                iLast := iEvent;
              end;

          if Key = ord('U') then
          begin
            if not Instrument.BassDiatonic then
              OptimisePairs(iFirst, iLast);
            result := true;
            exit;
          end else
          for iEvent := iFirst to iLast do
            with GriffEvents[iEvent] do
              if Key in [ord('C'), ord('X')] then
              begin
                if Length(CopyEvents) = 0 then
                  FirstCopy := iEvent;
                SetLength(CopyEvents, Length(CopyEvents)+1);
                CopyEvents[Length(CopyEvents)-1] := GriffEvents[iEvent];
              end else
              if (NoteType = ntDiskant) or
                 ((NoteType = ntBass) and Instrument.BassDiatonic) then
                begin
                  if Key in [ord('O'), ord('P')] then
                  begin
                    if InPush <> Rubber_In_Push then
                    begin
                      if Key = ord('O') then
                      begin
                        InPush := not InPush;
                        ChangeNote(@GriffEvents[iEvent], false);
                      end else begin
                        InPush := not InPush;
                        if not GriffEvents[iEvent].SoundToGriff(Instrument) then
                          InPush := not InPush;
                      end;
                    end;
                  end else
                  if (NoteType = ntDiskant) and (Key = ord('I')) then
                    AlternateNote(@GriffEvents[iEvent]);
                end;

          if (Key = ord('X')) and (FirstCopy >= 0) then
          begin
            w := 0;
            x := - GriffEvents[FirstCopy].AbsRect.Left;
            for i := 0 to Length(CopyEvents)-1 do
            begin
              with CopyEvents[i] do
              begin
                AbsRect.Offset(x, 0);
                if w < AbsRect.Right then
                  w := AbsRect.Right;
              end;
            end;
            for i := FirstCopy to UsedEvents-Length(CopyEvents)-1 do
              GriffEvents[i] := GriffEvents[i+Length(CopyEvents)];
            dec(GriffHeader.UsedEvents, Length(CopyEvents));
            for i := FirstCopy to UsedEvents-1 do
              GriffEvents[i].AbsRect.Offset(-w, 0);
            fSelected := FirstCopy-1;
          end;
          if (Key in [ord('C'), ord('X')]) then
            SetRubberOff;

          if Key in [ord('O'), ord('P')] then
            Rubber_In_Push := not Rubber_In_Push;
          result := true;
          exit;
        end;
        
      vk_Left:
        rectRubberBand.Offset(-(pitch_width div 4) - Left, 0);
      vk_Right: 
        rectRubberBand.Offset(pitch_width div 4 - Left, 0);
      vk_Up: 
        rectRubberBand.Width := rectRubberBand.Width + pitch_width div 4 - w;
      vk_Down:
        if rectRubberBand.Width > pitch_width div 2 then
          rectRubberBand.Width := rectRubberBand.Width - pitch_width div 4 - w;
    end;
    result := key in [vk_left, vk_right, vk_up, vk_down];
    exit;
  end;    

  if PartiturLoaded then
    case Key of
      ord(' '):
        if @DoPlay <> nil then
        begin
          DoPlay(nil);
          exit;
        end;
      vk_Escape:
        begin
          Unselect;
          result := true;
          exit;
        end;
      ord('S'):
        if (@DoSave <> nil) and (Shift = [ssCtrl]) then
        begin
          DoSave(nil);
          exit;
        end;
      vk_Tab:
        if SelectedEvent = nil then
        begin
          if (ssShift in Shift) or (ssCtrl in Shift)  then
            SetSelected(UsedEvents-1)
          else
            SetSelected(0);
          result := true;
          exit;
        end;
    end;

  case Key of
    ord('C'), ord('D'), ord('E'), ord('F'), ord('G'), ord('A'), ord('H'):
      begin
        NewDiskantEvent(Key);
        with SelectedEvent^do
        begin
          if ssShift in Shift then
          begin
            if ssCtrl in Shift then
              inc(AbsRect.Top, 14)
            else
              inc(AbsRect.Top, 7);
          end else
          if ssCtrl in Shift then
            dec(AbsRect.Top, 7);

          if Instrument.BassDiatonic then
          begin
            if AbsRect.Top > 24 then
              AbsRect.Top := 24;
            if AbsRect.Top < 0 then
              AbsRect.Top := 0;
          end else begin
            if AbsRect.Top > 21 then
              AbsRect.Top := 21;
            if AbsRect.Top < 1 then
              AbsRect.Top := 1;
          end;
          AbsRect.Height := 1;
        end;
        ChangeNote(SelectedEvent, true);
        result := true;
        exit;
      end;
    ord('1') .. ord('9'):
      if not Instrument.BassDiatonic or (Key < ord('9')) then
      begin
        NewBassEvent(Key);
        with SelectedEvent^do
        begin
          Cross := Shift = [];
        end;
        ChangeNote(SelectedEvent, true);
        result := true;
        exit;
      end;
  end;

  if SelectedEvent = nil then
    exit;

  with SelectedEvent^ do
  begin
    if [] = Shift then
    begin
      x := AbsRect.Left;
      case Key of
        vk_Left:
          begin
            if x mod GriffHeader.Details.smallestNote <> 0 then
              AbsRect.Offset(-(x mod GriffHeader.Details.smallestNote), 0)
            else
            if x >= GriffHeader.Details.smallestNote then
              AbsRect.Offset(-GriffHeader.Details.smallestNote, 0);
            result := true;
          end;
        vk_Right:
          begin
            if x mod GriffHeader.Details.smallestNote <> 0 then
              AbsRect.Offset(-(x mod GriffHeader.Details.smallestNote), 0);
            AbsRect.Offset(GriffHeader.Details.smallestNote, 0);
            result := true;
          end;
        vk_Up:
          if NoteType = ntBass then
          begin
            if (GriffPitch < High(TPitchArray)) and
               (Instrument.Bass[Cross, GriffPitch+1] > 0) then
            begin
              inc(GriffPitch);
              ChangeNote(@GriffEvents[Selected], true);
              result := true;
            end;
          end else
          if Instrument.bigInstrument then
          begin
            if (AbsRect.Top < 22) or
               (not Cross and (AbsRect.Top < 24)) then
            begin
              AbsRect.Offset(0, 1);
              ChangeNote(@GriffEvents[Selected], true);
              result := true;
            end;
          end else
          if not Cross and (AbsRect.Top < 21) then
          begin
            AbsRect.Offset(0, 1);
            ChangeNote(@GriffEvents[Selected], true);
            result := true;
          end else
          if AbsRect.Top < 19 then
          begin
            AbsRect.Offset(0, 2);
            ChangeNote(@GriffEvents[Selected], true);
            result := true;
          end;
        vk_Down:
          if NoteType = ntBass then
          begin
            if (GriffPitch > Low(TPitchArray)) and
               (Instrument.Bass[Cross, GriffPitch-1] > 0) then
            begin
              dec(GriffPitch);
              ChangeNote(@GriffEvents[Selected], true);
              result := true;
            end;
          end else
          if Instrument.bigInstrument then
          begin
            if (AbsRect.Top > 2) or
               (not Cross and (AbsRect.Top > 0)) then
            begin
              AbsRect.Offset(0, -1);
              ChangeNote(@GriffEvents[Selected], true);
              result := true;
            end;
          end else
          if not Cross and (AbsRect.Top > 1) then
          begin
            AbsRect.Offset(0, -1);
            ChangeNote(@GriffEvents[Selected], true);
            result := true;
          end else
          if AbsRect.Top > 2 then
          begin
            AbsRect.Offset(0, -2);
            ChangeNote(@GriffEvents[Selected], true);
            result := true;
          end;
        vk_Tab:
          if UsedEvents = 1 then
          begin
            SetSelected(-1);
            result := true;
          end else
          if Selected+1 < UsedEvents then
          begin
            SetSelected(Selected+1);
            result := true;
          end;
        ord('I'):
          begin
            AlternateNote(SelectedEvent);
            result := true;
          end;
        VK_Back:
          begin
            BackEvent := Selected;
          end;
        ord('X'):
          if NoteType = ntBass then
          begin
            if (GriffPitch in [1..9]) then
            begin
              Cross := not Cross;
              ChangeNote(SelectedEvent, true);
              result := true;
            end;
          end else
          if Instrument.bigInstrument then
          begin
            if AbsRect.Top in [2..22] then
            begin
              Cross := not Cross;
              ChangeNote(SelectedEvent, true);
              result := true;
            end;
          end else
          if not odd(AbsRect.Top) then
          begin
            Cross := not Cross;
            ChangeNote(SelectedEvent, true);
            result := true;
          end;
        ord('P'):
          if (NoteType = ntDiskant) or
             ((NoteType = ntBass) and (Instrument.BassDiatonic)) then
          begin
            InPush := not InPush;
            if not SelectedEvent.SoundToGriff(Instrument) then
              InPush := not InPush;
            result := true;
          end;
        ord('O'):
          if IsDiatonic(Instrument) then
          begin
            InPush := not InPush;
            ChangeNote(SelectedEvent, true);
            result := true;
          end;
        ord('M'):
          DoSoundPitch(SelectedEvent^);
        ord('V'),
        ord('N'),
        ord('B'):
          begin
            SetLength(EventPitchs, 0);
            selDur := GetDuration;
            for i := 0 to UsedEvents-1 do
            begin
              Dur := GriffEvents[i].GetDuration;
              if Dur.Intersect(selDur) then
               if Key = ord('V') then
                begin
                  SetLength(EventPitchs, Length(EventPitchs)+1);
                  EventPitchs[Length(EventPitchs)-1] := i;
                end else
                if (GriffEvents[i].NoteType = ntDiskant) and ((i <> Selected) or (Key = ord('N'))) then
                begin
                  SetLength(EventPitchs, Length(EventPitchs)+1);
                  EventPitchs[Length(EventPitchs)-1] := i;
                end;
            end;
            DoSoundPitchs(EventPitchs);
          end;
        ord('T'): // Triole
          if abs(AbsRect.Width - GriffHeader.Details.DeltaTimeTicks) < 10 then
          begin
            AbsRect.Width := GriffHeader.Details.DeltaTimeTicks div 3;
            NewEvent := SelectedEvent^;
            NewEvent.AbsRect.Offset(GriffHeader.Details.DeltaTimeTicks div 3, 0);
            AppendEvent(NewEvent);
            NewEvent.AbsRect.Offset(GriffHeader.Details.DeltaTimeTicks div 3, 0);
            AppendEvent(NewEvent);
            SortEvents;
            result := true;
          end;
        vk_Insert:
          begin
            InsertNewEvent(Selected);
            result := true;
          end;
        vk_Delete:
          begin
            DeleteGriffEvent(Selected);
            result := true;
          end;          
      end;
    end else
    if not (ssCtrl in Shift) then
    begin
      w := AbsRect.Width;
      case Key of
        vk_tab: // TAB
          if Selected > 0 then
          begin
            SetSelected(Selected-1);
            result := true;
          end;
        vk_Left:
          begin
            if w mod GriffHeader.Details.smallestNote <> 0 then
              dec(w, w mod GriffHeader.Details.smallestNote)
            else
              dec(w, GriffHeader.Details.smallestNote);
            if w < GriffHeader.Details.smallestNote then
              w := GriffHeader.Details.smallestNote;
            AbsRect.Width := w;
            result := true;  
          end;
        vk_Right:
          begin
            right := AbsRect.Right;
            if w mod GriffHeader.Details.smallestNote <> 0 then
              dec(w, w mod GriffHeader.Details.smallestNote);
            inc(w, GriffHeader.Details.smallestNote);
            GriffEvents[Selected].AbsRect.Width := w;
            if (Selected < UsedEvents-1) and
               (GriffEvents[Selected+1].AbsRect.Left >= Right) and
               (GriffEvents[Selected+1].AbsRect.Left < AbsRect.Right) then
            begin
              for i := Selected+1 to UsedEvents-1 do
                GriffEvents[i].AbsRect.Offset(GriffHeader.Details.smallestNote, 0);
              //SortEvents;
            end;
            result := true;            
          end;
      end
    end else begin
      case Key of
        vk_tab: // TAB
          if UsedEvents = 1 then
          begin
            SetSelected(-1);
            result := true;
          end else
          if Selected > 0 then
          begin
            SetSelected(Selected-1);
            result := true;
          end;
        vk_Left: 
          begin
            w := GriffHeader.Details.smallestNote;
            if AbsRect.Left mod GriffHeader.Details.smallestNote <> 0 then
              w := AbsRect.Left mod GriffHeader.Details.smallestNote;
            for i := Selected to UsedEvents-1 do
              GriffEvents[i].AbsRect.Offset(-w, 0);
            SortEvents;
            result := true;  
          end;
        vk_Right:
          begin
            for i := Selected to UsedEvents-1 do
              GriffEvents[i].AbsRect.Offset(GriffHeader.Details.smallestNote, 0);
            SortEvents;
            result := true;  
          end;
        ord('V'):
          if Length(CopyEvents) > 0 then
          begin
            x := - CopyEvents[0].AbsRect.Left;
            w := 0;
            for i := 0 to Length(CopyEvents)-1 do
            begin
              with CopyEvents[i] do
              begin
                AbsRect.Offset(x, 0);
                if w < AbsRect.Right then
                  w := AbsRect.Right;
                AbsRect.Offset(SelectedEvent.AbsRect.Right, 0);
              end;
            end;
            for i := Selected+1 to UsedEvents-1 do
              GriffEvents[i].AbsRect.Offset(w, 0);
            for i := 0 to Length(CopyEvents)-1 do
              AppendEvent(CopyEvents[i]);

            SortEvents;
            result := true;
          end;
      end;
    end;
  end;
end;

function TGriffPartitur.TickToScreen(tick: integer): integer;
begin
  result := round(tick*pitch_width/quarterNote);
  if GriffHeader.Details.measureDiv = 8 then
    result := 2*result;
end;

procedure TGriffPartitur.Play(var PlayEvent: TPlayRecord);
const
  PolyphonBass = true;
var
  i, Row: integer;
  Dur: array [1..6, 0..127] of record
         d: integer;
       end;
  DurRest: integer;
  AmpelRect: TAmpelRec;
  all_done: boolean;
  Sound: byte;
  TickOffset, Ticks, offset: double;
  Max, MaxBass: byte;
  LastPush: boolean;

  procedure SetAmpelToOff(Row, index: integer);
  begin
    if Dur[Row, index].d > 0 then
    begin
//      if not noSound then
      MidiOutput.Send(MicrosoftIndex, $80 + Row - 1, index, $40);
      case Row of
        5:    begin
                MidiOutput.Send(MicrosoftIndex, $84, index+12, $40);
              end;
        6:    begin
                MidiOutput.Send(MicrosoftIndex, $85, index+4, $40);
                MidiOutput.Send(MicrosoftIndex, $85, index+7, $40);
              end;
        else begin end;
      end;
      Dur[Row, index].d := 0;
    end;
  end;

  procedure AllVoicesOff;
  var
    t, Row, i: integer;
  begin
    ProcessMessages;
    sleep(1);

    Ticks := GriffHeader.Details.GetTicks;
    Offset := Offset + PlayFactor*(Ticks - TickOffset);
    TickOffset := Ticks;

    all_done := true;
    t := round(offset);
    for Row := 1 to High(Dur) do
      for i := 0 to 127 do
        if (Dur[Row, i].d > 0) then
        begin
          if (Dur[Row, i].d <= t) then
          begin
            SetAmpelToOff(Row, i);
          end else
            all_done := false;
        end;
    if DurRest > 0 then
    begin
      if DurRest <= t then
      else
        all_done := false;
    end;
  end;

  procedure SkipEvent(NewEvent: integer; wait: boolean);
  begin
    if wait then
      repeat
        AllVoicesOff;
      until all_done or StopPlay;

    PlayEvent.iEvent := NewEvent;
    TickOffset := GriffHeader.Details.GetTicks;
    offset := GriffEvents[PlayEvent.iEvent].AbsRect.Left;
  end;

begin
  if (PlayEvent.iEvent < 0) or (PlayEvent.iEvent >= UsedEvents) then
    PlayEvent.Clear;
  offset := GriffEvents[PlayEvent.iEvent].AbsRect.Left;
  LastPush := GriffEvents[PlayEvent.iEvent].InPush;
  MidiOutput.Send(MicrosoftIndex, $B0, ControlSustain, ord(LastPush));

  for Row := 1 to High(Dur) do
    for i := 0 to 127 do
      Dur[Row, i].d := 0;
  DurRest := 0;

        // 41 9  73

  Sound := 0;
  TickOffset := GriffHeader.Details.GetTicks;
  try
    repeat
      AllVoicesOff;

      while (PlayEvent.iEvent < UsedEvents) and
            (round(Offset) >= GriffEvents[PlayEvent.iEvent].AbsRect.Left) and
            not StopPlay do
      begin
        if (iAEvent >= 0) and (iBEvent > iAEvent + 2) and (PlayEvent.iEvent >= iBEvent) then
        begin
          SkipEvent(iAEvent, true);
          continue;
        end;

        with GriffEvents[PlayEvent.iEvent] do
        begin
          if Repeat_ = rVolta1Start then
          begin
            if PlayEvent.iStartVolta > PlayEvent.iEvent then
            begin
              SkipEvent(PlayEvent.iStartVolta, false);
              continue;
            end;
          end;

          if NoteType in [ntDiskant, ntBass] then
          begin
            if NoteType = ntBass then
              Sound := SoundPitch
            else
              Sound := GetSoundPitch(Instrument);
            AmpelRect := GetAmpelRec;
            SetAmpelToOff(AmpelRect.row, Sound);
            Dur[AmpelRect.row, Sound].d := AbsRect.Right;
          end else
          if NoteType = ntRest then
            DurRest := AbsRect.Right;

          if not noSound and
            (NoteType in [ntDiskant, ntBass]) then
          begin
            if InPush <> LastPush then
            begin
              LastPush := InPush;
              MidiOutput.Send(MicrosoftIndex, $B0, ControlSustain, ord(LastPush));
            end;
            Max := trunc($7e*Volume);
            MaxBass := trunc($7e*Volume);
            case AmpelRect.row of
              1..4:
                 if not noTreble then
                   MidiOutput.Send(MicrosoftIndex, $90 + AmpelRect.row - 1, Sound, Max);
              5: if not noBass then
                 begin
                   MidiOutput.Send(MicrosoftIndex, $94, Sound, MaxBass);
                   if PolyphonBass and
                      not Instrument.BassDiatonic then
                     MidiOutput.Send(MicrosoftIndex, $94, Sound+12, MaxBass - 10);
                 end;
              6: if not NoBass then
                 begin
                   MidiOutput.Send(MicrosoftIndex, $95, Sound, MaxBass);
                   if PolyphonBass and
                      not Instrument.BassDiatonic then
                   begin
                     MidiOutput.Send(MicrosoftIndex, $95, Sound+4, MaxBass - 10);
                     MidiOutput.Send(MicrosoftIndex, $95, Sound+7, MaxBass - 10);
                   end;
                 end;
            end;
          end;

          case Repeat_ of
            rRegular:
              inc(PlayEvent.iEvent);
            rStart:
              begin
                PlayEvent.iStartEvent := PlayEvent.iEvent;
                inc(PlayEvent.iEvent);
              end;
            rStop:
              begin
                inc(PlayEvent.iVolta);
                if PlayEvent.iVolta = 1 then
                begin
                  SkipEvent(PlayEvent.iStartEvent, true);
                end else begin
                  PlayEvent.iVolta := 0;
                  PlayEvent.iStartEvent := 0;
                  PlayEvent.iStartVolta := 0;
                  inc(PlayEvent.iEvent);
                end;
              end;
            rVolta1Start:
              inc(PlayEvent.iEvent);
            rVolta1Stop:
              begin
                PlayEvent.iStartVolta := PlayEvent.iEvent+1;
                SkipEvent(PlayEvent.iStartEvent, true);
              end;
            rVolta2Start:
              inc(PlayEvent.iEvent);
            rVolta2Stop:
              begin
                PlayEvent.iVolta := 0;
                PlayEvent.iStartEvent := 0;
                PlayEvent.iStartVolta := 0;
                inc(PlayEvent.iEvent);
              end;
          end;
        end;
      end;
      AllVoicesOff;
    until ((PlayEvent.iEvent >= UsedEvents) and all_done) or StopPlay;
  finally
    for Row := 1 to High(Dur) do
      for i := 0 to 127 do
        SetAmpelToOff(Row, i);
  end;
end;


procedure TGriffPartitur.StartPlay;
begin
  SortEvents;
  StopPlay := false;
end;

procedure TGriffPartitur.PlayAmpel(var PlayEvent: TPlayRecord; PlayDelay: integer);
var
  i, k: integer;
  Dur: array [1..6, 0..15] of record
         d: integer;
         rec: TAmpelRec;
       end;
  DurRest: integer;
  playStart: integer;
  all_done: boolean;
  screenRect: TRect;
  Sound: byte;
  PlayDelta: integer;
  Ticks, TickOffset, Offset: double;

  procedure SetAmpelToOff(Row, Index: integer);
  begin
    if Dur[Row, Index].d > 0 then
    begin
      with Dur[Row, Index].rec do
        frmAmpel.AmpelEvents.SetAmpel(Row, Index, false, false);
      Dur[Row, Index].d := 0;
    end;
  end;

  procedure AllVoicesOff;
  var
    i, k, t: integer;
  begin
    ProcessMessages;
    sleep(10);
    Ticks := GriffHeader.Details.GetTicks;
    Offset := Offset + PlayFactor*(Ticks - TickOffset);
    t := round(offset);
    TickOffset := Ticks;

    playLocation := TickToScreen(round(Offset));
    screenRect.Right := playLocation + 1;
    if @DoPlayRect <> nil then
      DoPlayRect(screenRect);
    screenRect.Left := playLocation - 1;

    all_done := true;
    for k := 1 to 6 do
      for i := 0 to 15 do
        if (Dur[k, i].d > 0) then
        begin
          if (Dur[k, i].d < t) then
          begin
            SetAmpelToOff(k, i);
          end else
            all_done := false;
        end;
      if DurRest > 0 then
      begin
        if DurRest <= t then
        else
          all_done := false;
      end;
  end;

  procedure SkipEvent(NewEvent: integer; wait: boolean);
  begin
    if wait then
      repeat
        AllVoicesOff;
      until all_done or StopPlay;

    PlayEvent.iEvent := NewEvent;
    PlayStart := GriffEvents[PlayEvent.iEvent].AbsRect.Left;
    screenRect.Left := TickToScreen(PlayStart);
    screenRect.Width := 10;
    offset := PlayStart;

    playLocation := -1;
{$ifdef __FRM_GRIFF__}
    frmGriff.Invalidate;
{$endif}
  end;

begin
  if (PlayEvent.iEvent < 0) or (PlayEvent.iEvent >= UsedEvents) then
    PlayEvent.Clear;

  playStart := GriffEvents[PlayEvent.iEvent].AbsRect.Left;
  offset := playStart;

  PlayDelta := GriffHeader.Details.MsDelayToTicks(PlayDelay);
  Offset := Offset - PlayDelta;

  for k := 1 to 6 do
    for i := 0 to 15 do
      Dur[k, i].d := 0;
  DurRest := 0;

  screenRect.Create(0, 0, 1, 25*row_height);
  screenRect.Offset(0, MoveVert);
  screenRect.Left := TickToScreen(playStart);
  screenRect.Width := 10;

  TickOffset := GriffHeader.Details.GetTicks;
  repeat
    while (PlayEvent.iEvent < UsedEvents) and
          (round(Offset) >= GriffEvents[PlayEvent.iEvent].AbsRect.Left) do
    begin
      // zum Loop-Anfang
      if (iAEvent >= 0) and (iBEvent > iAEvent + 2) and (PlayEvent.iEvent >= iBEvent) then
      begin
        SkipEvent(iAEvent, true);
        continue;
      end;

      with GriffEvents[PlayEvent.iEvent] do
      begin
        if Repeat_ = rVolta1Start then
        begin
          if PlayEvent.iStartVolta > PlayEvent.iEvent then
          begin
            SkipEvent(PlayEvent.iStartVolta, false);
            continue;
          end;
        end;

        if NoteType in [ntDiskant, ntBass] then
        begin
          if NoteType = ntBass then
            Sound := SoundPitch
          else
            Sound := GetSoundPitch(Instrument);
          SetAmpelToOff(GetRow, GetIndex);

          Dur[GetRow, GetIndex].d := AbsRect.Right - 40;
          Dur[GetRow, GetIndex].rec := GetAmpelRec;
          SetAmpel(GriffEvents[PlayEvent.iEvent], true);
        end else
        if NoteType = ntRest then
          DurRest := AbsRect.Right - 40;

        case Repeat_ of
          rRegular:
            inc(PlayEvent.iEvent);
          rStart:
            begin
              PlayEvent.iStartEvent := PlayEvent.iEvent;
              inc(PlayEvent.iEvent);
            end;
          rStop:
            begin
              inc(PlayEvent.iVolta);
              if PlayEvent.iVolta = 1 then
              begin
                SkipEvent(PlayEvent.iStartEvent, true);
              end else begin
                PlayEvent.iVolta := 0;
                PlayEvent.iStartEvent := 0;
                PlayEvent.iStartVolta := 0;
                inc(PlayEvent.iEvent);
              end;
            end;
          rVolta1Start:
            inc(PlayEvent.iEvent);
          rVolta1Stop:
            begin
              PlayEvent.iStartVolta := PlayEvent.iEvent+1;
              SkipEvent(PlayEvent.iStartEvent, true);
            end;
          rVolta2Start:
            inc(PlayEvent.iEvent);
          rVolta2Stop:
            begin
              PlayEvent.iVolta := 0;
              PlayEvent.iStartEvent := 0;
              PlayEvent.iStartVolta := 0;
              inc(PlayEvent.iEvent);
            end;
        end;
      end;
    end;

    AllVoicesOff;
  until ((PlayEvent.iEvent >= UsedEvents) and all_done) or StopPlay;

  PlayLocation := -1;
  for k := 1 to 6 do
    for i := 0 to 15 do
      SetAmpelToOff(k, i);

{$if defined(__AMPEL__)}
  frmAmpel.FormPaint(nil);
{$endif}
{$ifdef __FRM_GRIFF__}
  frmGriff.Invalidate;
{$endif}
end;

function TGriffPartitur.GetDrawDuration(Index: integer; In__Push: boolean): integer;
var
  i: integer;
  rect: TRect;
begin
  result := 0;
  while (Index < UsedEvents) and not GriffEvents[Index].IsDiatonic(Instrument) do
    inc(index);

  if Index >= UsedEvents then
    exit;

  with GriffEvents[Index] do
  begin
    rect := AbsRect;
    if InPush = In__Push then
      result := rect.Right;
  end;
  i := Index+1;
  while (i < Index+10) and (i < UsedEvents) do
  begin
    if GriffEvents[i].IsDiatonic(Instrument) then
      with GriffEvents[i] do
      begin
        if AbsRect.Left >= rect.Right then
          break;

        if (InPush = In__Push) and (AbsRect.Width > result) and (AbsRect.Left < rect.Right) then
          result := AbsRect.Width;
      end;
    inc(i);
  end;

  if result > rect.Right then
    result := rect.Right;
end;

procedure TGriffPartitur.SetRubberOff;
begin
  bRubberBand := false;
  bRubberBandOk := false;
  Rubber_In_Push := false;
  rectRubberBand.Empty;
  BackEvent := -1;
end;

procedure TGriffPartitur.Unselect;
begin
  fSelected := -1;
  SetRubberOff;
  StopPlay := true;
end;

function TGriffPartitur.SaveToMidiFile(const FileName: string; realGriffschrift: boolean): boolean;
begin
  result := false;
  if not PartiturLoaded then
    exit;

  SortEvents;

  TGriffArray.SaveMidiToFile(FileName, GriffEvents, Instrument, GriffHeader.Details, realGriffschrift);
  result := true;
end;


function TGriffPartitur.SaveToNewMidiFile(const FileName: string): boolean;
begin
  result := false;
  if not PartiturLoaded then
    exit;

  SortEvents;

  TGriffArray.SaveNewMidiToFile(FileName, GriffEvents, Instrument, GriffHeader.Details);
  result := true;
end;

procedure TGriffPartitur.DoStopPlay;
begin
  StopPlay := true;
end;

function TGriffPartitur.AppendEventArray(const Events: TMidiEventArray): boolean;
var
  iEvent: integer;
  Offset_: integer;
  In_Push: boolean;
  MidiEvent: TMidiEvent;
  GriffEvent: TGriffEvent;
  NextRepeat: TRepeat;
begin
  result := false;
  Offset_ := 0;
  In_Push := LoadStartPush;
  if Length(Events) < 2 then
    exit;

  result := true;
  iEvent := 0;
  NextRepeat := rRegular;
  if Events[0].command = 0 then
  begin
    Offset_ := Events[0].var_len;
    inc(iEvent);
  end;

  while iEvent < Length(Events) do
  begin
    MidiEvent := Events[iEvent];
    if MidiEvent.IsSustain then
      In_Push := MidiEvent.IsPush
    else
    if MidiEvent.Event = 11 then
    begin
      if (MidiEvent.d1 = ControlSustain+3) then
      begin
        NextRepeat := TRepeat(MidiEvent.d2);
      end else
      if (MidiEvent.d1 = ControlSustain+4) then
      begin
        with GriffEvent do
        begin
          Clear;
          NoteType := TNoteType(MidiEvent.d2);
          Repeat_ := NextRepeat;
          NextRepeat := rRegular;
          SoundPitch := 70;
          GriffPitch := 70;
          AbsRect.Create(0,0,0,0);
          if UsedEvents > 0 then
          begin
            AbsRect.Left := GriffEvents[UsedEvents-1].AbsRect.Right;
            AbsRect.Right := offset_;
            if AbsRect.Width < 10 then
            begin
              with GriffHeader.Details do
                if measureDiv > 0 then
                  AbsRect.Width := TicksPerMeasure - (offset_ mod TicksPerMeasure)
                else
                  AbsRect.Width := DeltaTimeTicks;
            end;
            AppendGriffEvent(GriffEvent);
          end;
        end;
      end;
    end else
    if MidiEvent.Event = 9 then
    begin
      GriffEvent.Clear;
      GriffEvent.SoundPitch := MidiEvent.d1;
      GriffEvent.Velocity := MidiEvent.d2;
      GriffEvent.Repeat_ := NextRepeat;
      NextRepeat := rRegular;
      with GriffEvent.AbsRect do
      begin
        Left := Offset_;
        Width := TEventArray.GetDuration(Events, iEvent);
        Top := 0;
        Height := 1;
      end;
      if MidiEvent.Channel = 2 then
      //if GriffEvent.SoundPitch < 40 then

      GriffEvent.NoteType := ntBass;
      if GriffEvent.SetGriffEvent(Instrument, In_Push, false) then
      begin
        AppendGriffEvent(GriffEvent);
{$if defined(CONSOLE)}
        if (GriffEvent.GriffPitch = 0) and
           (GriffEvent.NoteType = ntBass) then
          writeln('Bass SoundPitch ', GriffEvent.SoundPitch, ' ($', IntToHex(GriffEvent.SoundPitch), ') - Offset '+ IntToStr(Offset_));
      end else
      if GriffEvent.NoteType = ntDiskant then
        writeln('SoundPitch ', GriffEvent.SoundPitch, ' ($', IntToHex(GriffEvent.SoundPitch), ') - Offset '+ IntToStr(Offset_));
{$else}
      end;
{$endif}
    end;
    if MidiEvent.Event in [8..14] then
      inc(Offset_, MidiEvent.var_len);
    inc(iEvent);
  end;
end;

procedure TGriffPartitur.LoadChanges;
begin
  Unselect;
  PlayFactor := 1.0;
  Volume := 0.7;
//  iSkipEvent := -1;
  iAEvent := -1;
  iBEvent := -1;
  IsPlaying := false;
end;

function TGriffPartitur.LoadFromTrackEventArray(const Partitur: TEventArray): boolean;
begin
  Clear;
  LoadChanges;
  GriffHeader.Details := Partitur.DetailHeader;
  GriffHeader.UsedEvents := 0;
  result := AppendEventArray(Partitur.SingleTrack);

  SortEvents;
  SetBassGriff;

  PartiturLoaded := GriffHeader.UsedEvents > 0;
  result := PartiturLoaded;
end;

{$if defined(__INSTRUMENTS__)}
procedure TGriffPartitur.OptimisePairs(iFirst, iLast: integer);
var
  i, j, k, n: integer;
  IsPush_, IsPull_: boolean;
  d: TGriffDuration;

  procedure GetIndex(Griff1, Griff2: byte);
  var
    n: integer;
    k: integer;
    l: integer;
    o, no: boolean;
  begin
    n := i;
    while n <= j do
    begin
      if (GriffEvents[n].GriffPitch in [Griff1, Griff2]) and
          not GriffEvents[n].Cross then
        break;
      inc(n);
    end;
    if n > j then
      exit;

    o := false;
    no := false;
    for k := i to j do
      if (k <> n) and
         GriffEvents[k].IsDiatonic(Instrument) then
      begin
        if GriffEvents[k].Cross or
           odd(GetPitchLine(GriffEvents[k].GriffPitch)) then
          o := true
        else
          no := true;
      end;
    if o <> no then
    begin
      l := GetPitchLine(GriffEvents[n].GriffPitch);
      if GriffEvents[n].GriffPitch = Griff1 then
        Griff1 := Griff2;
      if odd(l) <> o then
        with GriffEvents[n] do
        begin
          GriffPitch := Griff1;
          AbsRect.Top := GetPitchLine(Griff1);
          AbsRect.Height := 1;
        end;
    end;
  end;

begin
  i := iFirst;
  while i <= iLast do
  begin
    while (i <= iLast) and
          not GriffEvents[i].IsDiatonic(Instrument) do
      inc(i);
    if i > iLast then
      break;

    d := GriffEvents[i].GetDuration;

    k := i + 1;
    while (k <= iLast) and
          (not GriffEvents[k].IsDiatonic(Instrument) or
            GriffEvents[k].GetDuration.IsIntersect(d)) do
      inc(k);

    j := k - 1; // Bereich i..j
    if j > i then
    begin
      IsPush_ := false;
      IsPull_ := false;
      for n := i to j do
        if GriffEvents[n].InPush then
          IsPush_ := true
        else
          IsPull_ := true;
      if IsPush_ <> IsPull_ then
      begin
        // Doppelbelegung: Örgeli
        // pull: 71 und 76      Linien 11 und 14
        // push: 71 UND 72      Linien 11 und 12
        //       60 UND 62              5 und  6
        //       81 und 83             17 und 18
        if not GriffEvents[i].InPush then
        begin
          GetIndex(71, 76);
        end else begin
          GetIndex(71, 72);
          GetIndex(60, 62);
          GetIndex(81, 83);
        end;
      end;
    end;
    if k = i then
      inc(k);
    i := k;
  end;
end;

function TGriffPartitur.CheckSustain: boolean;
var
  i, j, k, n: integer;
  push_: boolean;
  pushpull: TPushPullSet;
  d: TGriffDuration;
  ByteSet: set of byte;
begin
  result := true;

  i := 0;
  push_ := true;
  while i < UsedEvents do
  begin
    while (i < UsedEvents) and
          not GriffEvents[i].IsDiatonic(Instrument) do
      inc(i);
    if i >= UsedEvents then
      break;

    //push_ := GriffEvents[i].InPush;
    d := GriffEvents[i].GetDuration;

    k := i + 1;
    while (k < UsedEvents) and
          (not GriffEvents[k].IsDiatonic(Instrument) or
            GriffEvents[k].GetDuration.IsIntersect(d)) do
      inc(k);
    j := k - 1;
//    if j > i then
    begin
      ByteSet := [GriffEvents[i].SoundPitch];
      // i..j: Note On Event
      pushpull := [push, pull];
      for n := i to j do
        if GriffEvents[n].IsDiatonic(Instrument) then
        begin
          pushpull := pushpull * GriffEvents[n].InSet(Instrument);
          ByteSet := ByteSet + [GriffEvents[n].SoundPitch];
        end;
      
      if pushpull <> [] then
      begin
        if (Push_ and (push in pushpull)) then
        begin
        end else
        if (not Push_ and (pull in pushpull)) then
        begin
        end else
          Push_ := push in pushpull;

        for n := i to j do
          if GriffEvents[n].IsDiatonic(Instrument) and
             (GriffEvents[n].InPush <> push_) then
          begin
            GriffEvents[n].InPush := Push_;
            GriffEvents[n].SoundToGriff(Instrument);
          end;
      end else begin
//        push_ := true;
        result := false;
{$if defined(CONSOLE)}
        write('push-pull error: Index = ', i, '  Measure = ',
              GriffEvents[i].AbsRect.Left div GriffHeader.Details.TicksPerMeasure + 1,
              '  SoundPitches = ');
        for n := 0 to 127 do
          if n in ByteSet then
            write(MidiOnlyNote(n, Instrument.Sharp), ' ');
        writeln;
{$endif}
      end;
    end;
    if k = i then
      inc(k);
    i := k;
  end;
end;
{$endif}

procedure TGriffPartitur.PurgeBass;
var
  iEvent, iNew: integer;
  NullBass: boolean;
begin
  NullBass := false;
  for iEvent := 0 to UsedEvents-1 do
    if (GriffEvents[iEvent].NoteType = ntBass) and
       (GriffEvents[iEvent].GriffPitch = 0) then
    begin
      NullBass := true;
      break;
    end;

  iNew := 0;
  for iEvent := 0 to UsedEvents-1 do
    with GriffEvents[iEvent] do
      if (NoteType <> ntBass) or
         ((GriffPitch > 0) and NullBass) or
         (Repeat_ <> rRegular) then
      begin
        if (NoteType = ntBass) and
           (Repeat_ <> rRegular) then
        begin
          NoteType := ntRepeat;
          Cross := false;
          AbsRect.Top := 0;
          AbsRect.Height := 1;
        end;
        if iNew < iEvent then
          GriffEvents[iNew] := GriffEvents[iEvent];
        inc(iNew);
      end;
  GriffHeader.UsedEvents := iNew;

  RepeatToRest;
end;

procedure TGriffPartitur.RepeatToRest;
var
  iEvent: integer;
  Event: TGriffEvent;
begin
  iEvent := 0;
  while iEvent < UsedEvents do
  begin
    Event := GriffEvents[iEvent];
    if Event.NoteType = ntRepeat then
    begin
      case Event.Repeat_ of
        rRegular,
        rStart, rVolta1Start, rVolta2Start: begin end;
        rStop, rVolta1Stop, rVolta2Stop:
          begin
            if iEvent < UsedEvents-1 then
            begin
              if abs(Event.AbsRect.Right - GriffEvents[iEvent+1].AbsRect.Right) < 5 then
              begin
                GriffEvents[iEvent+1].Repeat_ := Event.Repeat_;
                DeleteEvent(iEvent);
                continue;
              end;
            end;
            if iEvent > 0 then
            begin
              if abs(Event.AbsRect.Right - GriffEvents[iEvent-1].AbsRect.Right) < 5 then
              begin
                GriffEvents[iEvent-1].Repeat_ := Event.Repeat_;
                DeleteEvent(iEvent);
                continue;
              end;
              GriffEvents[iEvent].AbsRect.Left := GriffEvents[iEvent-1].AbsRect.Right;
            end;
            if iEvent < UsedEvents-1 then
            begin
              GriffEvents[iEvent].AbsRect.Right := GriffEvents[iEvent+1].AbsRect.Left;
            end;
            GriffEvents[iEvent].NoteType := ntRest;
          end;
      end;
    end;
    inc(iEvent);
  end;
end;

procedure TGriffPartitur.DelayBass(delay: integer);
var
  ticks: integer;
  iEvent: integer;
begin
  ticks := GriffHeader.Details.MsDelayToTicks(delay);
  for iEvent := 0 to UsedEvents-1 do
    if GriffEvents[iEvent].NoteType = ntBass then
      GriffEvents[iEvent].AbsRect.Offset(ticks, 0);
  SortEvents;
end;

function TGriffPartitur.DeleteMp3(VelocityDelta: byte): boolean;
var
  iEvent, k: integer;
begin
  k := 0;
  for iEvent := 0 to UsedEvents-1 do
    if (GriffEvents[iEvent].Velocity >= VelocityDelta) and
       (GriffEvents[iEvent].AbsRect.Width > 10) then
    begin
      if k < iEvent then
        GriffEvents[k] := GriffEvents[iEvent];
      inc(k);
    end;
  result := k < UsedEvents;
  GriffHeader.UsedEvents := k;
end;


procedure TGriffPartitur.TransposeInstrument(delta: integer);
var
  d, iEvent: integer;
begin
  d := delta - Instrument.TransposedPrimes;
  Instrument.Transpose(d);
  for iEvent := 0 to UsedEvents-1 do
    GriffEvents[iEvent].Transpose(d);
end;

function TGriffPartitur.PlayControl(CharCode: word; KeyData: LongInt): boolean;
var
  ch: char;
  Key: integer;
  i, t: integer;
begin
  ch := #0;
//  writeln(charcode, '  ', Inttohex(Keydata));
  Key := (KeyData shr 16) and $1ff;
  case Key of
    79..81: ch := chr(Key-79+ord('1'));
    75..77: ch := chr(Key-75+ord('4'));
    71..73: ch := chr(Key-71+ord('7'));
    74:     ch := '-';
    55:     ch := '*';
    $135:   ch := '/';
    82:     ch := '0';
    83:     ch := '.';
    $11c:   ch := chr(13);
    78:     ch := '+';
  end;
  result := ch <> #0;

  case ch of
    '0': if PartiturLoaded and (@DoPlay <> nil) then
           DoPlay(self);
    '4': // langsamer
         begin
           PlayFactor := PlayFactor - 0.1;
           if PlayFactor < 0.2 then
             PlayFactor := 0.2;
         end;
    '5': // schneller
         begin
           PlayFactor := PlayFactor + 0.1;
           if PlayFactor > 6.0 then
             PlayFactor := 3.0;
         end;
    #13: // stoppen / von vorne beginnen
         if PartiturLoaded and (@DoPlay <> nil) then
         begin
           fSelected := -1;
           SetRubberOff;
           if IsPlaying then
           begin
             iSkipEvent := -1;
             StopPlay := true;
           end else begin
             PlayEvent.Clear;
             DoPlay(self);
           end;
         end;
    '.': // 4 Sekunden zurück
         begin
           i := PlayEvent.iEvent;
           if (i >= 0) and (i < UsedEvents) then
           begin
             t := GriffEvents[i].AbsRect.Left - GriffHeader.Details.MsDelayToTicks(4000);
             i := 0;
             while (i < UsedEvents) and (GriffEvents[i].AbsRect.Left < t) do
               inc(i);
             if i < UsedEvents then
             begin
               iSkipEvent := i;
               StopPlay := true;
             end;
           end;
         end;
    '1': // A - start loop
         if IsPlaying then
         begin
           iAEvent := PlayEvent.iEvent;
           iBEvent := -1;
         end;
    '2': // B - end loop
         if IsPlaying and (iAEvent >= 0) then
         begin
           iBEvent := PlayEvent.iEvent;
         end;
    '3': // end loop
         if IsPlaying then
         begin
           iBEvent := -1;
           iAEvent := -1;
         end;
    '+': begin
           Volume := Volume + 0.1;
           if Volume > 1.0 then
             Volume := 1.0;
         end;
    '-': begin
           Volume := Volume - 0.1;
           if Volume < 0.3 then
             Volume := 0.3;
         end;
    else ch := #0;
  end;

  if not IsPlaying and  (AnsiChar(ch) in ['1'..'3']) then
    ch := #0;

{$if defined(CONSOLE)}
  case AnsiChar(ch) of
    '1': writeln('loop start set');
    '2': writeln('loop end set');
    '3': writeln('loop cleared');
    '4', '5': writeln('play factor: ', PlayFactor:4:1, '   beats per minute: ',
                      round(PlayFactor*GriffHeader.Details.beatsPerMin));
    '+', '-': writeln('volume: ', Volume:4:1);
  end;
{$endif}
end;




////////////////////////////////////////////////////////////////////////////////

function TGriffPartitur.AufViertelnotenAufrunden: boolean;
var
  iEvent: integer;
  T, Dur: TGriffDuration;
begin
  result := true;
  iEvent := 0;
  T.Left := quarterNote div 2 + 2;
  T.Right := quarterNote - 2;
  while result and (iEvent < UsedEvents) do
  begin
    Dur := GriffEvents[iEvent].GetDuration;
    Dur.Left := dur.Left mod quarterNote + 4;
    Dur.Right := dur.Right mod quarterNote - 4;
    if T.IsIntersect(Dur) and (Dur.Width <= quarterNote div 2) then
      result := false;
    inc(iEvent);
  end;
end;


////////////////////////////////////////////////////////////////////////////////


procedure TPlayRecord.Clear;
begin
  iEvent := 0;
  iVolta := 0;
  iStartEvent := 0;
  iStartVolta := 0;
end;

procedure TGriffPartitur.SetBassGriff;

  procedure Exchange(Idx1, Idx2: integer);
  var
    Event: TGriffEvent;
  begin
    if GriffEvents[Idx1].SoundPitch > GriffEvents[Idx2].SoundPitch then
    begin
      Event := GriffEvents[Idx1]; GriffEvents[Idx1] := GriffEvents[Idx2]; GriffEvents[Idx2] := Event;
    end;
  end;

var
  iEvent, i, j: integer;
  n, l: integer;
  d, diff1, diff2: integer;
  event, Event1: TGriffEvent;
  BassDone: boolean;
begin
  if Instrument.BassDiatonic then
    exit;

  i := 0;
  while i < UsedEvents do
    if (GriffEvents[i].NoteType = ntBass) and
       (GriffEvents[i].Repeat_ <> rRegular) then
      exit
    else
      inc(i);

  iEvent := 0;
  i := 0;
  while i < UsedEvents do
  begin
    event := GriffEvents[i];
    if iEvent >= 946 then
        i := i;
    if event.NoteType <> ntBass then
    begin
      GriffEvents[iEvent] := event;
      inc(i);
      inc(iEvent);
    end else begin
      j := i+1;
      while (j < UsedEvents) and
            (GriffEvents[j].NoteType = ntBass) and
            (abs(event.AbsRect.Left - GriffEvents[j].AbsRect.Left) < 10) and
            (abs(event.AbsRect.Right - GriffEvents[j].AbsRect.Right) < 10) do
        inc(j);
      dec(j);

      // sort
      for n := i to j-1 do
        for l := n+1 to j do
          Exchange(n, l);

      // doppelte löschen
      for l := j downto i+1 do
        if GriffEvents[l].SoundPitch = GriffEvents[l-1].SoundPitch then
        begin
          DeleteEvent(l);
          dec(j);
        end;


      BassDone := false;
      if (j > i) then
      begin
        for n := i+1 to j do
          if GriffEvents[i].SoundPitch + 12 = GriffEvents[n].SoundPitch then
          begin
            if j-i >= 3 then
              DeleteEvent(n);
            GriffEvents[iEvent] := GriffEvents[i];
            inc(i);
            inc(iEvent);
            BassDone := true;
          end;
      end;
      if BassDone then
        continue;

      if j >= i+2 then
      begin
        diff1 := GriffEvents[i+1].SoundPitch - GriffEvents[i].SoundPitch;
        diff2 := GriffEvents[i+2].SoundPitch - GriffEvents[i+1].SoundPitch;
        Event1 := GriffEvents[i+1];

        d := Event1.SetGriff(Instrument, false, false);
        if d <= 0 then
        begin
          if (diff1 = 3) and (diff2 = 5) then
          begin
            dec(Event1.SoundPitch, 4);
          end else
          if (diff1 = 5) and (diff2 = 4) then
          begin
            inc(Event1.SoundPitch, 5);
          end else
          if (diff1 = 4) and (diff2 = 3) then
          begin
            inc(Event1.SoundPitch, 5);
          end;
          d := Event1.SetGriff(Instrument, false, false);
          if d <= 0 then
          begin
            dec(Event1.SoundPitch, 12);
            d := Event1.SetGriff(Instrument, false, false);
          end;
          Event1.Cross := true;
        end;
        Event1.GriffPitch := d;
        if d > 0 then
        begin
          GriffEvents[iEvent] := Event1;
          inc(iEvent);
        end;
        inc(i, 3);
        continue;
      end;

      while i <= j do
      begin
        GriffEvents[iEvent] := GriffEvents[i];
        inc(i);
        if GriffEvents[iEvent].SoundPitch > 20 then
          inc(iEvent);
      end;
    end;
  end;
  GriffHeader.UsedEvents := iEvent;
  SortEvents;
end;

initialization
  GriffPartitur_ := TGriffPartitur.Create;
  GriffPartitur_.ColorNote := $ff0000;
  GriffPartitur_.UseEllipses := false;

finalization

  GriffPartitur_.Free;


end.

