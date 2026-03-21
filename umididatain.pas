unit UMidiDataIn;

{$ifdef fpc}
  {$mode delphi}
{$endif}

interface

uses
  Classes, SysUtils, UMidiEvent, UMidiDataStream, CriticalSection;

var
  SavePath: string;

type
  TMidiInData = record
    DeviceIndex: integer;
    Timestamp: Int64;
    MidiEvent: TMidiEvent;

    procedure Clear;
    procedure Init(MidiEvent_: TMidiEvent);
    function GetMidiEvent: TMidiEvent;
  end;

  TMidiInRingBuffer = class
  private
    critical: TCriticalSection;
    Head, Tail: word;
    Buffer: array [0..1023] of TMidiEvent;
  public

    constructor Create;
    destructor Destroy; override;
    function Empty: boolean;
    function Get(var rec: TMidiEvent): boolean;
    function Put(rec: TMidiEvent): boolean;
  end;

  TMidiEventRecorder = class
  private
    critical: TCriticalSection;
    EventCount: integer;
  {$ifndef USE_GET32}
    oldTime: TTime;
  {$else}
    oldTime: Int64;
  {$endif}
  public
    Header: TDetailHeader;
    MidiEvents: TMidiEventArray;
    Instrument: AnsiString;

    constructor Create;
    destructor Destroy; override;
    procedure Start(Instr: AnsiString);
    procedure Stop;
    procedure Append(MidiEvent: TMidiEvent);
    function MakeRecordStream: TMidiSaveStream;

    property Size: integer read EventCount;
  end;

implementation

function MakeDirtySimple(const Events: TMidiEventArray): TSimpleDataStream;
var
  i: integer;
begin
  result := TSimpleDataStream.Create;

  result.SetSize(10000000);
  result.Position := 0;

  for i := 0 to Length(Events)-1 do
    with Events[i] do
      if Event < 12 then
      begin
        result.WriteString(Format('  %8d', [var_len]));
        result.WriteString(Format('  $%2.2x', [command]));
        result.WriteString(Format('  $%2.2x', [d1]));
        result.WriteString(Format('  $%2.2x', [d2]));
        result.writeln;
      end;
  result.SetSize(result.Position);
end;


constructor TMidiInRingBuffer.Create;
begin
  Critical := TCriticalSection.Create;
  Head := 0;
  Tail := 0;
  FillChar(Buffer, sizeof(Buffer), 0);
end;

destructor TMidiInRingBuffer.Destroy;
begin
  Critical.Free;
end;

function TMidiInRingBuffer.Empty: boolean;
begin
  result := Tail = Head;
end;

function TMidiInRingBuffer.Get(var rec: TMidiEvent): boolean;
begin
  result := false;
  rec.Clear;
  if self = nil then
    exit;

  Critical.Acquire;
  try
    result := not Empty;
    if result then
    begin
      rec := Buffer[Tail];
      Tail := (Tail + 1) mod Length(Buffer);
    end;
  finally
    Critical.Release;
  end;
end;

function TMidiInRingBuffer.Put(rec: TMidiEvent): boolean;
var
  oldHead: word;
begin
  result := false;
  Critical.Acquire;
  try
    oldHead := Head;
    Head := (Head + 1) mod Length(Buffer);
    if Empty then
      Tail := (Tail + 1) mod Length(Buffer);

    Buffer[oldHead] := rec;
    result := true;
  finally
    Critical.Release;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TMidiInData.Clear;
begin
  DeviceIndex := 0;
  Timestamp := 0;
  MidiEvent.Clear;
end;

function TMidiInData.GetMidiEvent: TMidiEvent;
begin
  result := MidiEvent;
end;

procedure TMidiInData.Init(MidiEvent_: TMidiEvent);
begin
  Clear;
  MidiEvent := MidiEvent_;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TMidiEventRecorder.Create;
begin
  Critical := TCriticalSection.Create;
  Instrument := '';
  EventCount := 0;
  SetLength(MidiEvents, 0);
  Header.Clear;
end;

destructor TMidiEventRecorder.Destroy;
begin
  Critical.Free;
end;

procedure TMidiEventRecorder.Append(MidiEvent: TMidiEvent);
const
  msInDay = 24*3600000.0;
var
{$ifndef USE_GET32}
  delta, Time: TDate;
{$else}
  delta: Int64;
{$endif}
  Ticks: integer;

  function MsToTicks(MsDelay: double): integer;
  begin
    with Header do
      result := trunc(MsDelay*TicksPerQuarter*QuarterPerMin / 60000.0);
  end;

begin
  if (MidiEvent.Event < 8) then
    exit;

  // Volumen- und Expression-Change ausfiltern
  if (MidiEvent.Event = 11) and (MidiEvent.d1 in [7, 11]) then
    exit;

  MidiEvent.CorrectRunningStatus;

  if EventCount >= Length(MidiEvents) then
    SetLength(MidiEvents, 2*Length(MidiEvents)+1);
{$ifndef USE_GET32}
  time := now;
  if EventCount = 1 then
    OldTime := time;
  delta := msInDay*(time - OldTime); // ms
  if (delta > 1000000) then
  begin
    delta := 0;
    OldTime := time;
  end;
  Ticks := MsToTicks(delta);
  OldTime := OldTime + Header.TicksToMs(Ticks)/msInDay;
{$else}
  delta := GetTickCount64 - OldTime;  // in ms
  Ticks := MsToTicks(delta);
  oldTime := oldTime + trunc(Header.TicksToMs(Ticks));
{$endif}
  if EventCount > 1 then
    MidiEvents[EventCount-1].var_len := Ticks;

  Critical.Acquire;
  try
    MidiEvents[EventCount] := MidiEvent;
    if MidiEvents[EventCount].var_len > 1000000 then
      MidiEvents[EventCount].var_len := 0;
    inc(EventCount);
  finally
    Critical.Release;
  end;
end;

procedure TMidiEventRecorder.Start(Instr: AnsiString);
begin
{$ifndef USE_GET32}
  OldTime := Now;
{$else}
  OldTime := 0;
{$endif}
  Instrument := Instr;
  EventCount := 1;
  SetLength(MidiEvents, 10000);
  MidiEvents[0].Clear;
end;

procedure TMidiEventRecorder.Stop;
begin
  SetLength(MidiEvents, EventCount);
end;

function TMidiEventRecorder.MakeRecordStream: TMidiSaveStream;
var
  i, k, j: integer;
  iOn, iTakt, iPush: integer;
  Push, PushFound: boolean;
  Event: TMidiEvent;
  Dirty: TSimpleDataStream;
begin
  Stop;

{$ifdef DEBUG}
  Dirty := MakeDirtySimple(MidiEvents);
  Dirty.SaveToFile(SavePath+'Dirty.txt');
  Dirty.Free;
{$endif}

  result := nil;
  iOn := 0;
  while (iOn < Length(MidiEvents)) and
        ((MidiEvents[iOn].Event <> 9) or   // <> On
         (MidiEvents[iOn].Channel = 9)) do
    inc(iOn);
  if iOn >= Length(MidiEvents) then // enthält kein On
    exit;

  iTakt := iOn-1;
  while (iTakt >= 1) and
        ((MidiEvents[iTakt].Event <> 9) or
         (MidiEvents[iTakt].Channel <> 9)) do
    dec(iTakt);

  if iTakt > 1 then
  begin
    iPush := iOn - 1;
    while (iPush > 0) and not MidiEvents[iPush].IsPushPull do
      dec(iPush);
    PushFound := MidiEvents[iPush].IsPushPull;
    if PushFound then
      Push := MidiEvents[iPush].IsPush;
  end;

  if (iTakt <> 1) and (iOn <> 1) and PushFound then
  begin
    MidiEvents[1].SetEvent($b0, ControlPushPull, 0);
    if Push then
      MidiEvents[1].d2 := 1;
  end;

  if iTakt > 1 then
    k := iTakt
  else
    k := iOn;
  // Events von 2 bis k-1 löschen
  if k > 2 then
  begin
    j := k-2;
    for i := 2 to Length(MidiEvents)-1-j do
      MidiEvents[i] := MidiEvents[i + j];
    SetLength(MidiEvents, Length(MidiEvents)-j);
  end;

  k := Length(MidiEvents)-1;
  while (k > 0) and (MidiEvents[k].Event <> 8) do
    dec(k);
  if k > 10 then
    SetLength(MidiEvents, k+1);

{$if false}
  // Metronom entfernen
  i := 2;
  k := 2;
  while i < Length(MidiEvents) do
  begin
    if (MidiEvents[i].command = $99) or
       (MidiEvents[i].command = $89) then
    begin
      inc(MidiEvents[k].var_len, MidiEvents[i].var_len);
    end else begin
      MidiEvents[k] := MidiEvents[i];
      inc(k);
    inc(i);
  end;
  SetLength(MidiEvents, k);
{$endif}

{$ifdef DEBUG}
  Dirty := MakeDirtySimple(MidiEvents);
  Dirty.SaveToFile(SavePath+'Dirty2.txt');
  Dirty.Free;
{$endif}

  result := TMidiSaveStream.Create;

  result.SetHead;
  result.AppendTrackHead(0);
  result.AppendHeaderMetaEvents(Header);
  result.AppendMetaEvent(2, AnsiString('Copyright by juerg5524.ch'));
  result.AppendTrackEnd(false);
  result.AppendTrackHead(0);

  Event.SetEvent($c0, 21, 0);  // Akkordeon
  for i := 0 to 7 do
  begin
    result.AppendEvent(Event);
    inc(Event.command);
  end;

  for i := 1 to Length(MidiEvents)-1 do
    result.AppendEvent(MidiEvents[i]);

  result.AppendTrackEnd(true);
end;

initialization

SavePath := ExtractFilePath(ParamStr(0));


finalization


end.

