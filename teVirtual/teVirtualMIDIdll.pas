{* teVirtualMIDI user-space interface - v1.3.0.43
 *
 * Copyright 2009-2019, Tobias Erichsen
 * All rights reserved, unauthorized usage & distribution is prohibited.
 *
 * For technical or commercial requests contact: info <at> tobias-erichsen <dot> de
 *
 * teVirtualMIDI.sys is a kernel-mode device-driver which can be used to dynamically create & destroy
 * midiports on Windows (XP to Windows 7, 32bit & 64bit).  The "back-end" of teVirtualMIDI can be used
 * to create & destroy such ports and receive and transmit data from/to those created ports.
 *
 * File: teVirtualMIDIdll.pas
 *
 * This is the binding-unit to use the teVirtualMIDI driver from Delphi applications.
 * This unit compiles using Delphi 7, Delphi XE3 and Lazarus (32 & 64 bit)
 *}

unit teVirtualMIDIdll;

interface

uses windows, syncobjs, classes;

const
  // Bits in Mask to enable logging for specific areas
  // TE_VM_LOGGING_MISC - log internal stuff (port enable, disable...)
  TE_VM_LOGGING_MISC = 1;
  // TE_VM_LOGGING_RX - log data received from the driver
  TE_VM_LOGGING_RX = 2;
  // TE_VM_LOGGING_TX - log data sent to the driver
  TE_VM_LOGGING_TX = 4;

  // Create virtual MIDI-port with parsing of incoming data
  TE_VM_FLAGS_PARSE_RX = 1;
  // Create virtual MIDI-port with parsing of outgoing data
  TE_VM_FLAGS_PARSE_TX = 2;
  // TE_VM_FLAGS_INSTANTIATE_RX_ONLY - Only the "midi-out" part of the port is created
  TE_VM_FLAGS_INSTANTIATE_RX_ONLY = 4;
  // TE_VM_FLAGS_INSTANTIATE_TX_ONLY - Only the "midi-in" part of the port is created
  TE_VM_FLAGS_INSTANTIATE_TX_ONLY = 8;
  // TE_VM_FLAGS_INSTANTIATE_BOTH - a bidirectional port is created
  TE_VM_FLAGS_INSTANTIATE_BOTH = 12;


// Name of the DLL depending if the build-target is 32 or 64 bit
{$ifdef WIN64}
  virtualMIDIDllName = 'teVirtualMIDI64.dll';
{$else}
  virtualMIDIDllName = 'teVirtualMIDI32.dll';
{$endif}

type

  LPVM_MIDI_PORT = Pointer;

  VM_MIDI_DATA_CB = procedure ( MidiPort: LPVM_MIDI_PORT; MidiDataBytes: PBYTE; DataLength: DWORD; dwCallbackInstance: Pointer ); stdcall;
  TvirtualMIDICreatePort = function( PortName: PWCHAR; Callback: VM_MIDI_DATA_CB; dwCallbackInstance: Pointer ): LPVM_MIDI_PORT; stdcall;
  TvirtualMIDICreatePortEx = function( PortName: PWCHAR; Callback: VM_MIDI_DATA_CB; dwCallbackInstance: Pointer; maxSysexLength: DWORD ): LPVM_MIDI_PORT; stdcall;
  TvirtualMIDICreatePortEx2 = function( PortName: PWCHAR; Callback: VM_MIDI_DATA_CB; dwCallbackInstance: Pointer; maxSysexLength: DWORD; flags: DWORD ): LPVM_MIDI_PORT; stdcall;
  TvirtualMIDICreatePortEx3 = function( PortName: PWCHAR; Callback: VM_MIDI_DATA_CB; dwCallbackInstance: Pointer; maxSysexLength: DWORD; flags: DWORD; manufacturer: pguid; product: pguid ): LPVM_MIDI_PORT; stdcall;
  TvirtualMIDIClosePort = procedure( MidiPort: LPVM_MIDI_PORT ); stdcall;
  TvirtualMIDISendData = function( MidiPort:LPVM_MIDI_PORT; MidiDataBytes: PBYTE; Length:DWORD ): LongBool; stdcall;
  TvirtualMIDIGetData = function( MidiPort: LPVM_MIDI_PORT; MidiDataBytes: PBYTE; Length: PDWORD ): LongBool; stdcall;
  TvirtualMIDIGetProcesses = function( MidiPort: LPVM_MIDI_PORT; ProcessIds: PINT64; Length: PDWORD ): LongBool; stdcall;
  TvirtualMIDIGetVersion = function( majorVersion, minorVersion, revision, build: PWORD ): PWCHAR; stdcall;
  TvirtualMIDILogging = function( logMask: DWORD ): DWORD; stdcall;
  TvirtualMIDIShutdown = function( MidiPort: LPVM_MIDI_PORT ):longBool; stdcall;

  function virtualMIDICreatePortEx3( PortName: PWCHAR; Callback: VM_MIDI_DATA_CB; dwCallbackInstance: Pointer; maxSysexLength: DWORD; flags: DWORD; manufacturer: pguid; product: pguid ): LPVM_MIDI_PORT; stdcall;
  function virtualMIDICreatePortEx2( PortName: PWCHAR; Callback: VM_MIDI_DATA_CB; dwCallbackInstance: Pointer; maxSysexLength: DWORD; flags: DWORD ): LPVM_MIDI_PORT; stdcall;
  procedure virtualMIDIClosePort( MidiPort: LPVM_MIDI_PORT ); stdcall;
  function virtualMIDISendData( MidiPort: LPVM_MIDI_PORT; MidiDataBytes: PBYTE; Length:DWORD ): LongBool; stdcall;
  function virtualMIDIGetData( MidiPort: LPVM_MIDI_PORT; MidiDataBytes: PBYTE; var Length:DWORD ): LongBool; stdcall;
  function virtualMIDIGetProcesses( MidiPort: LPVM_MIDI_PORT; ProcessIds: PINT64; var Length: DWORD ): LongBool; stdcall;
  function virtualMIDIError( value: dword ): string;
  function virtualMIDIGetVersion( var majorVersion, minorVersion, revision, build: WORD ): widestring; stdcall;
  function virtualMIDIGetDriverVersion( var majorVersion, minorVersion, revision, build: WORD ): widestring; stdcall;
  function virtualMIDILogging( logMask: DWORD ): DWORD; stdcall;
  function virtualMIDIShutdown( MidiPort: LPVM_MIDI_PORT ):longBool; stdcall;
  function virtualMIDIPath(): string;

  // deprecated functions - only remaining for backward compatibility - do not use for new implementations!
  function virtualMIDICreatePort( PortName: PWCHAR; Callback: VM_MIDI_DATA_CB; dwCallbackInstance: Pointer ): LPVM_MIDI_PORT; stdcall;
  function virtualMIDICreatePortEx( PortName: PWCHAR; Callback: VM_MIDI_DATA_CB; dwCallbackInstance: Pointer; maxSysexLength: DWORD ): LPVM_MIDI_PORT; stdcall;



implementation

uses
  sysutils;



var m_logging: DWORD;
    hVM: HMODULE;
    m_virtualMIDICreatePort: TvirtualMIDICreatePort;
    m_virtualMIDICreatePortEx: TvirtualMIDICreatePortEx;
    m_virtualMIDICreatePortEx2: TvirtualMIDICreatePortEx2;
    m_virtualMIDICreatePortEx3: TvirtualMIDICreatePortEx3;
    m_virtualMIDIClosePort: TvirtualMIDIClosePort;
    m_virtualMIDISendData: TvirtualMIDISendData;
    m_virtualMIDIGetData: TvirtualMIDIGetData;
    m_virtualMIDIGetProcesses: TvirtualMIDIGetProcesses;
    m_virtualMIDIShutdown: TvirtualMIDIShutdown;
    m_virtualMIDILogging: TvirtualMIDILogging;

    // used for automatically releasing the DLL when no open ports exist
    // This is used in loopMIDI & rtpMIDI to automatically release the
    // DLL when the driver is deactivated.  This fact is conveyed to the
    // application via a single MIDI-data-callback with zero-length
    // and/or nil-pointer.  When this occurs, the application should
    // shut down the midi-port immediately via "virtualMIDIClosePort"
    portCritical: tcriticalsection;
    portCount: dword;

function IsGerman: boolean;
begin
  result:=(GetUserDefaultLangID() and $3ff)=7;
end;

// finalize - called automatically when the application shuts down
procedure FinalVM();
begin
  m_virtualMIDICreatePort := nil;
  m_virtualMIDICreatePortEx := nil;
  m_virtualMIDICreatePortEx2 := nil;
  m_virtualMIDICreatePortEx3 := nil;
  m_virtualMIDIClosePort := nil;
  m_virtualMIDISendData := nil;
  m_virtualMIDIGetData := nil;
  m_virtualMIDIGetProcesses := nil;
  m_virtualMIDIShutdown := nil;
  m_virtualMIDILogging := nil;
  if hVM<>0 then
    begin
      FreeLibrary(hVM);
      hVM := 0;
    end;
end;

// see if no more MIDI-ports are opened by the application - then shut down
// the reference ot the DLL.
procedure TryFinalVM( isLocked: boolean );
begin
  if not isLocked then
    begin
      PortCritical.Enter;
    end;
  if portCount=0 then
    FinalVM();
  if not isLocked then
    begin
      PortCritical.Leave;
    end;
end;

// initialize - called automatically when virtualMIDI-ports are opened
procedure InitVM( isLocked: boolean);
label leave;
begin
  if not isLocked then
    begin
      PortCritical.Enter;
    end;
  if hVM<>0 then
    begin
      goto leave;
    end;
  SetErrorMode(SEM_NOOPENFILEERRORBOX or SEM_FAILCRITICALERRORS);
  hVM := LoadLibrary(virtualMIDIDllName);
  if hVM = 0 then
    begin
{$if defined(CONSOLE)}
      writeln('Error ' + IntToStr(GetLastError));
{$endif}
      FinalVM();
      goto leave;
    end;
  m_virtualMIDICreatePort := TvirtualMIDICreatePort(GetProcAddress(hVM,'virtualMIDICreatePort'));
  m_virtualMIDICreatePortEx := TvirtualMIDICreatePortEx(GetProcAddress(hVM,'virtualMIDICreatePortEx'));
  m_virtualMIDICreatePortEx2 := TvirtualMIDICreatePortEx2(GetProcAddress(hVM,'virtualMIDICreatePortEx2'));
  m_virtualMIDICreatePortEx3 := TvirtualMIDICreatePortEx3(GetProcAddress(hVM,'virtualMIDICreatePortEx3'));
  m_virtualMIDIClosePort := TvirtualMIDIClosePort(GetProcAddress(hVM,'virtualMIDIClosePort'));
  m_virtualMIDISendData := TvirtualMIDISendData(GetProcAddress(hVM,'virtualMIDISendData'));
  m_virtualMIDIGetData := TvirtualMIDIGetData(GetProcAddress(hVM,'virtualMIDIGetData'));
  m_virtualMIDIGetProcesses := TvirtualMIDIGetProcesses(GetProcAddress(hVM,'virtualMIDIGetProcesses'));
  m_virtualMIDIShutdown := TvirtualMIDIShutdown(GetProcAddress(hVM,'virtualMIDIShutdown'));
  m_virtualMIDILogging := TvirtualMIDILogging(GetProcAddress(hVM,'virtualMIDILogging'));
  // support for virtualMIDICreatePort2 and virtualMIDIVersion is optional, since they did not exist in the
  // first couple of versions of the driver!
  if (not assigned(m_virtualMIDICreatePort)) or (not assigned(m_virtualMIDIClosePort)) or (not assigned(m_virtualMIDISendData)) or (not assigned(m_virtualMIDILogging)) then
    begin
      FinalVM();
      goto leave;
    end;
  if m_logging<>0 then
    begin
      virtualMIDILogging( m_logging );
    end;
leave:
  if not isLocked then
    begin
      PortCritical.Leave;
    end;
end;


// maps NT_STATUS_CODES coming from the driver/DLL to understandable reasons
function virtualMIDIError(value: dword): string;
begin
  case value of
    ERROR_OLD_WIN_VERSION:
      if isGerman then
        result:='Ihre Windows-Version ist zu alt für das Erzeugen dynamischer MIDI-ports.'
      else
        result:='Your Windows-version is too old for dynamic MIDI-port creation.';
    ERROR_INVALID_NAME:
      if isGerman then
        result:='Der MIDI-Port-Name muss mindestens ein Zeichen lang sein!'
      else
        result:='You need to specify at least 1 character as MIDI-portname!';
    ERROR_ALREADY_EXISTS,ERROR_ALIAS_EXISTS:
      if isGerman then
        result:='Der angegebene MIDI-Port-Name ist bereits vergeben!'
      else
        result:='The name for the MIDI-port you specified is already in use!';
    ERROR_PATH_NOT_FOUND:
      if isGerman then
        result:='Eventuell ist der teVirtualMIDI-Treiber nicht installiert!'
      else
        result:='Possibly the teVirtualMIDI-driver has not been installed!';
    ERROR_MOD_NOT_FOUND:
      if isGerman then
        result:='Die '+virtualMIDIDllName+' konnte nicht geladen werden!'
      else
        result:='The '+virtualMIDIDllName+' could not be loaded!';
    ERROR_INVALID_FUNCTION:
      if isGerman then
        result:='Eventuell ist der installierte teVirtualMIDI-Treiber veraltet!'
      else
        result:='Possibly the installed teVirtualMIDI-driver is out of date!';
    ERROR_REVISION_MISMATCH:
      if isGerman then
        result:='Version von '+virtualMIDIDllName+' und teVirtualMIDI.sys Treiber unterscheiden sich!'
      else
        result:=virtualMIDIDllName+' and teVirtualMIDI.sys driver differ in version!';
    ERROR_TOO_MANY_SESS:
      if isGerman then
        result:='Maximale Anzahl von Ports erreicht'
      else
        result:='Maximum number of ports reached';
    ERROR_BAD_ARGUMENTS:
      if isGerman then
        result:='Angegebene Flags nicht unterstützt'
      else
        result:='Invalid flags specified';
    else
      if isGerman then
        result:='teVirtualMIDI-Funktion ist fehlgeschlagen: '+inttostr(value)
      else
        result:='teVirtualMIDI-Operation failed with errorcode '+inttostr(value);
  end;
end;


// creates a virtual midi-port
function virtualMIDICreatePort( PortName: PWCHAR; Callback: VM_MIDI_DATA_CB; dwCallbackInstance: Pointer ): LPVM_MIDI_PORT; stdcall;
label leave;
var
      lasterror: dword;
begin
  lasterror := ERROR_SUCCESS;
  portcritical.Enter;
  InitVM( true );
  if not assigned(m_virtualMIDICreatePort) then
    begin
      lastError := ERROR_MOD_NOT_FOUND;
      result:=nil;
      goto leave;
    end;

  if (not assigned(m_virtualMIDIGetData)) and (not assigned(Callback)) then
    begin
      lastError := ERROR_INVALID_PARAMETER;
      result:=nil;
      goto leave;
    end;

  result:=m_virtualMIDICreatePort(PortName,Callback,dwCallbackInstance);
  if result<>nil then
    begin
      inc(portCount);
    end
  else
    begin
      lastError := GetLastError();
    end;
leave:
  TryFinalVM( true );
  portcritical.Leave;
  if (lasterror<>ERROR_SUCCESS) then
    SetLastError(lastError);
end;

// creates a virtual midi-port
// extended functionality:  MIDI-commands are pre-parsed.  In your callback you will always get a single, fully valid MIDI-command.
function virtualMIDICreatePortEx( PortName: PWCHAR; Callback: VM_MIDI_DATA_CB; dwCallbackInstance: Pointer; maxSysexLength: DWORD ): LPVM_MIDI_PORT; stdcall;
label leave;
var
      lasterror: dword;
begin
  lasterror := ERROR_SUCCESS;
  portcritical.Enter;
  InitVM( true );
  if not assigned(m_virtualMIDICreatePortEx) then
    begin
      lastError := ERROR_INVALID_FUNCTION;
      result:=nil;
      goto leave;
    end;

  result:=m_virtualMIDICreatePortEx( PortName, Callback, dwCallbackInstance, maxSysexLength );
  if result<>nil then
    begin
      inc(portCount);
    end
  else
    begin
      lastError := GetLastError();
    end;
leave:
  TryFinalVM( true );
  portcritical.Leave;
  if (lasterror<>ERROR_SUCCESS) then
    SetLastError(lastError);
end;

// creates a virtual midi-port
// extended functionality:  MIDI-commands are pre-parsed.  In your callback you will always get a single, fully valid MIDI-command.
function virtualMIDICreatePortEx2( PortName: PWCHAR; Callback: VM_MIDI_DATA_CB; dwCallbackInstance: Pointer; maxSysexLength: DWORD; flags: DWORD ): LPVM_MIDI_PORT; stdcall;
label leave;
var
      lasterror: dword;
begin
  lasterror := ERROR_SUCCESS;
  portcritical.Enter;
  InitVM( true );
  if not assigned(m_virtualMIDICreatePortEx2) then
    begin
      lasterror := ERROR_INVALID_FUNCTION;
      result:=nil;
      goto leave;
    end;
  result:=m_virtualMIDICreatePortEx2( PortName, Callback, dwCallbackInstance, maxSysexLength, flags );
  if result<>nil then
    begin
      inc(portCount);
    end
  else
    begin
      lastError := GetLastError();
    end;
leave:
  TryFinalVM( true );
  portcritical.Leave;
  if (lasterror<>ERROR_SUCCESS) then
    SetLastError(lastError);
end;


function virtualMIDICreatePortEx3( PortName: PWCHAR; Callback: VM_MIDI_DATA_CB; dwCallbackInstance: Pointer; maxSysexLength: DWORD; flags: DWORD; manufacturer: pguid; product: pguid ): LPVM_MIDI_PORT; stdcall;
label leave;
var
      lasterror: dword;
begin
  lasterror := ERROR_SUCCESS;
  portcritical.Enter;
  InitVM( true );
  if not assigned(m_virtualMIDICreatePortEx3) then
    begin
      lasterror := ERROR_INVALID_FUNCTION;
      result:=nil;
      goto leave;
    end;
  result:=m_virtualMIDICreatePortEx3( PortName, Callback, dwCallbackInstance, maxSysexLength, flags, manufacturer, product );
  if result<>nil then
    begin
      inc(portCount);
    end
  else
    begin
      lastError := GetLastError();
    end;
leave:
  TryFinalVM( true );
  portcritical.Leave;
  if (lasterror<>ERROR_SUCCESS) then
    SetLastError(lastError);
end;



// destroys a prior created midi-port
procedure virtualMIDIClosePort( MidiPort: LPVM_MIDI_PORT ); stdcall;
label leave;
begin
  portcritical.Enter;
  if not assigned(m_virtualMIDIClosePort) then
    begin
      goto leave;
    end;
  try
    m_virtualMIDIClosePort( MidiPort );
    if (portCount>0) then
      begin
        dec(portCount);
      end;
  except
    on e:exception do
      begin
        OutputDebugString(pchar('teVirtualMIDIdll - exception virtualMIDIClosePort: '+e.message));
      end;
  end;
leave:
  TryFinalVM( true );
  PortCritical.Leave;
end;

function virtualMIDIGetData( MidiPort:LPVM_MIDI_PORT; MidiDataBytes: PBYTE; var Length:DWORD ): LongBool; stdcall;
begin
  if not assigned(m_virtualMIDIGetData) then
    begin
      SetLastError( ERROR_INVALID_FUNCTION );
      result:=false;
      exit;
    end;
  result:=m_virtualMIDIGetData(MidiPort,MidiDataBytes,@Length);
end;

function virtualMIDIGetProcesses( MidiPort:LPVM_MIDI_PORT; ProcessIds: PINT64; var Length:DWORD ): LongBool; stdcall;
begin
  if not assigned(m_virtualMIDIGetProcesses) then
    begin
      SetLastError( ERROR_INVALID_FUNCTION );
      result:=false;
      exit;
    end;
  result:=m_virtualMIDIGetProcesses(MidiPort,ProcessIds,@Length);
end;

// sends MIDI-data on a prior created midi-port.
// Note:  Each invocation of this call should contain one complete, fully valid MIDI-message
function virtualMIDISendData( MidiPort:LPVM_MIDI_PORT; MidiDataBytes: PBYTE; Length:DWORD ): LongBool; stdcall;
begin
  if not assigned(m_virtualMIDISendData) then
    begin
      SetLastError(ERROR_MOD_NOT_FOUND);
      result:=false;
      exit;
    end;
  result:=m_virtualMIDISendData(MidiPort,MidiDataBytes,Length);
end;

// retrieves version of this DLL
function virtualMIDIGetVersion( var majorVersion, minorVersion, revision, build: WORD ): widestring; stdcall;
var m_virtualMIDIGetVersion: TvirtualMIDIGetVersion;
    hVM: HMODULE;
begin
  SetErrorMode(SEM_NOOPENFILEERRORBOX or SEM_FAILCRITICALERRORS);
  hVM := LoadLibrary(virtualMIDIDllName);
  if hVM = 0 then
    begin
      SetLastError(ERROR_MOD_NOT_FOUND);
      result:='';
      exit;
    end;
  m_virtualMIDIGetVersion := TvirtualMIDIGetVersion(GetProcAddress(hVM,'virtualMIDIGetVersion'));
  if not assigned(m_virtualMIDIGetVersion) then
    begin
      SetLastError(ERROR_MOD_NOT_FOUND);
      result:='';
      exit;
    end;
  result:=m_virtualMIDIGetVersion( @majorVersion, @minorVersion, @revision, @build );
  FreeLibrary(hVM);
end;

// retrieves version of this driver
function virtualMIDIGetDriverVersion( var majorVersion, minorVersion, revision, build: WORD ): widestring; stdcall;
var m_virtualMIDIGetVersion: TvirtualMIDIGetVersion;
    hVM: HMODULE;
begin
  SetErrorMode(SEM_NOOPENFILEERRORBOX or SEM_FAILCRITICALERRORS);
  hVM := LoadLibrary(virtualMIDIDllName);
  if hVM = 0 then
    begin
      SetLastError(ERROR_MOD_NOT_FOUND);
      result:='';
      exit;
    end;
  m_virtualMIDIGetVersion := TvirtualMIDIGetVersion(GetProcAddress(hVM,'virtualMIDIGetDriverVersion'));
  if not assigned(m_virtualMIDIGetVersion) then
    begin
      SetLastError(ERROR_MOD_NOT_FOUND);
      result:='';
      exit;
    end;
  result:=m_virtualMIDIGetVersion( @majorVersion, @minorVersion, @revision, @build );
  FreeLibrary(hVM);
end;

// controls logging of virtualMIDI-dll
function virtualMIDILogging( logMask: DWORD ): DWORD; stdcall;
begin
  result := m_logging;
  m_logging := logMask;
  if assigned(m_virtualMIDIGetData) then
   begin
     result:=m_virtualMIDILogging( logMask );
   end
end;


function virtualMIDIPath: string;
var hVM: HMODULE;
    fileName: array[0..512] of char;
begin
  result:='';
  SetErrorMode(SEM_NOOPENFILEERRORBOX or SEM_FAILCRITICALERRORS);
  hVM := LoadLibrary(virtualMIDIDllName);
  if hVM = 0 then
    begin
      SetLastError(ERROR_MOD_NOT_FOUND);
      exit;
    end;
  if GetModuleFileName(hVM,fileName,512)<>0 then
    begin
      result:=fileName;
    end;
  FreeLibrary(hVM);
end;

function virtualMIDIShutdown( MidiPort: LPVM_MIDI_PORT ): LongBool; stdcall;
begin
  if not assigned( m_virtualMIDIShutdown ) then
    begin
      SetLastError( ERROR_INVALID_FUNCTION );
      result := false;
      exit;
    end;
  result := m_virtualMIDIShutdown( MidiPort );
end;


initialization
  m_logging := 0;
  hVM := 0;
  portCount := 0;
  portCritical := tCriticalSection.Create();
finalization
  try
    FinalVM();
    FreeAndNil(portCritical);
  except
    on e:exception do
      begin
        OutputDebugString(pchar('teVirtualMIDIdll - exception finalize: '+e.message));
      end;
  end;
end.
