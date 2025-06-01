//****************************************************************************/
//* MIDI device classes by Adrian Meyer
//****************************************************************************/
//* V1.1 Delphi 6 Windows 2000
//****************************************************************************/
//* V1.0 First release with simple MIDI Input/Output
//* V1.1 SysEx Input Event added, refactured error handling
//* V1.2 SysEx Output procedure added, changes sysex input for multiple ports
//****************************************************************************/
//* Homepage: http://www.midimountain.com
//****************************************************************************/
//* If you get a hold of this source you may use it upon your own risk. Please
//* let me know if you have any questions: adrian.meyer@rocketmail.com.
//****************************************************************************/

// August 2020
// juerg5524: Delphi 10.3 und Windows 8
// Der Refresh der MidiDevices funtioniert nicht richtig, deshalb habe ich mich 
// entschlossen, ein einzelnes Device über den Namen und nicht über den Index
// zu öffnen oder zu schliessen.
unit Midi;

interface

uses
  classes, SysUtils, mmsystem, Math, Windows, Contnrs;

const
  // size of system exclusive buffer
  cSysExBufferSize = 2048;

type
  
  // event if data is received
  TOnMidiInData = procedure (aDeviceIndex: integer; aStatus, aData1, aData2: byte; Timestamp: Int64) of object;
  // event of system exclusive data is received
  TOnSysExData = procedure (aDeviceIndex: integer; const aStream: TMemoryStream) of object;

  EMidiDevices = Exception;

  TSysDeviceIndex = integer; // Midi System Index
  TDeviceIndex = integer;    // Index zu DeviceNames

  // base class for MIDI devices
  TMidiDevices = class
  private
    fMidiResult: MMResult;
    procedure SetMidiResult(const Value: MMResult);
  protected
    property MidiResult: MMResult read fMidiResult write SetMidiResult;
  public
    DeviceNames: array of string;
    Handles: array of THandle;
    constructor Create; virtual;
    destructor Destroy; override;
    function GetHandle(const aDeviceIndex: TDeviceIndex): THandle;
    procedure Open(const aDeviceIndex: TDeviceIndex); virtual; abstract;
    procedure Close(const aDeviceIndex: TDeviceIndex); virtual; abstract;
    function IsOpen(const aDeviceIndex: integer) : boolean; virtual;
   // close all devices
    procedure CloseAll;
  end;

  // MIDI input devices
  TMidiInput = class(TMidiDevices)
  private
    fOnMidiData: TOnMidiInData;
    fOnSysExData: TOnSysExData;
    fSysExData: TObjectList;
  protected
    procedure DoSysExData(const aDeviceIndex: integer);
  public
    constructor Create; override;
    destructor Destroy; override;
    // open a specific input device
    procedure Open(const aDeviceIndex: TDeviceIndex); override;
    // close a specific device
    procedure Close(const aDeviceIndex: TDeviceIndex); override; 
    class procedure Free_Instance; 
    procedure GenerateList;
    function GetSysDeviceIndex(name: string): TSysDeviceIndex;
    // midi data event
    property OnMidiData: TOnMidiInData read fOnMidiData write fOnMidiData;
    // midi system exclusive is received
    property OnSysExData: TOnSysExData read fOnSysExData write fOnSysExData;
  end;

  // MIDI output devices
  TMidiOutput = class(TMidiDevices)
  protected
  public
    constructor Create; override;
    // open a specific input device
    procedure Open(const aDeviceIndex: TDeviceIndex); override;
    // close a specific device
    procedure Close(const aDeviceIndex: TDeviceIndex); override;
    // send some midi data to the indexed device
    procedure Send(const aDeviceIndex: TDeviceIndex; const aStatus, aData1, aData2: byte);
    procedure Reset;
    class procedure Free_Instance;
    procedure GenerateList;
    function GetSysDeviceIndex(name: string): TSysDeviceIndex; 
  end;

  TChannels = set of 0..15;

  // MIDI input devices
  function MidiInput: TMidiInput;
  // MIDI output Devices
  function MidiOutput: TMidiOutput;


const
  MicrosoftSync = 'Microsoft GS Wavetable Synth';

var
  MicrosoftIndex: integer = -1;
  TrueMicrosoftIndex: integer = -1;

implementation

{ TMidiBase }
type
  TSysExBuffer = array[0..cSysExBufferSize] of AnsiChar;

  TSysExData = class
  private
    fSysExStream: TMemoryStream;
  public
    SysExHeader: TMidiHdr;
    SysExData: TSysExBuffer;
    constructor Create;
    destructor Destroy; override;
    property SysExStream: TMemoryStream read fSysExStream;
  end;

// Win XP uses 'Creative Sound Blaster', but it does not work in a VM.
function IsCreativeSoundBlaster(p: PChar): boolean;
var
  s: string;
begin
  s := p;
  SetLength(s, 14);
  result := s = 'Creative Sound';
end;

constructor TMidiDevices.Create;
begin
  inherited;
  SetLength(DeviceNames, 0);
end;

destructor TMidiDevices.Destroy;
begin
  SetLength(DeviceNames, 0);
  inherited;
end;

procedure TMidiDevices.SetMidiResult(const Value: MMResult);
var
  lError: array[0..MAXERRORLENGTH] of char;
begin
  fMidiResult := Value;
  if fMidiResult <> MMSYSERR_NOERROR then
    if midiInGetErrorText(fMidiResult, @lError, MAXERRORLENGTH) = MMSYSERR_NOERROR then
      raise EMidiDevices.Create(StrPas(lError));
end;

function TMidiDevices.GetHandle(const aDeviceIndex: TDeviceIndex): THandle;
begin
  if (aDeviceIndex < 0) or (aDeviceIndex >= Length(DeviceNames)) then
    raise EMidiDevices.CreateFmt('%s: Device index out of bounds! (%d)', [ClassName,aDeviceIndex]);

  Result := Handles[aDeviceIndex];
end;


////////////////////////////////////////////////////////////////////////////////

// Singletons
var
  gMidiInput: TMidiInput;
  gMidiOutput: TMidiOutput;

function MidiInput: TMidiInput;
begin
  if not assigned(gMidiInput) then
    gMidiInput := TMidiInput.Create;
  Result := gMidiInput;
end;

function MidiOutput: TMidiOutput;
begin
  if not assigned(gMidiOutput) then
    gMidiOutput := TMidiOutput.Create;
  Result := gMidiOutput;
end;

class procedure TMidiInput.Free_Instance;
begin
  if assigned(gMidiInput) then
    FreeAndNil(gMidiInput);
end;

class procedure TMidiOutput.Free_Instance;
begin
  if assigned(gMidiOutput) then
    FreeAndNil(gMidiOutput);
end;

procedure midiInCallback(aMidiInHandle: PHMIDIIN; aMsg: UInt; aData, aMidiData, aTimeStamp: integer); stdcall;
begin
  case aMsg of
    MIM_DATA:
      begin
        if assigned(MidiInput.OnMidiData) then
           MidiInput.OnMidiData(aData, aMidiData and $000000FF,
           (aMidiData and $0000FF00) shr 8, (aMidiData and $00FF0000) shr 16, aTimeStamp);
      end;

    MIM_LONGDATA:
      MidiInput.DoSysExData(aData);
  end;
end;

procedure TMidiInput.Close(const aDeviceIndex: TDeviceIndex);
var
  Handle: THandle;
begin
  Handle := GetHandle(aDeviceIndex); 
  if IsOpen(aDeviceIndex) then
  begin
    MidiResult := midiInStop(Handle);
    MidiResult := midiInReset(Handle);
    MidiResult := midiInUnprepareHeader(Handle, @TSysExData(fSysExData[aDeviceIndex]).SysExHeader, SizeOf(TMidiHdr));
    MidiResult := midiInClose(Handle);
    Handles[aDeviceIndex] := 0;
  end;
end;
                         
procedure TMidiDevices.CloseAll;
var
  i: integer;
begin
  for i:= 0 to Length(DeviceNames) - 1 do
    Close(i);
end;

function TMidiDevices.IsOpen(const aDeviceIndex: integer) : boolean;
begin
  result := (aDeviceIndex >= 0) and (GetHandle(aDeviceIndex) <> 0);
end;

procedure TMidiInput.GenerateList;
var
  lInCaps: TMidiInCaps;
  lHandle: THandle;
  i, l: integer;
begin
  CloseAll;
  SetLength(DeviceNames, 0);
  SetLength(Handles, 0);
  fSysExData.Clear;

 // midiInGetNumDevs does not update!!!
  for i := 0 to integer(midiInGetNumDevs) - 1 do
  begin
    MidiResult := midiInGetDevCaps(i, @lInCaps, SizeOf(TMidiInCaps));
    if MidiResult = 0 then
    begin
      if //not IsCreativeSoundBlaster(lInCaps.szPname) and
         (midiInOpen(@lHandle, i, 0, 0, CALLBACK_NULL) = 0) then
      begin
    {$if defined(CONSOLE)}
        writeln('midi input ', length(DeviceNames), ': ', lInCaps.szPname);
    {$endif}
        l := length(DeviceNames);
        SetLength(DeviceNames, l+1);
        SetLength(Handles, l+1);
        DeviceNames[l] := lInCaps.szPname;
        fSysExData.Add(TSysExData.Create);
        midiInClose(lHandle);
      end;
    end;
  end;
end;

constructor TMidiInput.Create;
begin
  inherited;

  fSysExData := TObjectList.Create(true);
end;

function TMidiInput.GetSysDeviceIndex(name: string): TSysDeviceIndex;
var
  lInCaps: TMidiInCaps;
begin
  result := integer(midiInGetNumDevs)-1;
  while Result >= 0 do
  begin
    MidiResult := midiInGetDevCaps(Result, @lInCaps, SizeOf(TMidiInCaps));
    if (MidiResult = 0) and 
       (StrComp(lInCaps.szPname, PChar(name)) = 0) then
      break;
    dec(result);
  end;
end;

procedure TMidiInput.Open(const aDeviceIndex: TDeviceIndex);
var
  lHandle: THandle;
  lSysExData: TSysExData;
  Index: TSysDeviceIndex;
begin
  if IsOpen(aDeviceIndex) then Exit;

  Index := GetSysDeviceIndex(DeviceNames[aDeviceIndex]);
  if Index >= 0 then
  begin
    MidiResult := midiInOpen(@lHandle, Index, cardinal(@midiInCallback), aDeviceIndex, CALLBACK_FUNCTION);
    Handles[ aDeviceIndex ] := lHandle;
    lSysExData := TSysExData(fSysExData[aDeviceIndex]);

    lSysExData.SysExHeader.dwFlags := 0;

    MidiResult := midiInPrepareHeader(lHandle, @lSysExData.SysExHeader, SizeOf(TMidiHdr));
    MidiResult := midiInAddBuffer(lHandle, @lSysExData.SysExHeader, SizeOf(TMidiHdr));
    MidiResult := midiInStart(lHandle);
  end;
end;

procedure TMidiInput.DoSysExData(const aDeviceIndex: integer);
var
  lSysExData: TSysExData;
begin
  lSysExData := TSysExData(fSysExData[aDeviceIndex]);
  if lSysExData.SysExHeader.dwBytesRecorded = 0 then Exit;

  lSysExData.SysExStream.Write(lSysExData.SysExData, lSysExData.SysExHeader.dwBytesRecorded);
  if lSysExData.SysExHeader.dwFlags and MHDR_DONE = MHDR_DONE then
  begin
    lSysExData.SysExStream.Position := 0;
    if assigned(fOnSysExData) then fOnSysExData(aDeviceIndex, lSysExData.SysExStream);
    lSysExData.SysExStream.Clear;
  end;

  lSysExData.SysExHeader.dwBytesRecorded := 0;
  MidiResult := midiInPrepareHeader(GetHandle(aDeviceIndex), @lSysExData.SysExHeader, SizeOf(TMidiHdr));
  MidiResult := midiInAddBuffer(GetHandle(aDeviceIndex), @lSysExData.SysExHeader, SizeOf(TMidiHdr));
end;

destructor TMidiInput.Destroy;
begin
  FreeAndNil(fSysExData);
  inherited;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TMidiOutput.Close(const aDeviceIndex: TDeviceIndex);
var
  Handle: THandle;
begin
  if IsOpen(aDeviceIndex) then
  begin
    Handle := GetHandle(aDeviceIndex);
    MidiResult := midiOutClose(Handle);
    Handles[ aDeviceIndex ] := 0;
  end;
end;

procedure TMidiOutput.GenerateList;
var
  i, l: integer;
  lOutCaps: TMidiOutCaps;
  lHandle: THandle;
  s: string;
begin
  CloseAll;
  SetLength(DeviceNames, 0);
  SetLength(Handles, 0);

  // midiOutGetNumDevs does not update!!!
  for i := 0 to integer(midiOutGetNumDevs) - 1 do
  begin
    MidiResult := midiOutGetDevCaps(i, @lOutCaps, SizeOf(TMidiOutCaps));
    if MidiResult = 0 then
    begin
      if not IsCreativeSoundBlaster(lOutCaps.szPname) and
         (midiOutOpen(@lHandle, i, 0, 0, CALLBACK_NULL) = 0) then
      begin
        l := length(DeviceNames);
        SetLength(DeviceNames, l+1);
        SetLength(Handles, l+1);
        DeviceNames[l] := lOutCaps.szPname;
        Handles[l] := 0;
        s := lOutCaps.szPname;
        if (s = MicrosoftSync) then
        begin
          MicrosoftIndex := l;
          TrueMicrosoftIndex := MicrosoftIndex;
{$if defined(CONSOLE)}
          writeln('Index for ', MicrosoftSync, ' ', MicrosoftIndex);
        end else
          writeln('midi output ', Length(DeviceNames), ': ', s);
{$else}
        end;
{$endif}
        midiOutClose(lHandle);
      end;
    end;
  end;
end;

constructor TMidiOutput.Create;
begin
  inherited;

end;

function TMidiOutput.GetSysDeviceIndex(name: string): TSysDeviceIndex;  // >= 0: if device exists
var
  lOutCaps: TMidiOutCaps;
begin
  result := midiOutGetNumDevs-1;
  while result >= 0 do
  begin
    MidiResult := midiOutGetDevCaps(Result, @lOutCaps, SizeOf(TMidiOutCaps));
    if (MidiResult = 0) and 
       (StrComp(lOutCaps.szPname, PChar(name)) = 0) then
      break;    
    dec(result);
  end;
end;

procedure TMidiOutput.Open(const aDeviceIndex: TDeviceIndex);
var
  lHandle: THandle;
  Index: TSysDeviceIndex;
begin
  // device already open;
  if IsOpen(aDeviceIndex) then Exit;

  Index := GetSysDeviceIndex(DeviceNames[aDeviceIndex]);
  if Index >= 0 then
  begin
    MidiResult := midiOutOpen(@lHandle, Index, 0, 0, CALLBACK_NULL);
    Handles[ aDeviceIndex ] := lHandle;
  end;
end;

procedure TMidiOutput.Send(const aDeviceIndex: TDeviceIndex; const aStatus, aData1, aData2: byte);
var
  lMsg: cardinal;
begin
  if (aDeviceIndex < 0) or (length(Handles) <= aDeviceIndex) or
     (Handles[ aDeviceIndex ] = 0) then
    exit;

  lMsg := aStatus + (aData1 * $100) + (aData2 * $10000);
  MidiResult := midiOutShortMsg(GetHandle(aDeviceIndex), lMsg);
{$ifdef CONSOLE}
  writeln(Format('$%2.2x  $%2.2x (%d)  $%2.2x' ,[aStatus, aData1, aData1, aData2]));
{$endif}
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

constructor TSysExData.Create;
begin
  SysExHeader.dwBufferLength := cSysExBufferSize;
  SysExHeader.lpData := SysExData;
  fSysExStream := TMemoryStream.Create;
end;

destructor TSysExData.Destroy;
begin
  FreeAndNil(fSysExStream);
  inherited;
end;

initialization
  gMidiInput := nil;
  gMidiOutput := nil;
 
finalization
  FreeAndNil(gMidiInput);
  FreeAndNil(gMidiOutput);

end.

