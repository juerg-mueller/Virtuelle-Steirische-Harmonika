unit Urtmidi;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$ifdef LINUX}
  dynlibs,
{$endif}
  SysUtils, Classes, RtMidi;

type

  TOnMidiInData = procedure (aDeviceIndex: LongInt; aStatus, aData1, aData2: byte; Timestamp: Int64) of object;
  TOnSysExData = procedure (aDeviceIndex: integer; const aStream: TMemoryStream) of object;

  TMidiOutput = class
  private
    MidiOut: RtMidiOutPtr;
  public
    DeviceNames: array of string;
    constructor Create(Name: PChar = 'MidiOut 1');
    destructor Destroy; override;
    procedure CloseAll;
    procedure GenerateList;
    procedure Open(Index: integer);
    procedure Close(Index: integer);
    procedure Send(Index: integer; command, d1, d2: byte);
    procedure Reset;
  end;


  TMidiInput = class
  private
    MidiIn: RtMidiInPtr;
  public
    DeviceNames: array of string;
    OnMidiData: TOnMidiInData;
    OnSysExData: TOnSysExData;
    constructor Create(Name: PChar = 'MidiIn 1');
    destructor Destroy; override;
    procedure CloseAll;
    procedure GenerateList;
    procedure Open(Index: integer);
    procedure Close(Index: integer);
  end;


var
  MidiOutput: TMidiOutput;
  MidiVirtual: TMidiOutput;
  MidiInput: TMidiInput;

  MicrosoftIndex: integer = -1;

implementation

constructor TMidiOutput.Create(Name: PChar);
begin
  if @rtmidi_out_create <> nil then
    MidiOut := rtmidi_out_create(RTMIDI_API_LINUX_ALSA, Name);
end;

destructor TMidiOutput.Destroy;
begin
  CloseAll;
  if MidiOut <> nil then
    rtmidi_out_free(MidiOut);

  inherited;
end;

procedure TMidiOutput.CloseAll;
begin
  Close(0);
end;

procedure TMidiOutput.Open(Index: integer);
begin
  if @rtmidi_open_port <> nil then
    rtmidi_open_port(MidiOut, Index, '');
end;

procedure TMidiOutput.Close(Index: integer);
begin
  if (Index >= 0) and (@rtmidi_close_port <> nil) then
    rtmidi_close_port(MidiOut);
end;

procedure TMidiOutput.GenerateList;
var
  i, Count: integer;
  c: array [0..255] of AnsiChar;
  len: integer;
begin
  if @rtmidi_get_port_count <> nil then
  begin
    Count := rtmidi_get_port_count(MidiOut);
    SetLength(DeviceNames, Count);
    for i := 0 to count-1 do
    begin
      len := 254;
      rtmidi_get_port_name(MidiOut, i, c, len);
      DeviceNames[i] := c;
    end;
  end;
end;

procedure TMidiOutput.Send(Index: integer; command, d1, d2: byte);
var
  b: array[0..3] of byte;
  l: integer;
begin
  b[0] := command;
  b[1] := d1;
  b[2] := d2;
  b[3] := 0;
  l := 3;
  if (command shr 4) = 12 then
    dec(l);
  if (Index >= 0) and (MidiOut <> nil) then
    rtmidi_out_send_message(MidiOut, @b, l);
end;

procedure TMidiOutput.Reset;
  var
    i: integer;
begin
  for i := 0 to 15 do
  begin
    Sleep(5);
    Send(MicrosoftIndex, $B0 + i, 120, 0);  // all sound off
  end;
  Sleep(5);
end;


////////////////////////////////////////////////////////////////////////////////

constructor TMidiInput.Create(Name: PChar);
begin
  MidiIn := nil;
  if @rtmidi_in_create <> nil then
    MidiIn := rtmidi_in_create(RTMIDI_API_LINUX_ALSA, Name, 10240);
end;

destructor TMidiInput.Destroy;
begin
  CloseAll;
  if MidiIn <> nil then
    rtmidi_in_free(MidiIn);
end;

procedure Callback(TimeStamp: double; const message: PByte; userData: pointer); cdecl;
begin
  if @MidiInput.OnMidiData <> nil then
    MidiInput.OnMidiData(0, message[0], message[1], message[2], 0);
end;

procedure TMidiInput.Open(Index: integer);
begin
  if @rtmidi_open_port <> nil then
  begin
    rtmidi_open_port(MidiIn, Index, '');
    if @rtmidi_in_set_callback <> nil then
      rtmidi_in_set_callback(MidiIn, @Callback, self);
  end;
end;

procedure TMidiInput.Close(Index: integer);
begin
  if MidiIn <> nil then
  begin
    if @rtmidi_in_cancel_callback <> nil then
      rtmidi_in_cancel_callback(MidiIn);
    rtmidi_close_port(MidiIn);
  end;
end;

procedure TMidiInput.CloseAll;
begin
  Close(0);
end;

procedure TMidiInput.GenerateList;
var
  i, Count: integer;
  c: array [0..255] of char;
  len:integer;
begin
  Count := 0;
  SetLength(DeviceNames, Count);
  if (@rtmidi_get_port_count <> nil) then
  begin
    Count := rtmidi_get_port_count(MidiIn);
    SetLength(DeviceNames, Count);
    for i := 0 to count-1 do
    begin
      len := 255;
      rtmidi_get_port_name(MidiIn, i, c, len);
      DeviceNames[i] := c;
    end;
  end;
end;


initialization


  MidiOutput := TMidiOutput.Create;
  MidiVirtual := TMidiOutput.Create;
  MidiInput := TMidiInput.Create;


finalization

  MidiInput.Free;
  MidiVirtual.Free;
  MidiOutput.Free;
end.

