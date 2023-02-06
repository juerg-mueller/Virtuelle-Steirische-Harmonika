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
    fDeviceNames: TStringList;
    fMidiResult: MMResult;
    procedure SetMidiResult(const Value: MMResult);
  protected
    property MidiResult: MMResult read fMidiResult write SetMidiResult;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function GetHandle(const aDeviceIndex: TDeviceIndex): THandle;
    procedure Open(const aDeviceIndex: TDeviceIndex); virtual; abstract;
    procedure Close(const aDeviceIndex: TDeviceIndex); virtual; abstract;
    function IsOpen(const aDeviceIndex: integer) : boolean; virtual;
   // close all devices
    procedure CloseAll;
    // the devices
    property DeviceNames: TStringList read fDeviceNames;
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
    class procedure Free_Instance;
    procedure GenerateList;
    function GetSysDeviceIndex(name: string): TSysDeviceIndex; 
  end;

  // MIDI input devices
  function MidiInput: TMidiInput;
  // MIDI output Devices
  function MidiOutput: TMidiOutput;

//  procedure DoSoundPitch(Pitch: byte; On_: boolean);
  procedure ResetMidiOut;

const
  MicrosoftSync = 'Microsoft GS Wavetable Synth';
  UM_ONE = 'UM-ONE';
  
var
  MicrosoftIndex: integer = -1;
  TrueMicrosoftIndex: integer = -1;
  MidiInstrDiskant: byte = $15; // Akkordeon
  MidiInstrBass: byte = $15; // Akkordeon
  BassBankActiv: boolean = false;
  MidiBankDiskant: byte = 0;
  MidiBankBass: byte = 0;
  Scene: integer = 0;

  VolumeDiscant: double = 0.9;
  VolumeBass: double = 0.9;

procedure OpenMidiMicrosoft;
procedure SendSzene(Status, Data1, Data2: byte);
procedure ChangeSzene(Index: integer; UseMasterAcc: boolean);


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
  fDeviceNames := TStringList.Create;
end;

destructor TMidiDevices.Destroy;
begin
  FreeAndNil(fDeviceNames);
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
  if not InRange(aDeviceIndex, 0, fDeviceNames.Count - 1) then
    raise EMidiDevices.CreateFmt('%s: Device index out of bounds! (%d)', [ClassName,aDeviceIndex]);

  Result := THandle(fDeviceNames.Objects[ aDeviceIndex ]);
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
    fDeviceNames.Objects[aDeviceIndex] := nil;
  end;
end;
                         
procedure TMidiDevices.CloseAll;
var
  i: integer;
begin
  for i:= 0 to fDeviceNames.Count - 1 do
    Close(i);
end;

function TMidiDevices.IsOpen(const aDeviceIndex: integer) : boolean;
begin
  result := GetHandle(aDeviceIndex) <> 0;
end;

procedure TMidiInput.GenerateList;
var
  lInCaps: TMidiInCaps;
  lHandle: THandle;
  i: integer;
begin
  CloseAll;
  fDeviceNames.Clear;
  fSysExData.Clear;

 // midiInGetNumDevs does not update!!!
  for i := 0 to integer(midiInGetNumDevs) - 1 do
  begin
    MidiResult := midiInGetDevCaps(i, @lInCaps, SizeOf(TMidiInCaps));
    if MidiResult = 0 then
    begin
      if not IsCreativeSoundBlaster(lInCaps.szPname) and
         (midiInOpen(@lHandle, i, 0, 0, CALLBACK_NULL) = 0) then
      begin
    {$if defined(CONSOLE)}
        writeln('midi input ', fDeviceNames.Count, ': ', lInCaps.szPname);
    {$endif}
        midiInClose(lHandle);
        fDeviceNames.Add(StrPas(lInCaps.szPname));
        fSysExData.Add(TSysExData.Create);
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
    fDeviceNames.Objects[ aDeviceIndex ] := TObject(lHandle);
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
    fDeviceNames.Objects[ aDeviceIndex ] := nil;
  end;
end;

procedure TMidiOutput.GenerateList;
var
  i: integer;
  lOutCaps: TMidiOutCaps;
  lHandle: THandle;
  s: string;
begin
  CloseAll;
  fDeviceNames.Clear;
  
  // midiOutGetNumDevs does not update!!!
  for i := 0 to integer(midiOutGetNumDevs) - 1 do
  begin
    MidiResult := midiOutGetDevCaps(i, @lOutCaps, SizeOf(TMidiOutCaps));
    if MidiResult = 0 then
    begin
      if not IsCreativeSoundBlaster(lOutCaps.szPname) and
         (midiOutOpen(@lHandle, i, 0, 0, CALLBACK_NULL) = 0) then
      begin
        s := lOutCaps.szPname;                       
        if (s = MicrosoftSync) or
           (Copy(s, 1, Length(UM_ONE)) = UM_ONE) then
        begin
          MicrosoftIndex := fDeviceNames.Count;
          TrueMicrosoftIndex := MicrosoftIndex;
{$if defined(CONSOLE)}
          writeln('Index for ', MicrosoftSync, ' ', MicrosoftIndex);
        end else
          writeln('midi output ', fDeviceNames.Count, ': ', s);
{$else}
        end;
{$endif}
       //  MIDICAPS_VOLUME          = $0001;  { supports volume control }
       //  MIDICAPS_LRVOLUME        = $0002;  { separate left-right volume control }
       //  MIDICAPS_CACHE           = $0004;
       //  MIDICAPS_STREAM          = $0008;  { driver supports midiStreamOut directly }
       //  writeln(IntToHex(lOutCaps.dwSupport));
        fDeviceNames.Add(lOutCaps.szPname);
        midiOutClose(lHandle);
      end;
    end;
  end;
{  if (fDeviceNames.Count > 1) and
     (fDeviceNames.IndexOf('Midi Through Port-0') = 0) then
    MicrosoftIndex := 1   }

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
    fDeviceNames.Objects[ aDeviceIndex ] := TObject(lHandle);
  end;
end;

procedure TMidiOutput.Send(const aDeviceIndex: TDeviceIndex; const aStatus, aData1, aData2: byte);
var
  lMsg: cardinal;
begin
  if (aDeviceIndex < 0) or
     not assigned(fDeviceNames.Objects[ aDeviceIndex ]) then
    exit;

  lMsg := aStatus + (aData1 * $100) + (aData2 * $10000);
  MidiResult := midiOutShortMsg(GetHandle(aDeviceIndex), lMsg);
{$ifdef CONSOLE}
  writeln(Format('$%2.2x  $%2.2x  $%2.2x' ,[aStatus, aData1, aData2]));
{$endif}
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
{
procedure DoSoundPitch(Pitch: byte; On_: boolean);
begin
  if MicrosoftIndex >= 0 then
  begin
    if On_ then
    begin
   //   writeln(Pitch, '  $', IntToHex(Pitch));
      MidiOutput.Send(MicrosoftIndex, $90, Pitch, $4f)
    end else
      MidiOutput.Send(MicrosoftIndex, $80, Pitch, $40);
  end;
end;
}
procedure ResetMidiOut;
var
  i: integer;
begin
  if MicrosoftIndex >= 0 then
  begin
    if MidiOutput.IsOpen(MicrosoftIndex) then
      for i := 0 to 15 do
      begin
        MidiOutput.Send(MicrosoftIndex, $B0 + i, 120, 0);  // all sound off
      end;
  end;
end;

procedure ChangeBank(Index, Channel, Bank, Instr: byte);
begin
  MidiOutput.Send(Index, $b0 + Channel, 0, Bank);  // 0x32, LSB Bank);
  MidiOutput.Send(Index, $c0 + Channel, Instr, 0);
end;

// Drum Kit: Channel 10
// Program pp:  C9 pp

// Trompete  Klarinette  Gitarre   Akkordeon
// 12            16        07         41
// 00            00        04         61
// 0             -5         0          0
type
  Accord = record
    Channel: byte;
    Bank: byte;
    Instr: byte;
    Delta: integer;
    Velo: integer;      // in %
  end;

  AccordArr = array [0..4] of Accord;

const

  tx : AccordArr =
    (
      (Channel: 1; Bank: 12; Instr: 0; Delta: 3; Velo: -5),
      (Channel: 2; Bank: 17; Instr: 0; Delta: -5; Velo: -5),
      (Channel: 3; Bank: 7; Instr: 4; Delta: 0; Velo: -5),
      (Channel: 4; Bank: 41; Instr: 61; Delta: 0),
      ()
    );

    tx0 : AccordArr =
    (
      (Channel: 1; Bank: 0; Instr: 56; Delta: 3; Velo: -5),
      (Channel: 2; Bank: 0; Instr: 71; Delta: -5; Velo: -5),
      (Channel: 3; Bank: 0; Instr: 24; Delta: 0; Velo: -5),
      (Channel: 4; Bank: 0; Instr: 21; Delta: 0),
      ()
    );

  ty : AccordArr =
    (
      (Channel: 5; Bank: 15; Instr: 27; Delta: 0),  // Bariton
      (Channel: 6; Bank: 19; Instr: 7; Delta: 0),  // E-Bass
      (Channel: 7; Bank: 7; Instr: 4; Delta: 0),   // Akkordenbass
      (Channel: 8; Bank: 41; Instr: 61; Delta: 0),  // Gitarre
      ()
    );

var
  AccDiskant: AccordArr;
  AccBass: AccordArr;

procedure SendSzene(Status, Data1, Data2: byte);
var
  i: integer;

   procedure Send(const Acc: Accord);
   var
     d1, d2: integer;
   begin
     if Acc.Channel > 0 then
     begin
       d1 := Data1 + Acc.Delta;
       if not (d1 in [0 .. 127]) then
         d1 := Data1;
       d2 := round(Data2*(100 + Acc.Velo)/100.0) ;
       if not (d2 in [0 .. 127]) then
         d2 := Data2;
       MidiOutput.Send(MicrosoftIndex, (Status and $f0) or Acc.Channel, d1, d2);
     end;
   end;

begin
  if (MicrosoftIndex >= 0) then
  begin
    if Scene <= 0 then
      MidiOutput.Send(MicrosoftIndex, Status, Data1, Data2)
    else begin
      if (Status and $f) < 5 then
      begin
        for i := 0 to High(AccDiskant) do
          Send(AccDiskant[i]);
      end else begin
        for i := 0 to High(AccBass) do
          Send(AccBass[i]);
      end;
    end;
  end;
end;

procedure OpenMidiMicrosoft;
var
  i: integer;
begin
  if MicrosoftIndex >= 0 then
  begin
    MidiOutput.Open(MicrosoftIndex);
    try
      if Scene <= 0 then
      begin
        for i := 0 to 8 do
          if (i > 4) and BassBankActiv then
            ChangeBank(MicrosoftIndex, i, MidiBankBass, MidiInstrBass)
          else
            ChangeBank(MicrosoftIndex, i, MidiBankDiskant, MidiInstrDiskant);
      end else begin
        for i := 0 to High(AccDiskant) do
          with AccDiskant[i] do
            if Channel > 0 then
              ChangeBank(MicrosoftIndex, Channel, Bank, Instr);
        for i := 0 to High(AccBass) do
          with AccBass[i] do
            if Channel > 0 then
              ChangeBank(MicrosoftIndex, Channel, Bank, Instr);
      end;
    finally
    end;
  {$if defined(CONSOLE)}
    writeln('Midi Port-', MicrosoftIndex, ' opend');
  {$endif}
  end;
end;

procedure ChangeSzene(Index: integer; UseMasterAcc: boolean);
begin
  Scene := Index;
  if UseMasterAcc then
  begin
    AccDiskant := tx;
  end else begin
    AccDiskant := tx0;
  end;
  AccBass := ty;

  OpenMidiMicrosoft;
end;

initialization
  gMidiInput := nil;
  gMidiOutput := nil;
 
finalization
  FreeAndNil(gMidiInput);
  FreeAndNil(gMidiOutput);

end.

