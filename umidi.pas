unit UMidi;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils,
{$ifndef mswindows}
  Urtmidi;
{$else}
  Midi;
{$endif}

type
  TChannels = set of 0..15;

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

end.

