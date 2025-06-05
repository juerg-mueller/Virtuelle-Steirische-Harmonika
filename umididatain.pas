unit UMidiDataIn;

{$ifdef fpc}
  {$mode delphi}
{$endif}

interface

uses
  Classes, SysUtils, UMidiEvent, SyncObjs, UMidiDataStream, UEventArray;

type
  TMidiInData = record
    DeviceIndex: integer;
    Status, Data1, Data2: byte;
    var_len: integer;
    Timestamp: Int64;

    procedure Clear;
    procedure Init(command, d1, d2: byte);
    function GetMidiEvent: TMidiEvent;
  end;

  TMidiInRingBuffer = class
  private
    Critical: syncobjs.TCriticalSection;
    Head, Tail: word;
    Buffer: array [0..1023] of TMidiInData;
    OldTime: Int64;
  public
    Header: TDetailHeader;

    constructor Create(DetailHeader: TDetailHeader);
    destructor Destroy; override;
    function Empty: boolean;
    function Get(var rec: TMidiInData): boolean;
    function Put(rec: TMidiInData): boolean;
  end;

  TMidiEventRecorder = class
  private
    count: integer;
  public
    MidiEvents: TMidiEventArray;

    constructor Create;
    procedure Start;
    procedure Stop;
    procedure Append(const MidiEvent: TMidiEvent);
    function MakeRecordStream(Header: TDetailHeader): TMidiSaveStream;

    property Size: integer read count;
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


constructor TMidiInRingBuffer.Create(DetailHeader: TDetailHeader);
begin
  Critical := TCriticalSection.Create;
  Head := 0;
  Tail := 0;
  OldTime := 0;
  FillChar(Buffer, sizeof(Buffer), 0);
  Header := DetailHeader;
end;

destructor TMidiInRingBuffer.Destroy;
begin
  Critical.Free;
end;

function TMidiInRingBuffer.Empty: boolean;
begin
  result := Tail = Head;
end;

function TMidiInRingBuffer.Get(var rec: TMidiInData): boolean;
begin
  result := false;
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

function TMidiInRingBuffer.Put(rec: TMidiInData): boolean;
var
  oldHead: word;
  time, delta: Int64;
  Ticks: integer;
begin
  result := false;

  delta := GetTickCount64 - OldTime;  // ms
  Ticks := Header.MsDelayToTicks(delta);
  rec.var_len := Ticks;
  delta := Round(Header.TicksToMs(Ticks));

  Critical.Acquire;
  try
    OldTime := OldTime + delta;
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
  var_len := 0;
  Timestamp := 0;
end;

function TMidiInData.GetMidiEvent: TMidiEvent;
begin
  result.command:= Status;
  result.d1 := Data1;
  result.d2 := Data2;
  result.var_len := var_len;
  SetLength(result.Bytes, 0);
end;

procedure TMidiInData.Init(command, d1, d2: byte);
begin
  Clear;
  Status := command;
  Data1 := d1;
  Data2 := d2;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TMidiEventRecorder.Create;
begin
  count := 0;
  SetLength(MidiEvents, 0);
end;

procedure TMidiEventRecorder.Append(const MidiEvent: TMidiEvent);
begin
  if count >= Length(MidiEvents) then
    SetLength(MidiEvents, 2*Length(MidiEvents)+1);

  MidiEvents[count] := MidiEvent;
  if MidiEvents[count].var_len > 1000000 then
    MidiEvents[count].var_len := 0;
  inc(count);
end;

procedure TMidiEventRecorder.Start;
begin
  count := 1;
  SetLength(MidiEvents, 10000);
  MidiEvents[0].Clear;
end;

procedure TMidiEventRecorder.Stop;
begin
  SetLength(MidiEvents, count);
end;

function TMidiEventRecorder.MakeRecordStream(Header: TDetailHeader): TMidiSaveStream;
var
  i, k, j: integer;
  iOn, iTakt, iPush: integer;
  Push, PushFound: boolean;
  Event: TMidiEvent;
  Dirty: TSimpleDataStream;
begin
  Stop;

  if Length(MidiEvents) >= 2 then
    MidiEvents[1].var_len := 0;

{$ifdef DEBUG}
  Dirty := MakeDirtySimple(MidiEvents);
  Dirty.SaveToFile('Dirty.txt');
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
  Dirty.SaveToFile('Dirty2.txt');
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

  for i := 0 to Length(MidiEvents)-1 do
    result.AppendEvent(MidiEvents[i]);

  result.AppendTrackEnd(true);
end;

end.

