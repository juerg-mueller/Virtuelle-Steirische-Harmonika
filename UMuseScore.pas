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
unit UMuseScore;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Zip,
  UGriffPartitur;


  function LoadFromMscx(GriffPartitur: TGriffPartitur; FileName: string): boolean;
  function SaveToMscx(GriffPartitur: TGriffPartitur; const FileName: string): boolean;

implementation

uses
  UXmlNode, UXmlParser, UEventArray, UGriffArray, UGriffEvent,
  UMyMidiStream, UInstrument, USheetMusic, UMyMemoryStream, UMidiEvent;

const
  UseBellows = true;
  UseColors_ = false;
  UseGrandCross = true;
  BellowsWidth = 0.5;

  UseColors = UseColors_ or not UseBellows;

function LoadFromMscx(GriffPartitur: TGriffPartitur; FileName: string): boolean;
const
  Harmony: array [0..35] of integer = (2, 9, 4, -1, 6, 1, 8, 3, 10, 5, 0, 7,
                                       14, 21, 16, 11, 18, 13, 20, 15, -10, 17, 12, 19,
                                       26, 33, 28, 23, 30, 25, 32, 27, 22, 29, 24, 31);
type
  TRepRec = record
    offset: integer;
    repType: TRepeat;
  end;

var
  RepOffsets: array of TRepRec;
  VoltaNr: integer;
  endings, nextLocation: integer;
  Rep: TRepeat;

  procedure AddRep(offset_: integer; repType_: TRepeat);
  var
    i, k: integer;
  begin
    // sortiert einordnen
    i := 0;
    while (i < Length(RepOffsets)) and
          (RepOffsets[i].offset < offset_) do
      inc(i);
    SetLength(RepOffsets, Length(RepOffsets) + 1);
    for k := Length(RepOffsets)-2 downto i do
      RepOffsets[k+1] := RepOffsets[k];

    with RepOffsets[i] do
    begin
      offset := offset_;
      repType := RepType_;
    end;
  end;

  function GetRep(offset_: integer; Stop: boolean): TRepeat;
  var
    i: integer;
    d: TGriffDuration;
  begin
    with GriffPartitur.GriffHeader.Details do
    begin
      result := rRegular;
      d.Left := TicksPerMeasure * (offset_ div TicksPerMeasure);
      d.Right := d.Left + TicksPerMeasure;
      for i := Low(RepOffsets) to High(RepOffsets) do
        if d.PointIsIn(RepOffsets[i].offset) then
        begin
          if (RepOffsets[i].repType = rStop) and (i < High(RepOffsets)) and
             (RepOffsets[i+1].repType = rVolta1Stop) then
            RepOffsets[i].repType := rRegular;

          result := RepOffsets[i].repType;
          if (result in [rStop, rVolta1Stop, rVolta2Stop]) and Stop then
            break;
          if (result in [rStart, rVolta1Start, rVolta2Start]) and not Stop then
            break;
          result := rRegular;
        end;
    end;
  end;

  function GetFactor(const s: string): double;
  var
    denom: integer;
    i: integer;
  begin
    result := 0;
    denom := 0;
    i := 1;
    while (i <= Length(s)) and CharInSet(s[i], ['0'..'9']) do
    begin
      result := 10*result + ord(s[i]) - ord('0');
      inc(i);
    end;
    if (i <= Length(s)) and (s[i] = '/') then
    begin
      inc(i);
      while (i <= Length(s)) and CharInSet(s[i], ['0'..'9']) do
      begin
        denom := 10*denom + ord(s[i]) - ord('0');
        inc(i);
      end;
    end;
    if denom > 0 then
      result := result / denom;
  end;

  function GetEndings(Spanner: KXmlNode): boolean;
  var
    i, k: integer;
    Child: KXmlNode;
  begin
    result := false;
    for i := 0 to Spanner.ChildNodesCount-1 do
      if Spanner.ChildNodes[i].Name = 'Volta' then
      begin
        Child := Spanner.ChildNodes[i];
        for k := 0 to Child.ChildNodesCount-1 do
          with Child.ChildNodes[k] do
            if Name = 'endings' then
            begin
              endings := StrToIntDef(Value, 1);
              result := true;
             break;
            end;
      end else
      if Spanner.ChildNodes[i].Name = 'next' then
      begin
        Child := Spanner.ChildNodes[i];
        if (Child.ChildNodesCount = 1) and
           (Child.ChildNodes[0].Name = 'location') then
        begin
          Child := Child.ChildNodes[0];
//          writeln(Child.ChildNodes.Count, '  ', Child.ChildNodes[0].Name);
          if (Child.ChildNodesCount = 1) then
          begin
            nextLocation := 0;
            if (Child.ChildNodes[0].Name = 'measures') then
              nextLocation := StrToIntDef(Child.ChildNodes[0].Value, 0)
       {     else
            // am Schluss der Partitur
            if (Child.ChildNodes[0].Name = 'fractions') then
            begin
              d := GetFactor(Child.ChildNodes[0].Value);
              nextLocation := round(d*2);
            end; }
          end;
        end;
      end;
  end;

  procedure AppendStopEvent(Rep_: TRepeat);
  var
    n: integer;
    event: TGriffEvent;
  begin
    with GriffPartitur do
    begin
      n := GriffEvents[UsedEvents-1].AbsRect.Right mod GriffHeader.Details.TicksPerMeasure;
      if (n = 0) and (UsedEvents > 0)  then
        GriffEvents[UsedEvents-1].Repeat_ := Rep_
      else begin
        event.MakeRest;
        event.Repeat_ := Rep_;
        event.AbsRect.Left := GriffEvents[UsedEvents-1].AbsRect.Right;
        event.AbsRect.Width := GriffHeader.Details.TicksPerMeasure - n;
        AppendEvent(event);
      end;
    end;
  end;

  function MakeStopEvent(Left: integer): integer;
  begin
    with GriffPartitur do begin
      result := 0;
      if UsedEvents > 0 then
        result := Left div GriffHeader.Details.TicksPerMeasure -
                  (GriffEvents[UsedEvents-1].AbsRect.Right-1) div GriffHeader.Details.TicksPerMeasure;
      if result <> 0 then // neuer Takt
      begin
        Rep := GetRep(GriffEvents[UsedEvents-1].AbsRect.Right-1, true);
        if Rep <> rRegular then
          AppendStopEvent(Rep);
      end;
    end;
  end;

var
  Root, Score, Staff, Measure, Voice, Chord, Note, Child, Child1: KXmlNode;
  iStaff, iScore, iMeasure, iVoice, iChord, iNote, l, k, m, n: integer;
  Dots, Duration: integer;
  offset: integer;
  s: string;
  event, event2: TGriffEvent;
  StaffNr: integer;
  diskantRead: boolean;
  tiePrev, appoggiatura, prevAppoggiatura, IsTuplet, bassStaff, isRest: boolean;
  Volta, HarmonyRoot: integer;
  ole: oleVariant;
  Auftakt: string;
  OffsetAuftakt: integer;
  visible: boolean;
  Bass2015: boolean;
  SteiBass_: TSteiBass;
  MeasureNr: integer;
{$ifdef dcc}
  Zip_: System.Zip.TZipFile;
{$endif}
  Outp: TBytes;
begin
  Root := nil;
  result := KXmlParser.ParseFile(FileName, Root);
  if not result then
    exit;

  with GriffPartitur do
  begin
    Clear;
    GriffHeader.Details.IsSet := true;
    diskantRead := false;
    Duration := 0;
    OffsetAuftakt := 0;
    Auftakt := '';
    Bass2015 := false;
    SteiBass_ := SteiBass;

    for iScore := 0 to Root.ChildNodesCount-1 do
    begin
      Score := Root.ChildNodes[iScore];
      if Score.Name = 'Score' then
      begin
        StaffNr := 0;
        BassStaff := false;
        for iStaff := 0 to Score.ChildNodesCount-1 do
        begin
          Offset := OffsetAuftakt;
          Staff := Score.ChildNodes[iStaff];
          if Staff.Name = 'Division' then
          begin
            GriffHeader.Details.DeltaTimeTicks := StrToIntDef(Staff.Value, 120);
          end else
          if Staff.Name = 'Staff' then
          begin
            inc(StaffNr);
            MeasureNr := 0;
            for iMeasure := 0 to Staff.ChildNodesCount-1 do
            begin
              Measure := Staff.ChildNodes[iMeasure];
              if Measure.Name = 'Measure' then
              begin
                inc(MeasureNr);
                if (MeasureNr = 1) and (Auftakt = '') and Measure.HasAttribute('len') then
                begin
                  Auftakt := Measure.Attributes['len'];
                end;
                appoggiatura := false;
                prevAppoggiatura := false;
                endings := 0;
                nextLocation := 0;
                for iVoice := 0 to Measure.ChildNodesCount-1 do
                begin
                  Voice := Measure.ChildNodes[iVoice];
                  if Voice.Name = 'startRepeat' then
                  begin
                    AddRep(offset, rStart);
                  end else
                  if Voice.Name = 'endRepeat' then
                  begin
                    AddRep(offset, rStop);
                  end else
                  if Voice.Name = 'voice' then
                  begin
                    IsTuplet := false;
                    HarmonyRoot := -10;
                    for iChord := 0 to Voice.ChildNodesCount-1 do
                    begin
                      Chord := Voice.ChildNodes[iChord];
                      if (Chord.Name = 'Spanner') and
                         Chord.HasAttribute('type') then
                      begin
                        s := Chord.Attributes['type'];
                        if s = 'Volta' then
                        begin
                          if GetEndings(Chord) then
                          begin
                            if endings = 1 then
                            begin
                              AddRep(offset, rVolta1Start);
                              AddRep(offset + nextLocation*GriffHeader.Details.TicksPerMeasure - 1, rVolta1Stop);
                            end else
                            if endings = 2 then
                            begin
                              AddRep(offset, rVolta2Start);
                              if nextLocation = 0 then
                                nextLocation := 1;
                              AddRep(offset + nextLocation*GriffHeader.Details.TicksPerMeasure - 1, rVolta2Stop);
                            end;
                          end
                        end;
                      end else
                      if Chord.Name = 'TimeSig' then
                      begin
                        if not diskantRead then
                        begin
                          for l := 0 to Chord.ChildNodesCount-1 do
                          begin
                            Child := Chord.ChildNodes[l];
                            if Child.Name = 'sigN' then
                              GriffHeader.Details.measureFact := StrToIntDef(Child.Value, 4)
                            else
                            if Child.Name = 'sigD' then
                              GriffHeader.Details.measureDiv := StrToIntDef(Child.Value, 4);
                          end;
                        end;
                      end else
                      if (Chord.Name = 'StaffText') and
                         (Chord.ChildNodesCount = 1) and
                         diskantRead then
                      begin
                        Child := Chord.ChildNodes[0];
                        ole := Child.Value;
                        s := trim(Child.Value);
                        if s <> '' then
                        begin
                          if (Length(s) > 1) and not Bass2015 then
                          begin
                            Bass2015 := true;
                            SteiBass_ := SteiBass2015;
                          end;
                          event.Clear;
                          event.NoteType := ntBass;
                          event.AbsRect.Left := offset;
                          if abs(duration - QuarterNote div 2) < 10 then
                            event.AbsRect.Width := duration div 2
                          else
                            event.AbsRect.Width := duration;
                          event.AbsRect.Top := -1;
                          event.AbsRect.Height := 1;
                          if Instrument.BassDiatonic then
                          begin
                            for l := Low(SteiBass_[5]) to High(SteiBass_[5]) do
                              if string(SteiBass_[5, l]) = s then
                              begin
                                event.GriffPitch := l;
                                break;
                              end else
                              if string(SteiBass_[6, l]) = s then
                              begin
                                event.GriffPitch := l;
                                event.Cross := true;
                                break;
                              end;
                          end else begin
                            l := StrToIntDef(s, 0);
                            if l > 0 then
                            begin
                              event.GriffPitch := l;
                              event.Cross := true;
                            end;
                          end;
                          if event.GriffPitch > 0 then
                            AppendEvent(event);
                        end;
                      end else
                      if Chord.Name  = 'Tuplet' then
                      begin
                        IsTuplet := true;
                      end else
                      if Chord.Name  = 'endTuplet' then
                      begin
                        IsTuplet := false;
                      end else
                      if Chord.Name  = 'Harmony' then
                      begin
                        if Chord.ChildNodesCount >= 1 then
                        begin
                          Child := Chord.ChildNodes[0];
                          HarmonyRoot := StrToIntDef(Child.Value, -10);
                        end;
                      end else
                      if (Chord.Name = 'Rest') or
                         (Chord.Name = 'Chord') then
                      begin
                        isRest := Chord.Name = 'Rest';
                        visible := true;
                        if (MeasureNr = 1) and (Auftakt <> '') and (OffsetAuftakt = 0) then
                        begin
                          OffsetAuftakt := GriffHeader.Details.TicksPerMeasure
                            - round(4*GriffHeader.Details.DeltaTimeTicks*GetFactor(Auftakt));
                          Offset := OffsetAuftakt;
                          for k := Low(RepOffsets) to High(RepOffsets) do
                            inc(RepOffsets[k].offset, OffsetAuftakt);
                        end;

                        Duration := 0;
                        Dots := 0;
                        prevAppoggiatura := appoggiatura;
                        appoggiatura := false;
                        for iNote := 0 to Chord.ChildNodesCount-1 do
                        begin
                          Note := Chord.ChildNodes[iNote];
                          if Note.Name = 'visible' then
                          begin
                            s := Note.Value;
                            visible := s <> '0';
                          end else
                          if Note.Name = 'dots' then
                          begin
                            s := Note.Value;
                            Dots := StrToIntDef(s, 0)
                          end else
                          if IsRest and (Note.Name = 'duration') then
                          begin
                            duration := round(GetFactor(Note.Value)* 4 * GriffHeader.Details.DeltaTimeTicks);
                          end else
                          if (Note.Name = 'durationType') then
                          begin
                            s := Note.Value;
                            duration := 0;
                            if s <> 'measure' then
                            begin
                              l := GetFraction_(s);
                              if l = 0 then
                         {$if defined(CONSOLE)}
                                writeln('error: ', s)
                         {$endif}
                              else
                                duration := 4*GriffHeader.Details.DeltaTimeTicks div l;
                            end;
                            if dots = 1 then
                              inc(duration, duration div 2);
                            if IsTuplet then
                              Duration := 2*Duration div 3;
                            dots := 0;
                          end else
                          if Note.Name = 'appoggiatura' then
                          begin
                            appoggiatura := true;
                          end else
                          if Note.Name = 'Note' then
                          begin
                            event.Clear;
                            event.AbsRect.Left := offset;
                            event.AbsRect.Width := duration;
                            tiePrev := false;
                          {$if defined(CONSOLE)}
                            if duration = 0 then
                              writeln('Duration = 0');
                          {$endif}
                            for l := 0 to Note.ChildNodesCount-1 do
                            begin
                              Child := Note.ChildNodes[l];
                              if Child.Name = 'Spanner' then
                              begin
                                if Child.HasAttribute('type') and
                                   (Child.Attributes['type'] = 'Tie') and
                                   (Child.ChildNodesCount = 1) then
                                  tiePrev := Child.ChildNodes[0].Name = 'prev';
                              end else
                              if Child.Name = 'color' then
                              begin
                                if Child.HasAttribute('b') then
                                  event.InPush := (Child.Attributes['b'] = '255');
                              end else
                              if Child.Name = 'pitch' then
                              begin
                                event.GriffPitch := StrToIntDef(Child.Value, 0);
                                event.AbsRect.Top := GetPitchLine(event.GriffPitch);
                                event.AbsRect.Height := 1;
                              end else
                              if Child.Name = 'Symbol' then
                              begin
                                if (Child.ChildNodesCount >= 1) then
                                begin
                                  Child := Child.ChildNodes[0];
                                  if (Child.Name = 'name') then
                                    event.Cross := Child.Value = 'noteheadXBlack';
                                end;
                              end else
                              if Child.Name = 'head' then
                              begin
                                event.Cross := Child.Value = 'cross';
                              end;
                            end;
                            if not diskantRead then
                            begin
                              event.InPush := not event.InPush; //!!!!!!!!!!!
                              if tiePrev then
                              begin
                                l := UsedEvents - 1;
                                while (l >= 0) and (GriffEvents[l].AbsRect.Right = offset) do
                                  with GriffEvents[l] do
                                    if (NoteType = event.NoteType) and
                                       (GriffPitch = event.GriffPitch) and
                                       (InPush = event.InPush) and
                                       (Cross = event.Cross) then
                                    begin
                                      inc(AbsRect.Right, duration);
                                      tiePrev := false;
                                      break;
                                    end else
                                      dec(l);
                                if not tiePrev then
                                  continue;
                                tiePrev := false;
                              end;
                              if appoggiatura or prevAppoggiatura then
                              begin
                                if appoggiatura then
                                  event.AbsRect.Width := GriffHeader.Details.DeltaTimeTicks div 8 - 1
                                else
                                  inc(event.AbsRect.Left, GriffHeader.Details.DeltaTimeTicks div 8 + 1);
                              end;
                              if not diskantRead then
                              begin
                                m := MakeStopEvent(event.AbsRect.Left);
                                if (m <> 0) or (UsedEvents = 0) then
                                begin
                                  Rep := GetRep(event.AbsRect.Left, false);
                                  if Rep <> rRegular then
                                  begin
                                    n := event.AbsRect.Left mod GriffHeader.Details.TicksPerMeasure;
                                    if n = 0 then
                                      event.Repeat_ := Rep
                                    else begin
                                      event2.MakeRest;
                                      event2.Repeat_ := Rep;
                                      event2.AbsRect.Left := event.AbsRect.Left - n;
                                      event2.AbsRect.Right := event.AbsRect.Left;
                                      AppendEvent(event2);
                                    end;
                                  end;

                                end;
                                AppendEvent(event);

                                if HarmonyRoot > -10 then
                                begin
                                  for l := Low(Harmony) to High(Harmony) do
                                    if HarmonyRoot = Harmony[l] then
                                    begin
                                      event.SoundPitch := 48 + l mod 12;
                                      k := event.SoundToGriffBass(Instrument);
                                      if k > 0 then
                                      begin
                                        event.NoteType := ntBass;
                                        event.GriffPitch := k;
                                        event.AbsRect.Width:= GriffHeader.Details.DeltaTimeTicks div 2;
                                        event.AbsRect.Top := -1;
                                        event.AbsRect.Height := 1;
                                        //event.Repeat_ := rRegular;
                                        AppendEvent(event);
                                      end;
                                      break;
                                    end;
                                  HarmonyRoot := -10;
                                end;
                              end;
                            end;
                          end;
                        end;
                        if not appoggiatura and visible then
                          inc(offset, duration);
                      end;

                    end;
                  end;
                end;
              end;
            end;
            if not diskantRead then
              MakeStopEvent(offset);
            if UsedEvents > 0 then
              diskantRead := true;
          end;
        end;
      end;
    end;

    Root.Free;

    SortEvents;

    for l := 0 to UsedEvents-1 do
      with GriffEvents[l] do
      begin
        if NoteType = ntBass then
        begin
          k := l+1;
          while (k < UsedEvents) and (GriffEvents[k].NoteType <> ntDiskant) do
            inc(k);
          if (k < UsedEvents) and (AbsRect.Right > GriffEvents[k].AbsRect.Left) then
            InPush := GriffEvents[k].InPush
          else
          if (l > 0) then
            InPush := GriffEvents[l-1].InPush
          else begin
          end;
        end;
        GriffToSound(Instrument);
      end;
    SortEvents;

    PartiturLoaded := UsedEvents > 0;
    result := PartiturLoaded;
  end;
end;


function SaveToMscx(GriffPartitur: TGriffPartitur; const FileName: string): boolean;
var
  SaveRec: TSaveRec;

  StaffNode, MeasureNode_, VoiceNode, ChordNode: KXmlNode;
  Volta1StartNode, Volta2StartNode: KXmlNode;

  function MakeVoltaSpanner: KXmlNode;
  begin
    result := NewXmlNode('Spanner');
    result.AppendAttr('type', 'Volta');
  end;

  procedure AddHeadColor(NoteNode: KXmlNode);
  var
    Child1: KXmlNode;
  begin
    if UseColors then
    begin
      Child1 := NoteNode.AppendChildNode('color');
      Child1.AppendAttr('r', '0');
      Child1.AppendAttr('g', '0');
      Child1.AppendAttr('b', '255');
      Child1.AppendAttr('a', '255');
    end;
  end;

  procedure Verzierung(iEvent: integer; NoteNode: KXmlNode; sDur: string);
  var
    Child, Child1: KXmlNode;
    CrossHead: boolean;
    GriffEvent: TGriffEvent;

    procedure AddMirror(Right: boolean);
    begin
      if Right then
        NoteNode.AppendChildNode('mirror', 'right')
      else
        NoteNode.AppendChildNode('mirror', 'left');
    end;

  begin
    GriffEvent := GriffPartitur.GriffEvents[iEvent];
    if UseGrandCross then
    begin
      if SaveRec.hasEvenGriff then
        AddMirror(odd(GetPitchLine(GriffEvent.GriffPitch)))
      else
      if SaveRec.hasSame then
      begin
        if SaveRec.nextSame then
        begin
          AddMirror(not GriffEvent.Cross);
          SaveRec.nextSame := false;
        end else
        if (iEvent < SaveRec.iEnd) and
           (GriffEvent.GriffPitch = GriffPartitur.GriffEvents[iEvent+1].GriffPitch) then
        begin
          SaveRec.nextSame := true;
          AddMirror(not GriffEvent.Cross);
        end;
      end;
    end;
    CrossHead := GriffEvent.Cross;
    if CrossHead and UseGrandCross then
    begin
      Child := NoteNode.AppendChildNode('Symbol');
      Child.AppendChildNode('name', 'noteheadXBlack');
      Child1 := Child.AppendChildNode('offset');
      Child1.AppendAttr('x', '-1.6');
      Child1.AppendAttr('y', '0');
      if not GriffEvent.InPush then
        AddHeadColor(Child);
    end;

    Child := NoteNode.AppendChildNode('Events');
    Child := Child.AppendChildNode('Event');
    if GriffEvent.GriffPitch <> GriffEvent.SoundPitch then
      Child.AppendChildNode('pitch',
        IntToStr(integer(GriffEvent.SoundPitch) - GriffEvent.GriffPitch));
    NoteNode.AppendChildNode('pitch', IntToStr(GriffEvent.GriffPitch));
    NoteNode.AppendChildNode('tpc', IntToStr(MuseScoreTPC[GriffEvent.GriffPitch mod 12]));
    if CrossHead and not UseGrandCross then
    begin
      if not GriffEvent.InPush then
        AddHeadColor(NoteNode);
      NoteNode.AppendChildNode('head', 'cross');
    end;
  end;

  procedure AddNextPrev(mes: integer; next: KXmlNode);
  var
    Child: KXmlNode;
    m, n: integer;
  begin
    n := 1;
    if mes < 0 then
    begin
      n := -1;
      mes := -mes;
    end;
    m := mes div GriffPartitur.GriffHeader.Details.TicksPerMeasure;
    if (mes mod GriffPartitur.GriffHeader.Details.TicksPerMeasure) > 0 then
      inc(m);
    m := n*m;

    Child := next.AppendChildNode('location');
    Child.AppendChildNode('measures', IntToStr(m));
  end;

  function AddVolta(s: string; visible: boolean): KXmlNode;
  var
    Child: KXmlNode;
  begin
    result := MakeVoltaSpanner;
    Child := result.AppendChildNode('Volta');
    if not visible then
    begin
      Child.AppendChildNode('visible', '0');
    end;
    Child.AppendChildNode('endHookType', '1');
    Child.AppendChildNode('beginText', s + '.');
    Child.AppendChildNode('endings', s);
  end;

  procedure AddVoltaPrev(delta: integer);
  var
    Child1, Child2: KXmlNode;
  begin
    Child1 := MakeVoltaSpanner;
    Child2 := Child1.AppendChildNode('prev');
    AddNextPrev(delta, Child2);
    VoiceNode.InsertChildNode(0, Child1);
  end;

  procedure AddNewMeasure;
  begin
    MeasureNode_ := StaffNode.AppendChildNode('', 'Measure ' + IntToStr(SaveRec.MeasureNr));
    MeasureNode_ := StaffNode.AppendChildNode('Measure');
    VoiceNode := MeasureNode_.AppendChildNode('voice');
    VoiceNode.AppendChildNode('BarLine');
  end;

  procedure NeuerTakt(Visible: boolean);
  var
    i: integer;
    Child1: KXmlNode;
  begin
    with SaveRec do
    begin
      if LastRepeat = rVolta1Start then
      begin
        Volta1Off := offset;
        Volta1StartNode := AddVolta('1', Visible);
        VoiceNode.InsertChildNode(0, Volta1StartNode);
        LastRepeat := rRegular;
        Volta2StartNode := nil;
      end;
      if (LastRepeat = rVolta2Start) and (Volta1Off >= 0) then
      begin
        Volta2Off := offset;
        Child1 := Volta1StartNode.AppendChildNode('next');
        AddNextPrev(Volta2Off - Volta1Off, Child1);

        AddVoltaPrev(-(Volta2Off - Volta1Off));

        Volta2StartNode := AddVolta('2', Visible);
        VoiceNode.InsertChildNode(1, Volta2StartNode);
        LastRepeat := rRegular;
      end;

      if TaktNr < offset div Takt then
      begin
        if (LastRepeat = rStart) then
        begin
          if not Visible then
          begin
            Child1 := nil;
            for i := 0 to Length(VoiceNode.ChildNodes)-1 do
            begin
              if VoiceNode.ChildNodes[i].Name = 'BarLine' then
              begin
                Child1 := VoiceNode.ChildNodes[i];
                break;
              end;
            end;
            if Child1 = nil then
              Child1 := VoiceNode.AppendChildNode('BarLine');
            Child1.AppendChildNode('subtype' , 'start-repeat');
            Child1.AppendChildNode('visible', '0');
          end else begin
            Child1 := NewXmlNode('startRepeat');
            MeasureNode_.InsertChildNode(0, Child1);
          end;
          LastRepeat := rRegular;
        end;

        if LastRepeat in [rVolta1Stop, rStop] then
        begin
          Child1 := NewXmlNode('endRepeat');
          Child1.Value := '2';
          MeasureNode_.InsertChildNode(0, Child1);
          LastRepeat := rRegular;
        end;

        t32takt := 0;
        inc(MeasureNr);
        AddNewMeasure;
        TaktNr := offset div Takt;

        if (LastRepeat = rVolta2Stop) and (Volta2Off >= 0) and
           (Volta2StartNode <> nil) then
        begin
          Child1 := Volta2StartNode.AppendChildNode('next');
          AddNextPrev(offset - Volta2Off, Child1);

          AddVoltaPrev(-(offset - Volta2Off));
          LastRepeat := rRegular;
        end;
      end;
    end;
  end;

  function AddTimeSig(Visible: boolean): KXmlNode;
  begin
    result := VoiceNode.AppendChildNode('TimeSig');
    if not Visible then
    begin
      result.AppendChildNode('visible', '0');
    end;
    result.AppendChildNode('sigN', IntToStr(GriffPartitur.GriffHeader.Details.measureFact));
    result.AppendChildNode('sigD', IntToStr(GriffPartitur.GriffHeader.Details.measureDiv));
  end;

  function AddRest(Len: integer; Lyrics, Visible: boolean; Bellows: boolean = false): boolean;
  var
    t, t1: integer;
    RestNode, Child, Child1: KXmlNode;
    iLen: integer;
    s: WideString;
  begin
    t := 8*Len div GriffPartitur.quarterNote;
    result := false;
    while t > 0 do
    begin
      result := true;
      t1 := t;
      if Lyrics then
      begin
        SaveRec.dot := false;
        if ((GriffPartitur.GriffHeader.Details.measureDiv = 8) or not SaveRec.Aufrunden) and
           (t >= 4) then
        begin
          SaveRec.sLen := 'eighth';
          dec(t, 4);
        end else
        if (t >= 8) then
        begin
          SaveRec.sLen := 'quarter';
          dec(t, 8);
        end else
          SaveRec.sLen := GetLen2(t, SaveRec.dot, SaveRec.t32takt);
        iLen := GetLyricLen(SaveRec.sLen);
        s := WideChar(iLen);
        Child := VoiceNode.AppendChildNode('StaffText');
        Child1 := Child.AppendChildNode('offset');
        Child1.AppendAttr('x', '0');
        if UseBellows then
          Child1.AppendAttr('y', Format('%g', [6.6 + BellowsWidth])) //'7.1');
        else
          Child1.AppendAttr('y', '5.9');
        Child := Child.AppendChildNode('text');
        Child1 := Child.AppendChildNode('font');
        Child1.AppendAttr('face', 'ScoreText');
        Child1 := Child.AppendChildNode('font', s);
        // örgeli 22 st 18
        if iLen >= 58612 then
          Child1.AppendAttr('size', '24')
        else
        if GriffPartitur.Instrument.BassDiatonic then
          Child1.AppendAttr('size', '18')
        else
          Child1.AppendAttr('size', '22');
        if SaveRec.dot then
        begin
          Child1 := Child.AppendChildNode('font', '.');
          Child1.AppendAttr('size', '18');
        end;
        Child1 := Child.AppendChildNode('font');
        Child1.AppendAttr('face', 'Edwin');
      end else begin
        SaveRec.sLen := SaveRec.GetLenS(t, GriffPartitur.quarterNote);
      end;
      RestNode := VoiceNode.AppendChildNode('Rest');
      if Lyrics or Bellows then
        RestNode.AppendChildNode('visible', '0');
      if SaveRec.dot then
        RestNode.AppendChildNode('dots', '1');
      RestNode.AppendChildNode('durationType', SaveRec.sLen);
      inc(SaveRec.t32takt, t1 - t);
      inc(SaveRec.offset, GriffPartitur.quarterNote*(t1 - t) div 8 );
      NeuerTakt(Visible);
    end;
  end;

  procedure AppendStaff(Lyrics: boolean; nt: TNoteType);


    procedure AddTie(NoteNode: KXmlNode; Next: boolean);
    var
      Child, Child1: KXmlNode;
      s: string;
    begin
      Child := NoteNode.AppendChildNode('Spanner');
      Child.AppendAttr('type', 'Tie');
      if Next then
        Child.AppendChildNode('Tie');

      s := 'prev';
      if Next then
        s := 'next';
      Child1 := Child.AppendChildNode(s);
      Child1 := Child1.AppendChildNode('location');
      s := SaveRec.tieFractions;
      if s <> '' then
      begin
        if not Next then
          s := '-' + s;
        Child1.AppendChildNode('fractions', s);
      end else begin
        if Next then
          s := '1'
        else
          s := '-1';
        Child1.AppendChildNode('measures', s);
      end;
    end;

    function GetFraction: string;
    var
      s: string;
      n, d: integer;
    begin
      result := '';
      s := SaveRec.slen;
      d := GetFraction_(s);
      if d = 0 then
        exit;

      n := 1;
      if SaveRec.dot then
      begin
        n := 3;
        d := 2*d;
      end;
      result := IntToStr(n) + '/' + IntToStr(d);
    end;

    procedure AddChord(WithBass: boolean);
    var
      Child1, Child2: KXmlNode;
    begin
      with SaveRec do
      begin
        ChordNode := VoiceNode.AppendChildNode('Chord');
        if Dot then
        begin
          ChordNode.AppendChildNode('dots', '1');
        end;
        ChordNode.AppendChildNode('durationType', sLen);
        if (sLen = 'eighth') and
           (nt = ntBass) and WithBass then
        begin
          Child1 := ChordNode.AppendChildNode('Articulation');
          Child2 := Child1.AppendChildNode('subtype');
          if GriffPartitur.GriffEvents[iEnd].SoundPitch >= 45 then
            Child2.Value := 'articStaccatoAbove'
          else
            Child2.Value := 'articStaccatoBelow';
        end;
  {      if Dot then
        begin
          Child1 := ChordNode.AppendChildNode('dots');
          Child1.Value := '1';
        end;
        Child := ChordNode.AppendChildNode('durationType');
        Child.Value := sLen;    }
      end;
    end;

  var
    i: integer;
    NoteNode, Child, Child1, Child2: KXmlNode;
  begin
    with GriffPartitur, SaveRec do
    begin
      Clear;
      Takt := GriffHeader.Details.TicksPerMeasure;

      if Lyrics then
        SaveRec.Aufrunden := AufViertelnotenAufrunden;

      AddNewMeasure;
      if nt = ntDiskant then
      begin
        AddTimeSig(true);

        Child := VoiceNode.AppendChildNode('Tempo');
        Child.AppendChildNode('tempo',
          Format('%f', [GriffHeader.Details.beatsPerMin / 60.0]));
        Child.AppendChildNode('followText', '1');
        Child1 := Child.AppendChildNode('text', ' = ' + IntToStr(GriffHeader.Details.beatsPerMin));
        Child2 := NewXmlNode('sym', 'metNoteQuarterUp');
        Child1.InsertChildNode(0, Child2);
      end else
        AddTimeSig(false);

      while iEvent < UsedEvents do
      begin
        NeuerTakt(nt = ntDiskant);
        if SaveRec.MostRight < GriffEvents[SaveRec.iEvent].AbsRect.Right then
          SaveRec.MostRight := GriffEvents[SaveRec.iEvent].AbsRect.Right;

        with GriffEvents[SaveRec.iEvent] do
        if NoteType > ntBass then
        begin
          if (GriffEvents[iEvent].Repeat_ <> rRegular){ and (nt = ntDiskant) }then
            LastRepeat := GriffEvents[iEvent].Repeat_;
          NeuerTakt(nt = ntDiskant);
          if NoteType = ntRest then
          begin
            Len := GriffHeader.Details.GetRaster(GriffEvents[SaveRec.iEvent].AbsRect.Right - offset);
            dot := false;
            AddRest(Len, Lyrics, nt = ntDiskant);
            LastRepeat := rRegular;
          end;
        end else begin
          // Pausen einfügen
          while (SaveRec.Rest(GriffHeader.Details.GetRaster(GriffEvents[SaveRec.iEvent].AbsRect.Left - offset),
                   (nt = ntBass) and (NoteType <> ntBass))) do
             if not AddRest(Len, Lyrics, nt = ntDiskant) then
               break;

          if (GriffEvents[iEvent].Repeat_ <> rRegular) {and (nt = ntDiskant)} then
            LastRepeat := GriffEvents[iEvent].Repeat_;

          if NoteType = nt then
          begin
            if (nt = ntDiskant) and SetTriolen(SaveRec) then
            begin
              t := offset;
              tupletNr := 1;
              Child1 := VoiceNode.AppendChildNode('Tuplet');
              Child1.AppendChildNode('normalNotes', '2');
              Child1.AppendChildNode('actualNotes', '3');
              Child1.AppendChildNode('baseNote', sLen);
              Child2 := Child1.AppendChildNode('Number');
              Child2.AppendChildNode('style', 'Tuplet');
              Child2.AppendChildNode('text', '3');
              for i := 1 to 3 do
              begin
                ChordNode := VoiceNode.AppendChildNode('Chord');
                ChordNode.AppendChildNode('durationType', sLen);
                iEnd := LastChordEvent(iEvent);
                while iEvent <= iEnd do
                begin
                  if GriffEvents[iEvent].NoteType = ntDiskant then
                  begin
                    NoteNode := ChordNode.AppendChildNode('Note');
                    Verzierung(iEvent, NoteNode, sDur);
                  end;
                  inc(iEvent);
                end;
              end;
              inc(offset, 8*quarterNote div triole);
              inc(t32takt, 64 div triole);
              VoiceNode.AppendChildNode('endTuplet');
              NeuerTakt(nt = ntDiskant);
              continue;
            end;

            SetIEnd(SaveRec);

            tie := tieOff;
            tieFractions := '';
            while SaveRec.SaveLen(GriffHeader.Details.GetRaster(GriffEvents[SaveRec.iEvent].AbsRect.Right - offset)) do
            begin
              if nt = ntBass then
              begin
                if Len < QuarterNote div 2 then
                  Len := QuarterNote div 2;
                if Lyrics and Aufrunden and (Len < QuarterNote) then
                begin
                  // auf Viertelnoten aufrunden
                  Len := QuarterNote;
                end;
              end;
              t1 := Len;
              SaveRec.LimitToTakt;
              if (t1 > Len) { and (nt = ntDiskant)} then
              begin
                case Tie of
                  tieOff: Tie := tieStart;
                  tieStart: Tie := tieMitte;
                end;
              end else
              if (tieFractions = '') and (Tie <> tieOff) then
                Tie := tieStop;

              t := 8*Len div quarterNote;
              while t > 0 do
              begin
                i := iEvent;
                if (nt = ntDiskant) and
                   GriffPartitur.IsAppoggiatura(SaveRec) then
                  appoggiatura := tieStart;
                sLen := USheetMusic.GetLen(t, dot, t32takt);

                if (t > 0) {and (nt = ntDiskant)} then
                begin
                  case Tie of
                    tieOff: Tie := tieStart;
                    tieStop: Tie := tieMitte;
                  end;
                end else
                if (Tie <> tieOff) and (t = 0) and (tieFractions <> '') then
                  Tie := tieStop;

                sDur := IntToStr(3*(t1-t));
                inc(t32takt, t1 - t);

                NeuerTakt(nt = ntDiskant);

                if Lyrics and (nt = ntBass) then
                begin
                  if iEvent = 60 then
                    t := t;
                  if not Lyrics or (Tie <= tieStart) then
                  begin
                    if not Instrument.BassDiatonic then
                    begin
                      Child := VoiceNode.AppendChildNode('StaffText');
                      if not GriffEvents[iEvent].Cross then
                      begin
                        Child.AppendChildNode('size', '14');  // 14 pt
                      end;
                      Child.AppendChildNode('text', IntToStr(GriffEvents[iEvent].GriffPitch));

                      if (iEvent < iEnd) and
                         (GriffEvents[iEnd].NoteType = ntBass) then
                      begin
                        Child := VoiceNode.AppendChildNode('StaffText');
                        Child.AppendChildNode('text', IntToStr(GriffEvents[iEnd].GriffPitch));
                      end;
                    end else begin
                      Child := VoiceNode.AppendChildNode('StaffText');
                      if not GriffEvents[iEvent].InPush then
                        AddHeadColor(Child);
                      Child.AppendChildNode('text', GriffEvents[iEvent].GetSteiBass);
                      if (iEvent < iEnd) and
                         (GriffEvents[iEnd].NoteType = ntBass) then
                      begin
                        Child := VoiceNode.AppendChildNode('StaffText');
                        if not GriffEvents[iEvent].InPush then
                          AddHeadColor(Child);
                        Child.AppendChildNode('text', GriffEvents[iEnd].GetSteiBass);
                      end;
                    end;
                  end;
                  // Die Pause wird beschriftet.
                  Child := VoiceNode.AppendChildNode('Rest');
                  Child.AppendChildNode('visible', '0');
                  if Dot then
                  begin
                    Child.AppendChildNode('dots', '1');
                  end;
                  Child.AppendChildNode('durationType', sLen);
                end else begin
                  AddChord(true);
                  while i <= iEnd do
                    with GriffEvents[i] do
                    begin
                      if GriffEvents[i].NoteType = nt then
                      begin
                        if appoggiatura <> tieOff then
                        begin
                          case appoggiatura of
                            tieStart:
                              begin
                                Child := ChordNode.AppendChildNode('Spanner');
                                Child.AppendAttr('type', 'Slur');
                                Child.AppendChildNode('Slur');
                                Child1 := Child.AppendChildNode('next');
                                Child1.AppendChildNode('location');
                                ChordNode.AppendChildNode('appoggiatura');
                                if (i < iEnd) and GriffEvents[i+1].IsAppoggiatura(GriffHeader) then
                                  appoggiatura := tieMitte
                                else
                                  appoggiatura := tieStop;
                              end;
                            tieMitte:
                              if (i >= iEnd) or
                                 not GriffEvents[i+1].IsAppoggiatura(GriffHeader) then
                                appoggiatura := tieStop;
                            tieStop:
                              begin
                                AddChord(false);
                                Child := ChordNode.AppendChildNode('Spanner');
                                Child.AppendAttr('type', 'Slur');

                                Child1 := Child.AppendChildNode('prev');
                                Child1 := Child1.AppendChildNode('location');
                                Child1.AppendChildNode('grace', '0');
                                appoggiatura := tieOff;
                              end;
                          end;
                        end;

                        NoteNode := ChordNode.AppendChildNode('Note');
                        if (nt = ntDiskant) and not GriffEvents[i].InPush then
                          AddHeadColor(NoteNode);

                        if Tie <> TieOff then
                        begin
                          if Tie in [tieStart, tieMitte] then
                          begin
                            if t > 0 then
                              tieFractions := GetFraction;
                            AddTie(NoteNode, true);   // next
                            tieFractions := '';
                          end;
                          if Tie in [tieMitte, tieStop] then
                          begin
                            AddTie(NoteNode, false);  // prev
                          end;
                        end;

                        if nt = ntDiskant then
                          Verzierung(i, NoteNode, sDur)
                        else
                        if not Lyrics then
                        begin
                          NoteNode.AppendChildNode('pitch',
                            IntToStr(GriffEvents[i].SoundPitch));
                        end;
                      end;
                    inc(i);
                  end;
                  if Tie = tieStart then
                    Tie := tieMitte;
                end;
                if t > 0 then
                  tieFractions := GetFraction;
              end;
              inc(offset, Len);
              if t32takt*quarterNote >= 8*Takt then
                NeuerTakt(nt = ntDiskant);
            end;
            iEvent := iEnd;
          end;
        end;
        inc(iEvent);
      end;

      SaveRec.MostRight := GriffPartitur.GriffHeader.Details.GetRaster(SaveRec.MostRight);
      SaveRec.Len := SaveRec.MostRight mod SaveRec.Takt;
      with SaveRec do
      begin
        if Len > 0 then
          Len := MostRight + Takt - Len - Offset;
        if Len > 0 then
          AddRest(Len, Lyrics, nt = ntDiskant);

        if (Length(VoiceNode.ChildNodes) >= 2) or
           (SaveRec.LastRepeat <> rRegular) then
          AddRest(Takt, Lyrics, nt = ntDiskant);
        StaffNode.RemoveChild(MeasureNode_);
      end;
    end;
  end;

  var
    PushStartNode: KXmlNode;
    PushStartOffset: integer;

  procedure ShowBellows(Push: boolean; Child: KXmlNode);
  var
    TextLine, Segment, Child1: KXmlNode;
    off, mes, fra, quot: integer;

    procedure AddSubtype(Sub: string; X, Y: string);
    begin
      Segment := TextLine.AppendChildNode('Segment');
      Segment.AppendChildNode('subtype', Sub);
      Child := Segment.AppendChildNode('offset');
      Child.AppendAttr('x', '0');
      Child.AppendAttr('y', Y);
      Child := Segment.AppendChildNode('off2');
      Child.AppendAttr('x', X);
      Child.AppendAttr('y', '0');
    end;

  begin
    if Push then
    begin
      PushStartNode := Child;
      PushStartOffset := SaveRec.offset;
      TextLine := PushStartNode.AppendChildNode('TextLine');
      TextLine.AppendChildNode('placement', 'below');
      TextLine.AppendChildNode('lineWidth', Format('%g', [BellowsWidth]));
    //  if Child <> VoiceNode then
    //    AddSubtype('0', '2', '3.5')
    //  else   begin
        AddSubtype('0', '0', '3.5');
    //    AddSubtype('3', '0', '3.5');
    //  end;
    end else begin
      with GriffPartitur do
      begin
        off := SaveRec.offset - PushStartOffset;
        mes := off div GriffHeader.Details.TicksPerMeasure;
        fra := GriffHeader.Details.GetRaster(off) mod GriffHeader.Details.TicksPerMeasure;
        fra := 8*fra div quarterNote;  // 32nd
      end;
      Child1 := PushStartNode.AppendChildNode('next');
      Child1 := Child1.AppendChildNode('location');
      if mes > 0 then
      begin
        Child1.AppendChildNode('measures', IntToStr(mes));
      end;
      quot := 0;
      if fra > 0 then
      begin
        quot := 32;
        while not odd(fra) do
        begin
          quot := quot div 2;
          fra := fra div 2;
        end;
        Child1.AppendChildNode('fractions', IntToStr(fra) + '/' + IntToStr(quot));
      end;

      Child1 := Child.AppendChildNode('prev');
      Child1 := Child1.AppendChildNode('location');
      if mes > 0 then
      begin
        Child1.AppendChildNode('measures', IntToStr(-mes));
      end;
      if fra > 0 then
      begin
        Child1.AppendChildNode('fractions', IntToStr(-fra) + '/' + IntToStr(quot));
      end;
    end;
  end;

  procedure AppendBellowsChange(Push: boolean; StaffNode: KXmlNode);
  var
    Child: KXmlNode;
  begin
 {   Child := nil;
    if (Length(StaffNode.ChildNodes) >= 3) then
      Child := StaffNode.ChildNodes[Length(StaffNode.ChildNodes)-3];
    if not Push and (SaveRec.t32takt = 0) and (Child <> nil) then
    begin
      Child := Child.LastNode;
    end else}
      Child := VoiceNode;
    Child := Child.AppendChildNode('Spanner');
    Child.AppendAttr('type', 'TextLine');

    ShowBellows(Push, Child);
  end;

  procedure AppendBellows(StaffNode: KXmlNode);
  var
    Pos: integer;
  begin
    with GriffPartitur do
    begin
      SaveRec.Clear;
      SaveRec.Takt := GriffHeader.Details.TicksPerMeasure;
      SaveRec.InPu := false;
      AddNewMeasure;
      while SaveRec.iEvent < UsedEvents do
      begin
        with GriffEvents[SaveRec.iEvent] do
        begin
          if AbsRect.Right > SaveRec.MostRight then
            SaveRec.MostRight := AbsRect.Right;

          if (NoteType = ntDiskant) or
             ((NoteType = ntBass) and (Instrument.BassDiatonic)) then
          begin
            Pos := GriffHeader.Details.GetRaster(AbsRect.Left);
            if SaveRec.Offset < Pos then
            begin
              SaveRec.Len := Pos - SaveRec.Offset;
              AddRest(SaveRec.Len, false, false, true);
            end;
            //NeuerTakt(false);
            if InPush <> SaveRec.InPu then
            begin
              SaveRec.InPu := InPush;
              AppendBellowsChange(SaveRec.InPu, StaffNode);
            end;
            Pos := GriffHeader.Details.GetRaster(AbsRect.Right);
            if SaveRec.Offset < Pos then
            begin
              SaveRec.Len := Pos - SaveRec.Offset;
              AddRest(SaveRec.Len, false, false, true);
            end;
            //NeuerTakt(false);
          end;
        end;
        inc(SaveRec.iEvent);
      end;

      with SaveRec do
      begin
        if SaveRec.InPu then
          AppendBellowsChange(false, StaffNode);

        SaveRec.MostRight := GriffHeader.Details.GetRaster(SaveRec.MostRight);
        SaveRec.Len := SaveRec.MostRight mod SaveRec.Takt;
        if Len > 0 then
          Len := MostRight + Takt - Len - Offset;
        if Len > 0 then
          AddRest(Len, false, false, true);

        if (Length(VoiceNode.ChildNodes) >= 2) or
           (SaveRec.LastRepeat <> rRegular) then
          AddRest(Takt, false, false, true);
        StaffNode.RemoveChild(MeasureNode_);
      end;
    end;

  end;

  function AddStaff(Nr: integer; Part: KXmlNode): KXmlNode;
  begin
    result := Part.AppendChildNode('Staff');
    result.AppendAttr('id', IntToStr(Nr));
  end;

  function AddPart(Nr: integer; BassClef, Invisual: boolean; Score:KXmlNode): KXmlNode;
  var
    Child, Child1, Child2: KXmlNode;
  begin
    result := Score.AppendChildNode('Part');
    Child := AddStaff(Nr, result);
    Child1 := Child.AppendChildNode('StaffType');
    Child1.AppendAttr('group', 'pitched');
    Child1.AppendChildNode('name', 'stdNormal');

    if Invisual then
    begin
      Child1.AppendChildNode('clef', '0');
      Child1.AppendChildNode('barlines', '0');
      Child1.AppendChildNode('timesig', '0');
      Child1.AppendChildNode('invisible', '1');

      Child.AppendChildNode('invisible', '1');
      Child.AppendChildNode('hideSystemBarLine', '1');
    end else
    if BassClef then
    begin
      Child.AppendChildNode('defaultClef', 'F');
    end else
      Child1.AppendChildNode('clef', '0');

    if BassClef then
    begin
      result.AppendChildNode('show', '0');
    end;
    result.AppendChildNode('trackName', 'Akkordeon');
    Child := result.AppendChildNode('Instrument');
    Child.AppendAttr('id', 'accordion');
    Child.AppendChildNode('trackName', 'Akkordeon');
    Child.AppendChildNode('instrumentId', 'keyboard.accordion');
    Child1 := Child.AppendChildNode('Articulation');
    Child1.AppendChildNode('velocity', '100');
    Child1.AppendChildNode('gateTime', '100');

    Child1 := Child.AppendChildNode('Channel');
    Child2 := Child1.AppendChildNode('progam');
    Child2.AppendAttr('value', '0');
    Child2 := Child1.AppendChildNode('controller');
    Child2.AppendAttr('ctrl', '10');
    Child2.AppendAttr('value', '63');
    Child1.AppendChildNode('synti', 'Fluid');

    Child1 := Child.AppendChildNode('Channel');
    Child1.AppendAttr('value', '0');
    Child2 := Child1.AppendChildNode('progam');
    Child2.AppendAttr('value', '0');
    Child2 := Child1.AppendChildNode('controller');
    Child2.AppendAttr('ctrl', '10');
    Child2.AppendAttr('value', '63');
    Child1.AppendChildNode('synti', 'Fluid');
  end;

var
  Root, Score, Part, Child, Child1, Child2: KXmlNode;
  Staff1, Staff3: KXmlNode;
  s, t: string;
  p: integer;
  WithBass: boolean;
begin
  WithBass := false;
  for p := 0 to GriffPartitur.UsedEvents-1 do
    if GriffPartitur.GriffEvents[p].NoteType = ntBass then
      WithBass := true;


  Root := NewXmlNode('museScore');
  Root.AppendAttr('version', '3.02');
  Root.AppendChildNode('programVersion', '3.6.2');
  Root.AppendChildNode('programRevision');

  Score := Root.AppendChildNode('Score');
  Child := Score.AppendChildNode('LayerTag');
  Child.AppendAttr('id', '0');
  Child.AppendAttr('tag', 'default');

  Score.AppendChildNode('currentLayer', '0');
  Score.AppendChildNode('Division', IntToStr(GriffPartitur.quarterNote));

  Child := Score.AppendChildNode('Style');
  if UseBellows then
  begin
    if WithBass then
      Child.AppendChildNode('minSystemDistance', '13')
    else
      Child.AppendChildNode('minSystemDistance', '9.5'); // Abstand zw. Notenlinien
  end else begin
    if WithBass then
      Child.AppendChildNode('minSystemDistance', '11.5')
    else
      Child.AppendChildNode('minSystemDistance', '9.5'); // Abstand zw. Notenlinien
  end;
  // Lyrics unten
  Child.AppendChildNode('staffPlacement', '1');
  Child1 := Child.AppendChildNode('staffPosBelow');
  Child1.AppendAttr('x', '0');
  if UseBellows then
    Child1.AppendAttr('y', Format('%g', [5.7 + BellowsWidth]))
  else
    Child1.AppendAttr('y', '5.4');
  //'6.1');      // 5.3
  Child.AppendChildNode('Spatium', '1.74978');

  Score.AppendChildNode('showInvisible', '0');
  Score.AppendChildNode('showUnprintable', '1');
  Score.AppendChildNode('showFrames', '1');
  Score.AppendChildNode('showMargins', '1');

  s := ExtractFilename(FileName);
  SetLength(s, Length(s) - Length(ExtractFileExt(s)));
  p := Pos('_', s);
  if p > 0 then
    SetLength(s, p-1);

  Child := Score.AppendChildNode('metaTag');
  Child.AppendAttr('name', 'workTitle');
  Child.Value := s;

  ///////////////////////////////////////////////////////////////// Score Part 1

  AddPart(1, false, false, Score);

  if WithBass then
  begin
    p := 2;
    Part := AddPart(p, true, false, Score);
    inc(p);
{$ifdef OldStyle}
    Part := AddPart(p, false, true, Score);
    inc(p);
{$endif}
  end;
  //////////////////////////////////////////////////////////////////////////////

  StaffNode := AddStaff(1, Score);
  Staff1 := StaffNode;
  Child1 := StaffNode.AppendChildNode('VBox');
  Child2 := Child1.AppendChildNode('Text');
  Child2.AppendChildNode('style', 'Title');
  t := s;
  p := system.Pos(' - ', s);
  if p > 1 then
    Delete(s, p, length(s));
  Child2.AppendChildNode('text', s);

  if p > 1 then
  begin
    s := t;
    Delete(s, 1, p + 2);
    Child2 := Child1.AppendChildNode('Text');
    Child2.AppendChildNode('style', 'Subtitle');
    Child2.AppendChildNode('text', s);
  end;
  Child2 := Child1.AppendChildNode('Text');
  Child2.AppendChildNode('style', 'Composer');
  Child2.AppendChildNode('text', String(GriffPartitur.Instrument.Name));

  // Measure
  AppendStaff(false, ntDiskant);

  //////////////////////////////////////////////////////////////////////////////

  if WithBass then
  begin
    p := 2;
    StaffNode := AddStaff(p, Score);
    // Measure
    AppendStaff(false, ntBass);
    inc(p);

    StaffNode := AddStaff(p, Score);
    Staff3 := StaffNode;
    StaffNode.SaveToXmlFile('staff3.xml');
    // Measure
    AppendStaff(true, ntBass);  // Lyrics

    // inserts staff 3 voices (lyrics) in staff 1
    Staff1.MergeStaff(Staff3);
    Score.RemoveChild(Staff3);
  end;

  if UseBellows then
  begin
    StaffNode := AddStaff(3, Score);
    Staff3 := StaffNode;
    AppendBellows(StaffNode);
    Staff1.MergeStaff(Staff3);
    Score.RemoveChild(Staff3);
  end;

{$ifdef dcc}
  result := Root.SaveToMsczFile(FileName);
{$else}
  result := Root.SaveToXmlFile(Filename);
{$endif}
end;

end.
