unit Urtmidi;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$ifdef LINUX}
  dynlibs,
{$endif}
  SysUtils, Classes;

type
  RtMidiWrapper = record
    ptr_: pointer;
    data: pointer;
    ok: boolean;
    msg: PChar;
  end;
  PRtMidiWrapper = ^RtMidiWrapper;

  RtMidiPtr = PRtMidiWrapper;
  RtMidiInPtr = PRtMidiWrapper;
  RtMidiOutPtr = PRtMidiWrapper;


  RtMidiApi =
    (
      RT_MIDI_API_UNSPECIFIED,    //*!< Search for a working compiled API. */
      RT_MIDI_API_MACOSX_CORE,    //*!< Macintosh OS-X Core Midi API. */
      RT_MIDI_API_LINUX_ALSA,     //*!< The Advanced Linux Sound Architecture API. */
      RT_MIDI_API_UNIX_JACK,      //*!< The Jack Low-Latency MIDI Server API. */
      RT_MIDI_API_WINDOWS_MM,     //*!< The Microsoft Multimedia MIDI API. */
      RT_MIDI_API_WINDOWS_KS,     //*!< The Microsoft Kernel Streaming MIDI API. */
      RT_MIDI_API_RTMIDI_DUMMY    //*!< A compilable but non-functional API. */
    );

  RtMidiErrorType =
    (
      RT_ERROR_WARNING, RT_ERROR_DEBUG_WARNING, RT_ERROR_UNSPECIFIED, RT_ERROR_NO_DEVICES_FOUND,
      RT_ERROR_INVALID_DEVICE, RT_ERROR_MEMORY_ERROR, RT_ERROR_INVALID_PARAMETER, RT_ERROR_INVALID_USE,
      RT_ERROR_DRIVER_ERROR, RT_ERROR_SYSTEM_ERROR, RT_ERROR_THREAD_ERROR
    );

  RtMidiCCallback = procedure(TimeStamp: double; const message: PChar; userData: pointer); cdecl; // __declspec(dllexport);

  //! Returns the size (with sizeof) of a RtMidiApi instance.
  rtmidi_sizeof_rtmidi_api = function: integer; cdecl;


{*! Determine the available compiled MIDI APIs.
 * If the given `apis` parameter is null, returns the number of available APIs.
 * Otherwise, fill the given apis array with the RtMidi::Api values.
 *
 * \param apis  An array or a null value.
*}
  rtmidi_get_compiled_api = function({enum RtMidiApi **} apis: pointer): integer; cdecl; // return length for NULL argument.

//! Report an error.
  rtmidi_error = procedure(type_: RtMidiErrorType; const errorString: PChar); cdecl;
{/*! Open a MIDI port.
 *
 * \param port      Must be greater than 0
 * \param portName  Name for the application port.
 *}
  rtmidi_open_port = procedure(device: RtMidiPtr; portNumber: integer; portName: PChar);
 {
/*! Creates a virtual MIDI port to which other software applications can
 * connect.
 *
 * \param portName  Name for the application port.
 *}
  rtmidi_open_virtual_port = procedure(device: RtMidiPtr; const portName: PChar); cdecl;

  rtmidi_close_port = procedure (device: RtMidiPtr); cdecl;

//*! Return the number of available MIDI ports.
  rtmidi_get_port_count = function (device: RtMidiPtr): integer; cdecl;

//! Return a string identifier for the specified MIDI input port number.
  rtmidi_get_port_name = function (device: RtMidiPtr; portNumber: integer): PChar; cdecl;

{
//! Create a default RtMidiInPtr value, with no initialization.
RTMIDIAPI RtMidiInPtr rtmidi_in_create_default ();

/*! Create a  RtMidiInPtr value, with given api, clientName and queueSizeLimit.
 *
 *  \param api            An optional API id can be specified.
 *  \param clientName     An optional client name can be specified. This
 *                        will be used to group the ports that are created
 *                        by the application.
 *  \param queueSizeLimit An optional size of the MIDI input queue can be
 *                        specified.
 *}
  rtmidi_in_create = function(api: RtMidiApi; const clientName: PChar; queueSizeLimit: integer): RtMidiInPtr; cdecl;

  rtmidi_in_free = procedure (device: RtMidiInPtr); cdecl;

//! Returns the MIDI API specifier for the given instance of RtMidiIn.
  rtmidi_in_get_current_api = function(device: RtMidiPtr): RtMidiApi; cdecL;

//! Set a callback function to be invoked for incoming MIDI messages.
  rtmidi_in_set_callback = procedure(device: RtMidiInPtr; callback: RtMidiCCallback; userData: pointer); cdecl;

//! Cancel use of the current callback function (if one exists).
  rtmidi_in_cancel_callback = procedure (device: RtMidiInPtr); cdecl;

{//! Specify whether certain MIDI message types should be queued or ignored during input.
RTMIDIAPI void rtmidi_in_ignore_types (RtMidiInPtr device, bool midiSysex, bool midiTime, bool midiSense);

/*! Fill the user-provided array with the data bytes for the next available
 * MIDI message in the input queue and return the event delta-time in seconds.
 *
 * \param message   Must point to a char* that is already allocated.
 *                  SYSEX messages maximum size being 1024, a statically
 *                  allocated array could
 *                  be sufficient.
 * \param size      Is used to return the size of the message obtained.
 */
RTMIDIAPI double rtmidi_in_get_message (RtMidiInPtr device, unsigned char **message, size_t * size);

/* RtMidiOut API */

//! Create a default RtMidiInPtr value, with no initialization.
RTMIDIAPI RtMidiOutPtr rtmidi_out_create_default ();

/*! Create a RtMidiOutPtr value, with given and clientName.
 *
 *  \param api            An optional API id can be specified.
 *  \param clientName     An optional client name can be specified. This
 *                        will be used to group the ports that are created
 *                        by the application.
 */}
  rtmidi_out_create = function(api: RtMidiApi; const clientName: PChar): RtMidiOutPtr; cdecl;

//! Deallocate the given pointer.
  rtmidi_out_free = procedure(device: RtMidiOutPtr); cdecl;

//! Returns the MIDI API specifier for the given instance of RtMidiOut.
//RTMIDIAPI enum RtMidiApi rtmidi_out_get_current_api (RtMidiPtr device);

//! Immediately send a single message out an open MIDI output port.
 rtmidi_out_send_message = function(device: RtMidiOutPtr; const message: PChar; length: integer): RtMidiOutPtr; cdecl;

 // event if data is received
 TOnMidiInData = procedure (aDeviceIndex: integer; aStatus, aData1, aData2: byte; Timestamp: integer) of object;
 // event of system exclusive data is received
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
 //  fSysExData: TObjectList;
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
  MicrosoftIndex: integer = 0;
  TrueMicrosoftIndex: integer = -1;
  MidiInstrDiskant: byte = $15; // Akkordeon
  MidiInstrBass: byte = $15; // Akkordeon
  MidiBankDiskant: byte = 0;
  MidiBankBass: byte = 0;

  MidiOutput: TMidiOutput;
  MidiVirtual: TMidiOutput;
  MidiInput: TMidiInput;

procedure OpenMidiMicrosoft;

implementation
uses
  UFormHelper;

var
  hndLib: TLibHandle = 0;
  prtmidi_in_create: rtmidi_in_create = nil;
  prtmidi_in_free: rtmidi_in_free = nil;
  prtmidi_in_set_callback: rtmidi_in_set_callback = nil;
  prtmidi_in_cancel_callback: rtmidi_in_cancel_callback = nil;

  prtmidi_out_create: rtmidi_out_create = nil;
  prtmidi_out_free: rtmidi_out_free = nil;
  prtmidi_out_send_message: rtmidi_out_send_message = nil;

  prtmidi_open_port: rtmidi_open_port = nil;
  prtmidi_close_port: rtmidi_close_port = nil;
  prtmidi_open_virtual_port: rtmidi_open_virtual_port = nil;
  prtmidi_get_port_count: rtmidi_get_port_count = nil;
  prtmidi_get_port_name: rtmidi_get_port_name = nil;

constructor TMidiOutput.Create(Name: PChar);
begin
  MidiOut := prtmidi_out_create(RT_MIDI_API_LINUX_ALSA, Name);
end;

destructor TMidiOutput.Destroy;
begin
  CloseAll;
  prtmidi_out_free(MidiOut);

  inherited;
end;

procedure TMidiOutput.CloseAll;
begin
  Close(0);
end;

procedure TMidiOutput.Open(Index: integer);
begin
  prtmidi_open_port(MidiOut, Index, '');
end;

procedure TMidiOutput.Close(Index: integer);
begin
  prtmidi_close_port(MidiOut);
end;

procedure TMidiOutput.GenerateList;
var
  i, Count: integer;
  c: PChar;
begin
  Count := prtmidi_get_port_count(MidiOut);
  SetLength(DeviceNames, Count);
  for i := 0 to count-1 do
  begin
    c := prtmidi_get_port_name(MidiOut, i);
    DeviceNames[i] := c;
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
  if MidiOut <> nil then
    prtmidi_out_send_message(MidiOut, @b, l);
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
//      ResetMidi;
      ChangeBank(MicrosoftIndex, 0, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 1, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 2, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 3, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 4, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 5, MidiBankBass, MidiInstrBass);
      ChangeBank(MicrosoftIndex, 6, MidiBankBass, MidiInstrBass);
    finally
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TMidiInput.Create(Name: PChar);
begin
  MidiIn := prtmidi_in_create(RT_MIDI_API_LINUX_ALSA, Name, 10240);
end;

destructor TMidiInput.Destroy;
begin
  CloseAll;
  prtmidi_in_free(MidiIn);
end;

procedure Callback(TimeStamp: double; const message: PChar; userData: pointer); cdecl;
begin
  with TMidiInput(userData)  do
  begin
    if @OnMidiData <> nil then
    begin
      OnMidiData(0, Byte(message[0]), Byte(message[1]), Byte(message[2]), 0);
    end;
  end;
end;

procedure TMidiInput.Open(Index: integer);
begin
  prtmidi_open_port(MidiIn, Index, '');
  prtmidi_in_set_callback(MidiIn, @Callback, self);
end;

procedure TMidiInput.Close(Index: integer);
begin
  prtmidi_in_cancel_callback(MidiIn);
  prtmidi_close_port(MidiIn);
end;

procedure TMidiInput.CloseAll;
begin
  Close(0);
end;

procedure TMidiInput.GenerateList;
var
  i, Count: integer;
  c: PChar;
begin
  Count := prtmidi_get_port_count(MidiIn);
  SetLength(DeviceNames, Count);
  for i := 0 to count-1 do
  begin
    c := prtmidi_get_port_name(MidiIn, i);
    DeviceNames[i] := c;
  end;

end;


initialization

{$ifdef LINUX}
  hndLib := LoadLibrary(PChar('librtmidi.so'));
{$else}
  hndLib := LoadLibrary('rtmidi.dll');
{$endif}
  if hndLib <> NilHandle then
  begin
    prtmidi_open_port :=  GetProcedureAddress(hndLib, 'rtmidi_open_port');
    prtmidi_close_port :=  GetProcedureAddress(hndLib, 'rtmidi_close_port');
    prtmidi_open_virtual_port :=  GetProcedureAddress(hndLib, 'rtmidi_open_virtual_port');
    prtmidi_get_port_count :=  GetProcedureAddress(hndLib, 'rtmidi_get_port_count');
    prtmidi_get_port_name :=  GetProcedureAddress(hndLib, 'rtmidi_get_port_name');

    prtmidi_in_create :=  GetProcedureAddress(hndLib, 'rtmidi_in_create');
    prtmidi_in_free :=  GetProcedureAddress(hndLib, 'rtmidi_in_free');
    prtmidi_in_set_callback :=  GetProcedureAddress(hndLib, 'rtmidi_in_set_callback');
    prtmidi_in_cancel_callback :=  GetProcedureAddress(hndLib, 'rtmidi_in_cancel_callback');

    prtmidi_out_create :=  GetProcedureAddress(hndLib, 'rtmidi_out_create');
    prtmidi_out_free :=  GetProcedureAddress(hndLib, 'rtmidi_out_free');
    prtmidi_out_send_message :=  GetProcedureAddress(hndLib, 'rtmidi_out_send_message');

    MidiOutput := TMidiOutput.Create;
    MidiVirtual := TMidiOutput.Create;
    MidiInput := TMidiInput.Create;
  end else begin
    ErrMessage('rtmidi library not found');
    halt;
  end;

finalization

  FreeLibrary(hndLib);
  MidiInput.Free;
  MidiVirtual.Free;
  MidiOutput.Free;
end.

