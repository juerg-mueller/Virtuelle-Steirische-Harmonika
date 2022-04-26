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
unit UGriffArray;

interface

uses
  SysUtils,
  UMyMidiStream, UGriffEvent, UEventArray, UInstrument;

type

  TGriffArray = class
    class procedure CopyToGriff(var GriffEvents: TGriffEventArray; const MidiEvents: TMidiEventArray);
    class procedure CopyToMidi(var MidiEvents: TMidiEventArray; const GriffEvents: TGriffEventArray; Channel: byte);
    class procedure SortGriffEvents(var GriffEvents: TGriffEventArray; var Selected: integer);
    class procedure ReduceBass(var GriffEvents: TGriffEventArray); overload;
    class procedure ReduceBass(var MidiEvents: TMidiEventArray; Channel: integer); overload;
    class procedure DeleteDoubles(var GriffEvents: TGriffEventArray);
    class procedure DeleteGriffEvent(var GriffEvents: TGriffEventArray; Index: integer);
    class procedure SplitBass(var DiskantGriffEvents, BassGriffEvents: TGriffEventArray;
                              const GriffEvents: TGriffEventArray);
    class procedure CopyGriffToMidi(var MidiEvents: TMidiEventArray;
                                    const GriffEvents: TGriffEventArray;
                                    Bass, BassDiatonic: boolean;
                                    realGriffschrift: boolean);
    class procedure SaveMidiToFile(FileName: string;
                                   const GriffEvents: TGriffEventArray;
                                   const Instrument: TInstrument;
                                   const DetailHeader: TDetailHeader;
                                   realGriffschrift: boolean);
    class procedure SaveSimpleToFile(FileName: string;
                                     const MidiTracks: TTrackEventArray;
                                     const DetailHeader: TDetailHeader);


  end;

implementation

uses
  UMidiDataStream, Midi;

class procedure TGriffArray.CopyToMidi(var MidiEvents: TMidiEventArray; const GriffEvents: TGriffEventArray; Channel: byte);
var
  i, iGriff, iMidi: integer;
  Offset: integer;
  MidiEvent: TMidiEvent;
  Dur: array [0..127] of integer;
  Empty: boolean;

  procedure AddStops;
  var
    i: integer;
  begin
    Empty := true;
    for i := 0 to 127 do
      if Dur[i] = Offset then
      begin
        MidiEvent.Clear;
        MidiEvent.command := $80 + (Channel and $7f);
        MidiEvent.d1 := i;
        MidiEvent.d2 := $40;

        MidiEvents[iMidi] := MidiEvent;
        inc(iMidi);
      end else
      if Dur[i] > Offset then
        Empty := false;
  end;

begin
  SetLength(MidiEvents, 3*Length(GriffEvents));

  for i := 0 to 127 do
    Dur[i] := -1;

  Offset := 0;
  MidiEvent.Clear;
  MidiEvents[0] := MidiEvent;
  iGriff := 0;
  iMidi := 1;
  while iGriff < Length(GriffEvents) do
    if GriffEvents[iGriff].NoteType in [ntDiskant, ntBass] then
      with GriffEvents[iGriff] do
      begin
        AddStops;
        if AbsRect.Left = Offset then
        begin
          MidiEvent.Clear;
          MidiEvent.command := $90 + (Channel and $7f);
          MidiEvent.d1 := SoundPitch;
          MidiEvent.d2 := Velocity;

          MidiEvents[iMidi] := MidiEvent;
          inc(iMidi);
          Dur[SoundPitch] := AbsRect.Right;
          inc(iGriff);
        end else begin
          inc(MidiEvents[iMidi-1].var_len);
          inc(Offset);
        end;
      end;
  repeat
    AddStops;
    inc(MidiEvents[iMidi-1].var_len);
    inc(Offset);
  until Empty;
  SetLength(MidiEvents, iMidi);
end;

class procedure TGriffArray.CopyToGriff(var GriffEvents: TGriffEventArray; const MidiEvents: TMidiEventArray);
var
  iGriff, iMidi: integer;
  Offset: integer;
  GriffEvent: TGriffEvent;
begin
  iGriff := 0;
  iMidi := 0;
  SetLength(GriffEvents, Length(MidiEvents));

  Offset := 0;
  while iMidi < Length(MidiEvents) do
  begin
    with MidiEvents[iMidi] do
    begin
      if MidiEvents[iMidi].Event = 9 then
      begin
        GriffEvent.Clear;
        GriffEvent.NoteType := ntBass;
        GriffEvent.SoundPitch := d1;
        GriffEvent.Velocity := d2;
        GriffEvent.AbsRect.Left := Offset;
        GriffEvent.AbsRect.Width := TEventArray.GetDelayEvent(MidiEvents, iMidi);
        GriffEvent.AbsRect.Top := -1;
        GriffEvent.AbsRect.Height := 1;

        GriffEvents[iGriff] := GriffEvent;
        inc(iGriff);
      end;
      inc(Offset, var_len);
      inc(iMidi);
    end;
  end;

  SetLength(GriffEvents, iGriff);
end;

class procedure TGriffArray.SortGriffEvents(var GriffEvents: TGriffEventArray; var Selected: integer);

  procedure Exchange(i, j: integer);
  var
    Event: TGriffEvent;
  begin
    if i = Selected then
      Selected := j
    else
    if j = Selected then
      Selected := i;

    Event := GriffEvents[i];
    GriffEvents[i] := GriffEvents[j];
    GriffEvents[j] := Event;
  end;

var
  i, k, j: integer;
  UsedEvents: integer;
  RepeatStart, RepeatStop: TRepeat;
begin
  UsedEvents := Length(GriffEvents);
  for i := 0 to UsedEvents-2 do
    for k := i + 1 to UsedEvents-1 do
    begin
      if (GriffEvents[i].AbsRect.Left > GriffEvents[k].AbsRect.Left) or
         ((GriffEvents[i].AbsRect.Left = GriffEvents[k].AbsRect.Left) and
          (GriffEvents[i].AbsRect.Right > GriffEvents[k].AbsRect.Right)) or
         ((GriffEvents[i].AbsRect.Left = GriffEvents[k].AbsRect.Left) and
          (GriffEvents[i].AbsRect.Right = GriffEvents[k].AbsRect.Right) and
          (GriffEvents[i].AbsRect.Top > GriffEvents[k].AbsRect.Top)) then
      begin
        Exchange(i, k);
      end;
    end;

  // tiefer Bass vor hohem (Cross) Bass
  i := 0;
  while (i < UsedEvents-1) do
  begin
    while (i < UsedEvents-1) and
          (GriffEvents[i].NoteType <> ntBass) do
      inc(i);
    k := i;
    while (k < UsedEvents - 1) and
          (GriffEvents[k+1].NoteType = ntBass) do
    begin
      if (GriffEvents[i].AbsRect.Left = GriffEvents[k+1].AbsRect.Left) and
         (GriffEvents[i].AbsRect.Right = GriffEvents[k+1].AbsRect.Right) then
        inc(k)
      else
        break;
    end;

    while k > i do
    begin
      for j := i+1 to k do
        if GriffEvents[i].SoundPitch > GriffEvents[j].SoundPitch then
        begin
          Exchange(i, j);
        end;
      inc(i);
    end;
    inc(i);
  end;

{$if true}
  i := 0;
  while i < UsedEvents-1 do
  begin
    k := i;
    RepeatStart := rRegular;
    RepeatStop := rRegular;
    while (k < UsedEvents) and
          (GriffEvents[i].AbsRect.Left = GriffEvents[k].AbsRect.Left) do
    begin
      if GriffEvents[k].Repeat_ in [rStart, rVolta1Start, rVolta2Start] then
        RepeatStart := GriffEvents[k].Repeat_
      else
      if GriffEvents[k].Repeat_ in [rStop, rVolta1Stop, rVolta2Stop] then
        RepeatStop := GriffEvents[k].Repeat_;
      inc(k);
    end;
    dec(k);

    if (RepeatStart <> rRegular) or (RepeatStop <> rRegular) then
    begin
{$if defined(CONSOLE)}
      if (i = k) and (RepeatStart <> rRegular) and (RepeatStop <> rRegular) then
        writeln('Error repeat event: ', i);
{$endif}
      if i < k then
      begin
        GriffEvents[i].Repeat_ := RepeatStart;
        GriffEvents[k].Repeat_ := RepeatStop;
        for j := i + 1 to k - 1 do
          GriffEvents[j].Repeat_ := rRegular;
      end;
    end;
    i := k + 1;
  end;
{$endif}
end;

class procedure TGriffArray.DeleteDoubles(var GriffEvents: TGriffEventArray);
var
  i, k: integer;
begin
  i := 0;
  k := 0;
  while (i < Length(GriffEvents)-1) do
  begin
    if not GriffEvents[i].IsEqual(GriffEvents[i+1]) then
    begin
      if i <> k then
        GriffEvents[k] := GriffEvents[i];
      inc(k);
    end;
    inc(i);
  end;
  GriffEvents[k] := GriffEvents[i];
  inc(k);
  SetLength(GriffEvents, k);
end;

class procedure TGriffArray.DeleteGriffEvent(var GriffEvents: TGriffEventArray; Index: integer);
var
  i: integer;
begin
  if (Index >= 0) and (Index < Length(GriffEvents)) then
  begin
    for i := Index to Length(GriffEvents)-2 do
      GriffEvents[i] := GriffEvents[i+1];
    SetLength(GriffEvents, Length(GriffEvents)-1);
  end;
end;

class procedure TGriffArray.ReduceBass(var GriffEvents: TGriffEventArray);
var
  i, j, l, n: integer;
  BassDone: boolean;
  Pitch: byte;
begin
  n := -1;
  SortGriffEvents(GriffEvents, n);
  DeleteDoubles(GriffEvents);

  i := 0;
  while (i < Length(GriffEvents)) do
  begin
    if (GriffEvents[i].NoteType <> ntBass) then
    begin
      inc(i);
      continue;
    end;
    if i > 800 then
      i := i;

    j := i + 1;
    while (j < Length(GriffEvents)) and
          (GriffEvents[j].NoteType = ntBass) and
          (GriffEvents[i].AbsRect.Left = GriffEvents[j].AbsRect.Left) and
          (GriffEvents[i].AbsRect.Right = GriffEvents[j].AbsRect.Right) do
      inc(j);
    dec(j);

    BassDone := false;
    for l := i to j do
      if GriffEvents[i].SoundPitch + 12 = GriffEvents[l].SoundPitch then
      begin
        if GriffEvents[i].SoundPitch > 44 then
          dec(GriffEvents[i].SoundPitch, 12);
        if j - i < 2 then
          DeleteGriffEvent(GriffEvents, l);
        inc(i);
        BassDone := true;
        break;
      end;
    if BassDone then
      continue;

    if j - i >= 2 then
    begin
      Pitch := GriffEvents[i].SoundPitch;
      if ((GriffEvents[i].SoundPitch + 4 = GriffEvents[i+1].SoundPitch) and
          (GriffEvents[i+1].SoundPitch + 3 = GriffEvents[i+2].SoundPitch)) or
         ((GriffEvents[i].SoundPitch + 3 = GriffEvents[i+1].SoundPitch) and
          (GriffEvents[i+1].SoundPitch + 5 = GriffEvents[i+2].SoundPitch)) or
         ((GriffEvents[i].SoundPitch + 5 = GriffEvents[i+1].SoundPitch) and
          (GriffEvents[i+1].SoundPitch + 4 = GriffEvents[i+2].SoundPitch)) then
      begin
        if (GriffEvents[i+0].SoundPitch + 3 = GriffEvents[i+1].SoundPitch) and (GriffEvents[i+1].SoundPitch + 5 = GriffEvents[i+2].SoundPitch) then
          dec(Pitch, 4)
        else
        if (GriffEvents[i+0].SoundPitch + 5 = GriffEvents[i+1].SoundPitch) and (GriffEvents[i+1].SoundPitch + 4 = GriffEvents[i+2].SoundPitch) then
          Pitch := GriffEvents[i+1].SoundPitch;
        if Pitch > 56 then
          dec(Pitch, 12);

        DeleteGriffEvent(GriffEvents, i+2);
        DeleteGriffEvent(GriffEvents, i+1);

        GriffEvents[i].SoundPitch := Pitch;
        inc(i);
        BassDone := true;
      end
    end;
    if not BassDone then
    begin
      inc(i);
    end;
  end;
end;

class procedure TGriffArray.ReduceBass(var MidiEvents: TMidiEventArray; Channel: integer);
var
  GriffEvents: TGriffEventArray;
begin
  CopyToGriff(GriffEvents, MidiEvents);
  ReduceBass(GriffEvents);
  CopyToMidi(MidiEvents, GriffEvents, Channel);
end;


class procedure TGriffArray.SplitBass(var DiskantGriffEvents, BassGriffEvents: TGriffEventArray;
                                      const GriffEvents: TGriffEventArray);
var
  iEvent, iBass, iDiskant: integer;
  Event: TGriffEvent;
begin
  SetLength(DiskantGriffEvents, Length(GriffEvents));
  SetLength(BassGriffEvents, Length(GriffEvents));
  iBass := 0;
  iDiskant := 0;
  for iEvent := 0 to Length(GriffEvents)-1 do
  begin
    Event := GriffEvents[iEvent];
    if Event.NoteType = ntBass then
    begin
  {    if Event.Repeat_<> rRegular then
      begin
        Event.NoteType := ntRepeat;
        DiskantGriffEvents[iDiskant] := Event;
        inc(iDiskant);
        Event.NoteType := ntBass;
        Event.Repeat_ := rRegular;
      end;}
      BassGriffEvents[iBass] := Event;
      inc(iBass);
    end else begin
      DiskantGriffEvents[iDiskant] := Event;
      inc(iDiskant);
    end;
  end;
  SetLength(DiskantGriffEvents, iDiskant);
  SetLength(BassGriffEvents, iBass);
end;

class procedure TGriffArray.CopyGriffToMidi(var MidiEvents: TMidiEventArray;
                                            const GriffEvents: TGriffEventArray;
                                            Bass, BassDiatonic: boolean;
                                            realGriffschrift: boolean);
var
  Off: array [1..6, 0..127] of integer;
  RestOff: integer;
  Offset: integer;
  i, k: integer;
  smallest: integer;
  Ok, IsInPush: boolean;
  D: integer;
  AmpelRect: TAmpelRec;

  iEvent, iMidi: integer;
  MidiEvent: TMidiEvent;
  GriffEvent: TGriffEvent;

  function GetSmallest: integer;
  var
    i, r: integer;
  begin
    result := -1;
    if RestOff > 0 then
      result := RestOff;
    for r := 1 to 6 do
      for i := 0 to High(Off[r]) do
        if (Off[r, i] > 0) and
           ((Off[r, i] < result) or (result = -1)) then
        begin
          result := Off[r, i];
        end;
  end;

  procedure AppendMidiEvent;
  begin
    SetLength(MidiEvents, iMidi+1);
    MidiEvents[iMidi] := MidiEvent;
    inc(iMidi);
    MidiEvent.Clear;
  end;

  procedure GenerateStops(pos: integer);
  var
    i, r: integer;
    Found: boolean;
    iM: integer;
  begin
    Found := RestOff = Pos;
    iM := iMidi;
    for r := 1 to 6 do
      for i := 0 to High(Off[r]) do
        if (Off[r, i] > 0) and (pos <= Off[r, i]) then
        begin
          if Bass then
            MidiEvent.command := $81
          else
            MidiEvent.command := $80;
          MidiEvent.d1 := i;
          MidiEvent.d2 := $40;
          Off[r, i] := 0;
          Found := true;
          AppendMidiEvent;
        end;
    if Found then
    begin
      inc(MidiEvents[iM-1].var_len, pos - offset);
      //offset := pos;
    end;
    if RestOff = Pos then
      RestOff := 0;
    offset := pos;
  end;

begin
  for k := 1 to 6 do
    for i := 0 to 127 do
      Off[k, i] := 0;
  RestOff := 0;

  Offset := 0;
  MidiEvent.Clear;
  iMidi := 0;
  AppendMidiEvent;

  IsInPush := true;
  if not Bass or BassDiatonic then
  begin
    MidiEvent.command := $b0;
    MidiEvent.d1 := ControlSustain;
    MidiEvent.d2 := 0;
    if IsInPush then
      MidiEvent.d2 := 127;
    AppendMidiEvent;
  end;

  for iEvent := 0 to Length(GriffEvents)-1 do
  begin
    GriffEvent := GriffEvents[iEvent];

    if Bass <> (GriffEvent.NoteType = ntBass) then
      continue;

    repeat
      smallest := GetSmallest;
      Ok := (smallest > 0) and
            (smallest <= GriffEvent.AbsRect.Left);
      if Ok then
        GenerateStops(smallest);
    until not Ok;

    if (Offset < GriffEvent.AbsRect.Left) then  // Pause
    begin
      inc(MidiEvents[iMidi-1].var_len, GriffEvent.AbsRect.Left - Offset);
      Offset := GriffEvent.AbsRect.Left;
    end;

    // Wiederholungen
    if (GriffEvent.Repeat_ > rRegular) then
    begin
      MidiEvent.command := $b0;
      if Bass then
        inc(MidiEvent.command);
      MidiEvent.d1 := ControlSustain + 3;
      MidiEvent.d2 := ord(GriffEvent.Repeat_);
      AppendMidiEvent;
    end;

    if (GriffEvent.NoteType > ntBass) then
    begin
      MidiEvent.command := $b0;
      MidiEvent.d1 := ControlSustain + 4;
      MidiEvent.d2 := ord(GriffEvent.NoteType);
      if GriffEvents[iEvent].NoteType = ntRest then
      begin
        MidiEvent.var_len := GriffEvent.AbsRect.Width;
        Offset := GriffEvent.AbsRect.Right;
        AppendMidiEvent;
        MidiEvent.command := $b0;
        MidiEvent.d1 := ControlSustain + 4;
        MidiEvent.d2 := ord(GriffEvent.NoteType);
      end;
      AppendMidiEvent;
      continue;
    end;

    // bereits aktiver Pitch?
    AmpelRect := GriffEvent.GetAmpelRec;
    if realGriffschrift then
    begin
      D := GriffEvent.GriffPitch
    end else begin
      D := GriffEvent.SoundPitch;
    end;
    if (GriffEvent.NoteType <= ntBass) and
       (Off[AmpelRect.row, D] > 0) then
    begin
      if Bass then
        MidiEvent.command := $81
      else
        MidiEvent.command := $80;
      MidiEvent.d1 := D;
      MidiEvent.d2 := $40;
      Off[AmpelRect.row, D] := 0;
      AppendMidiEvent;
    end;
    if (GriffEvent.NoteType > ntBass) then
      continue;

    // Balg-Notation ändert?
    if (not Bass or BassDiatonic) and
       not realGriffschrift then
    begin
      if GriffEvent.InPush <> IsInPush then
      begin
        IsInPush := not IsInPush;
        if Bass then
          MidiEvent.command := $b1
        else
          MidiEvent.command := $b0;
        MidiEvent.d1 := ControlSustain;
        MidiEvent.d2 := 0;
        if IsInPush then
          MidiEvent.d2 := 127;
        AppendMidiEvent;
      end;
    end;

    if GriffEvent.Cross or
       (GriffEvent.GriffPitch <> GriffEvent.SoundPitch) then
    begin
      if not realGriffschrift then
      begin
        if Bass then
          MidiEvent.command := $b1
        else
          MidiEvent.command := $b0;
        MidiEvent.d1 := ControlSustain + 1;
        if GriffEvent.Cross then
          inc(MidiEvent.d1);
        if realGriffschrift then
          MidiEvent.d2 := GriffEvents[iEvent].SoundPitch
        else
          MidiEvent.d2 := GriffEvents[iEvent].GriffPitch;
        AppendMidiEvent;
      end;
    end;

    if Bass then
    begin
      MidiEvent.command := $91;
      MidiEvent.d2 := $7f;
    end else begin
      MidiEvent.command := $90;
      MidiEvent.d2 := $6f;
    end;
    if realGriffschrift then
    begin
      MidiEvent.d1 := GriffEvent.GriffPitch
    end else begin
      MidiEvent.d1 := GriffEvent.SoundPitch;
    end;
    AmpelRect := GriffEvent.GetAmpelRec;
    Off[AmpelRect.row, MidiEvent.d1] := GriffEvent.AbsRect.Right;
    AppendMidiEvent;
  end;
  repeat
    smallest := GetSmallest;
    if smallest >= 0 then
      GenerateStops(smallest);
  until smallest < 0;
end;

class procedure TGriffArray.SaveMidiToFile(FileName: string;
                                           const GriffEvents: TGriffEventArray;
                                           const Instrument: TInstrument;
                                           const DetailHeader: TDetailHeader;
                                           realGriffschrift: boolean);
var
  MidiEvents: TMidiEventArray;
  SaveStream: TMidiSaveStream;
  i: integer;
  MidiEvent: TMidiEvent;
  Header: TDetailHeader;
  MidiTracks: TTrackEventArray;
begin
  SaveStream := TMidiSaveStream.Create;
  try
    SaveStream.SetHead(DetailHeader.DeltaTimeTicks);
    SaveStream.AppendTrackHead;

    if realGriffschrift then
      MidiEvent.MakeMetaEvent(2, Copyrightreal)
    else
      MidiEvent.MakeMetaEvent(2, CopyrightGriff);
    SaveStream.AppendEvent(MidiEvent);

    Header := DetailHeader;
    if realGriffschrift then
    begin
      Header.CDur := 0;
      Header.Minor := false;
    end;
    SaveStream.AppendHeaderMetaEvents(Header);

    SaveStream.AppendTrackEnd(false);

    SetLength(MidiTracks, 2);
    for i := 0 to 1 do
    begin
      TGriffArray.CopyGriffToMidi(MidiEvents, GriffEvents,
                                i = 1, Instrument.BassDiatonic or (i = 0), realGriffschrift);
      MidiTracks[i] := MidiEvents;

      if (i = 0) or (Length(MidiEvents) > 1) then
      begin
        SaveStream.AppendTrackHead(MidiEvents[0].var_len);
        MidiEvents[0].var_len := 0;

        if i = 1 then
          MidiEvent.MakeMetaEvent(3, 'Bass')
        else
          MidiEvent.MakeMetaEvent(3, 'Melodie');
        SaveStream.AppendEvent(MidiEvent);
        MidiEvent.command := $c0;
        if i = 1 then
          MidiEvent.command := $c1;
        MidiEvent.d1 := MidiInstr;
        SaveStream.AppendEvent(MidiEvent);

        if Instrument.Name <> '' then
        begin
          MidiEvent.MakeMetaEvent(4, Instrument.Name);
          SaveStream.AppendEvent(MidiEvent);
        end;
        SaveStream.AppendEvents(MidiEvents);
        SaveStream.AppendTrackEnd(false);
      end
    end;
    SaveStream.Size := SaveStream.Position;
    SaveStream.SaveToFile(FileName);

    SaveSimpleToFile(FileName + '.txt', MidiTracks, DetailHeader);

  finally
    SaveStream.Free;
  end;
end;

class procedure TGriffArray.SaveSimpleToFile(FileName: string;
                                             const MidiTracks: TTrackEventArray;
                                             const DetailHeader: TDetailHeader);
var
  iTrack, iMidiEvent, i : integer;
  Push: boolean;
  Delta, takt: integer;
  Datastream: TSimpleDataStream;
  MidiEvent: TMidiEvent;
begin
  Datastream := TSimpleDataStream.Create;
  try
    Delta := 0;
    with DataStream do
    begin
      WritelnString(cSimpleHeader + ' 1 ' + IntToStr(Length(MidiTracks)) +
                    ' ' + IntToStr(DetailHeader.DeltaTimeTicks) +
                    ' ' + IntToStr(DetailHeader.beatsPerMin));

      for iTrack := 0 to Length(MidiTracks)-1 do
      begin
        for iMidiEvent := 0 to Length(MidiTracks[iTrack])-1 do
        begin
          MidiEvent := MidiTracks[iTrack][iMidiEvent];
          if iMidiEvent = 0 then
          begin
            Delta := MidiEvent.var_len;
            WriteTrackHeader(Delta);

            continue;
          end;
          case MidiEvent.Event of
            15:
              if MidiEvent.command = $f0 then
              begin
                WriteString(cSimpleMetaEvent + ' ' + IntToStr(MidiEvent.command) + '    ' +
                  IntToStr(MidiEvent.d1));
                for i := Low(MidiEvent.Bytes) to High(MidiEvent.Bytes) do
                  WriteString(' ' + IntToStr(MidiEvent.Bytes[i]));
              end else begin
                WriteString(cSimpleMetaEvent + ' ' + IntToStr(MidiEvent.command) + ' ' +
                  IntToStr(MidiEvent.d1) + ' ' + IntToStr(MidiEvent.d2));
                for i := Low(MidiEvent.Bytes) to High(MidiEvent.Bytes) do
                  WriteString(' ' + IntToStr(MidiEvent.Bytes[i]));
                if MidiEvent.d2 > 0 then
                  WriteString(' ' + IntToStr(MidiEvent.var_len));
                if MidiEvent.d1 in [2, 3, 4] then
                  WriteAnsiString('  "' + MidiEvent.GetBytes + '"');
              end;
            8..14:
              begin
                if (MidiEvent.Channel = 0) and MidiEvent.IsSustain and (MidiEvent.Event = 11) then
                begin
                  Push := MidiEvent.IsPush;
                  if Push then
                    WriteString(cPush)
                  else
                    WriteString(cPull);
                  WritelnString(' ' + IntToStr(MidiEvent.var_len));
                  continue;
                end;
                if HexOutput then
                begin
                  WriteString(Format('%5d $%2.2x $%2.2x $%2.2x',
                                     [MidiEvent.var_len, MidiEvent.command, MidiEvent.d1, MidiEvent.d2]));
                end else
                  WriteString(Format('%5d %3d %3d %3d',
                                     [MidiEvent.var_len, MidiEvent.command, MidiEvent.d1, MidiEvent.d2]));
                for i := Low(MidiEvent.Bytes) to High(MidiEvent.Bytes) do
                  WriteString(' ' + IntToStr(MidiEvent.Bytes[i]));
                if MidiEvent.Event in [8, 9] then
                begin
                  if MidiEvent.Event = 9 then
                  begin
                    takt := Delta div DetailHeader.DeltaTimeTicks;
                    if DetailHeader.measureDiv = 8 then
                      takt := 2*takt;
                    WriteString(Format('  Takt: %.2f', [takt / double(DetailHeader.measureFact) + 1]));
                  end;
                  inc(Delta, MidiEvent.var_len);
              //     WriteString('  LineNr: ' + IntToStr(iMidiEvent));
             //     if event.Event = 9 then
             //       WriteString(' ' + IntToStr(OffIndex));
                end;
              end;
              else begin end;
          end;
          if MidiEvent.Event >= 8 then
            WritelnString('');
        end;
      end;
    end;
    Datastream.SaveToFile(FileName);
  finally
    Datastream.Free;
  end;
end;

end.


