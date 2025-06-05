unit UMidi;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, UMidiEvent,
{$ifndef mswindows}
  Urtmidi;
{$else}
  Midi;
{$endif}

type
  TChannels = set of 0..15;

  TMetronom = record
    On_: boolean;
    OnPip: boolean;
    nextPip: TTime;
    pipDelay: TTime;
    pipCount: integer;
    sec: boolean;
    pip: byte;
    MidiEvent: TMidiEvent;
    function DoPip(const Header: TDetailHeader): boolean;
    function IsFirst: boolean;
    procedure SetOn(OnOff: boolean);
  end;


var
  MidiInstrDiskant: byte = $15; // Akkordeon
  MidiBankDiskant: byte = 0;
  MidiInstrBass: byte = $15;
  MidiBankBass: byte = 0;
  pipFirst: byte =  37;   // 59
  pipSecond: byte = 69;       // 76
  pipChannel: byte = 9;

  VolumeDiscant: double = 1.0;
  VolumeBass: double = 1.0;
  VolumeMetronom: double = 0.8;
  VolumeOut: double = 0.8;
  NurTakt: boolean = false;
  OhneBlinker: boolean = true;


procedure ChangeBank(Index, Channel, Bank, Instr: byte);
procedure ResetMidiOut;
procedure OpenMidiMicrosoft;
procedure SendMidi(Status, Data1, Data2: byte);
procedure SendMidiEvent(MidiEvent: TMidiEvent);
procedure DoSoundPitch(Pitch: byte; On_: boolean);

implementation

procedure DoSoundPitch(Pitch: byte; On_: boolean);
begin
  if MicrosoftIndex >= 0 then
  begin
    if On_ then
      MidiOutput.Send(MicrosoftIndex, $90, Pitch, $4f)
    else
      MidiOutput.Send(MicrosoftIndex, $80, Pitch, 64)
  end;
end;

procedure ResetMidiOut;
begin
  if MicrosoftIndex >= 0 then
    MidiOutput.Reset;
end;


procedure ChangeBank(Index, Channel, Bank, Instr: byte);
begin
  MidiOutput.Send(Index, $b0 + Channel, 0, Bank);
  MidiOutput.Send(Index, $c0 + Channel, Instr, 0);
end;

procedure OpenMidiMicrosoft;
begin
  if MicrosoftIndex >= 0 then
  begin
    MidiOutput.Open(MicrosoftIndex);
    try
      ResetMidiOut;
      ChangeBank(MicrosoftIndex, 0, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 1, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 2, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 3, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 4, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 5, MidiBankBass, MidiInstrBass);
      ChangeBank(MicrosoftIndex, 6, MidiBankBass, MidiInstrBass);
      ChangeBank(MicrosoftIndex, 7, MidiBankBass, MidiInstrBass);
    finally
    end;
  end;
end;

procedure SendMidi(Status, Data1, Data2: byte);
begin
  if (MicrosoftIndex >= 0) then
    MidiOutput.Send(MicrosoftIndex, Status, Data1, Data2);
end;

procedure SendMidiEvent(MidiEvent: TMidiEvent);
begin
  SendMidi(MidiEvent.command, MidiEvent.d1, MidiEvent.d2);
end;

////////////////////////////////////////////////////////////////////////////////

function TMetronom.DoPip(const Header: TDetailHeader): boolean;
var
  BPM, mDiv: integer;
  Time: TDateTime;
  vol: double;
begin
  result := false;
  if not On_ then
    exit;

  Time := Now;
  BPM := Header.QuarterPerMin;

  if nextPip = 0 then begin
    nextPip := Time;
    pipDelay := Time + 1/(24.0*60.0)/BPM;
    pipCount := 0;
  end;

  mDiv := Header.measureDiv; // ist 4 oder 8
  if NurTakt then
    sec := false
  else
  if mDiv = 8 then
  begin
    BPM := 2*BPM;
    sec := ((Header.measureFact = 6) and (pipCount = 3)) or
           ((Header.measureFact = 9) and (pipCount in [3, 6]));
  end else
    sec := true;

  pip := 0;
  if pipCount = 0 then
    pip := pipFirst
  else
  if sec then
    pip := pipSecond;
  MidiEvent.d1 := pip;

  if Time >= nextPip then
  begin
    if pip > 0 then
    begin
      vol := 100*VolumeMetronom;
      if vol > 126 then
        vol := 126;
      MidiEvent.d2 := trunc(vol);
      MidiEvent.command := $90 + pipChannel;
      OnPip := true;
      result := true;
    end;
    pipDelay := nextPip + 1/(24.0*60.0)/Header.QuarterPerMin/4; // 16-tel Note
    nextPip := nextPip + 1/(24.0*60.0)/BPM;
  end else
  if (Time >= pipDelay) and (pipDelay > 0) then
  begin
    pipDelay := 0;
    if pip > 0 then
    begin
      MidiEvent.command := $80 + pipChannel;
      MidiEvent.d2 := 64;
      OnPip := false;
      result := true;
    end;
    inc(pipCount);
    if pipCount >= Header.measureFact then
      pipCount := 0;
  end;
end;

procedure TMetronom.SetOn(OnOff: boolean);
begin
  On_ := OnOff;
  nextPip := 0;
end;

function TMetronom.IsFirst: boolean;
begin
  result := pip = pipFirst;
end;

end.

