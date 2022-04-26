//
// Vorlage ist: teVirtualMIDITest.dpr
//
// Diese Unit aus dem Projekt entfernen und das Projekt lässt sich ohne
// "VirtualMidi" generieren.
//
unit UVirtual;

interface

var
  LoopbackName: string = 'Midi loopback';
  MidiVersion, MidiDriver: string;

function DriverLoaded: boolean;
function InstallLoopback: boolean;

implementation


uses
  SysUtils,
  teVirtualMIDIdll,
  Midi;

var
  dummy: word;
  port2: LPVM_MIDI_PORT = nil;
  i: integer;
  s: string;

function DriverLoaded: boolean;
begin
  result := port2 <> nil;
end;

procedure teVMCallback( MidiPort: LPVM_MIDI_PORT; MidiDataBytes: PBYTE; DataLength: cardinal; dwCallbackInstance: Pointer ); stdcall;
var
  i: integer;
  b: byte;
begin
  if ( mididatabytes = nil ) or ( datalength = 0 ) then
    begin
{$if defined(CONSOLE)}
      writeln('empty command - driver was probably shut down!');
{$endif}
      exit;
    end;

{$if defined(CONSOLE)}
  for i := 0 to DataLength-1 do
  begin
    b := MidiDataBytes[i];
    write(' $', IntToHex(b));
  end;
  writeln;
{$endif}

  if (MidiDataBytes^ and $f0) = $80 then
    writeln;

  if not virtualMIDISendData( midiport, mididatabytes, datalength ) then
    begin
{$if defined(CONSOLE)}
      writeln('error sending data: '+virtualMIDIError(GetLastError()));
{$endif}
      exit;
    end;
end;

function InstallLoopback: boolean;
begin
  result := DriverLoaded;
  if not result and (MidiDriver <> '') then
  begin
    virtualMIDILogging( TE_VM_LOGGING_MISC or TE_VM_LOGGING_RX or TE_VM_LOGGING_TX );

    i := 1;
    repeat
      s := LoopbackName + ' ' +IntToStr(i);
      inc(i);
    until MidiInput.GetSysDeviceIndex(s) < 0;
{$if defined(CONSOLE)}
    writeln('Generate ', s);
{$endif}

    port2 := virtualMIDICreatePortEx2( PWideChar(s), teVMCallback, nil, 65535, TE_VM_FLAGS_PARSE_RX );
{$if defined(CONSOLE)}

    if port2=nil then
    begin
      writeln('could not create port2: '+virtualMIDIError(GetLastError()));
    end;
{$endif}
  end;
end;

initialization
  MidiVersion := virtualMIDIGetVersion( dummy, dummy, dummy, dummy );
  MidiDriver := virtualMIDIGetDriverVersion( dummy, dummy, dummy, dummy );
{$if defined(CONSOLE)}
  if MidiVersion = '' then
  begin
    writeln(virtualMIDIDllName, ' not installed!');
  end else begin
    writeln( 'using ', virtualMIDIDllName, '-Version: ', MidiVersion);
    writeln( 'using driver-version: ', MidiDriver);
  end;
  writeln;
{$endif}

finalization
  if port2 <> nil then
    virtualMIDIClosePort( port2 );
end.
