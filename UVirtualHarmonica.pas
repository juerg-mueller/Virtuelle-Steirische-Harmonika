unit UVirtualHarmonica;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, SyncObjs,
  UInstrument, UMidiEvent;

type
  TMidiTimeEvent = record
    TimeStamp: TDateTime;
    MidiEvent: TMidiEvent;
  end;

  TfrmVirtualHarmonica = class(TForm)
    gbMidi: TGroupBox;
    lblKeyboard: TLabel;
    Label17: TLabel;
    lbVirtual: TLabel;
    cbxMidiOut: TComboBox;
    cbxMidiInput: TComboBox;
    btnResetMidi: TButton;
    cbxVirtual: TComboBox;
    gbInstrument: TGroupBox;
    Label13: TLabel;
    cbxTransInstrument: TComboBox;
    cbTransInstrument: TComboBox;
    Label1: TLabel;
    gbBalg: TGroupBox;
    cbxShiftIsPush: TCheckBox;
    Label2: TLabel;
    cbxMidiInstrument: TComboBox;
    Label3: TLabel;
    GroupBox1: TGroupBox;
    btnRecord: TButton;
    SaveDialog1: TSaveDialog;
    procedure cbTransInstrumentChange(Sender: TObject);
    procedure cbxMidiInputChange(Sender: TObject);
    procedure cbxTransInstrumentChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure cbxMidiOutChange(Sender: TObject);
    procedure btnResetMidiClick(Sender: TObject);
    procedure cbxVirtualChange(Sender: TObject);
    procedure cbxShiftIsPushClick(Sender: TObject);
    procedure cbxMidiInstrumentChange(Sender: TObject);
    procedure cbTransInstrumentKeyPress(Sender: TObject; var Key: Char);
    procedure cbTransInstrumentKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbTransInstrumentKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnRecordClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    CriticalSendOut: TCriticalSection;
    TimeEventCount: cardinal;
    TimeEventArray: array of TMidiTimeEvent;
    procedure RegenerateMidi;
    procedure SendMidiOut(const aStatus, aData1, aData2: byte);
  public
    Instrument: TInstrument;
  end;

var
  frmVirtualHarmonica: TfrmVirtualHarmonica;

implementation

{$R *.dfm}

uses
  UAmpel, Midi, UVirtual, UFormHelper, UGriffEvent, UMidiSaveStream;

procedure TfrmVirtualHarmonica.SendMidiOut(const aStatus, aData1, aData2: byte);
var
  Event: TMidiTimeEvent;
  Last: double;
begin
  CriticalSendOut.Acquire;
  try
    inc(TimeEventCount);
    if TimeEventCount >= Length(TimeEventArray) then
      SetLength(TimeEventArray, TimeEventCount+1);

    Last := time;
    if TimeEventCount > 1 then
      TimeEventArray[TimeEventCount-2].TimeStamp := Last;

    with TimeEventArray[TimeEventCount-1] do
    begin
      TimeStamp := Last;
      MidiEvent.Clear;
      MidiEvent.command := aStatus;
      MidiEvent.d1 := aData1;
      MidiEvent.d2 := aData2;
    end;
  finally
    CriticalSendOut.Release;
  end;
end;

procedure TfrmVirtualHarmonica.btnRecordClick(Sender: TObject);

  procedure Deactivate(Ok: boolean);
  begin
    gbInstrument.Enabled := Ok;
    gbMidi.Enabled := Ok;
    gbBalg.Enabled := Ok;
  end;

const
  MilliSekProTag = 3600.0*24*1000;
var
  i: integer;
  Stream: TMidiSaveStream;
  TimeOffset: double;
  DetailHeader: TDetailHeader;
  Event: TMidiEvent;
  Saved: boolean;
begin
  if btnRecord.Caption = 'Record' then
  begin
    Deactivate(false);
    TimeEventCount := 0;
    SendMidiOut($B0, ControlSustain, ord(ShiftUsed));
    frmAmpel.AmpelEvents.PSendMidiOut := SendMidiOut;
    btnRecord.Caption := 'Stop';
  end else begin
    frmAmpel.AmpelEvents.PSendMidiOut := nil;
    if TimeEventCount > 1 then
    begin
      Stream := TMidiSaveStream.Create;
      DetailHeader.Clear;
      Stream.SetHead(DetailHeader.DeltaTimeTicks);
      Stream.AppendTrackHead;
      Event.MakeMetaEvent(2, 'VirtualHarmonica');
      Stream.AppendEvent(Event);
      Event.MakeMetaEvent(4, Instrument.Name);
      Stream.AppendEvent(Event);
      Stream.AppendHeaderMetaEvents(DetailHeader);
      Stream.AppendTrackEnd(false);
      Stream.AppendTrackHead;
      for i := 1 to 6 do
      begin
        Stream.AppendEvent($C0 + i, MidiInstr, 0); // Instrument
        Stream.WriteByte(0); // var_len = 0
      end;

      i := 0;
      repeat
        Stream.AppendEvent(TimeEventArray[i].MidiEvent);
        inc(i);
      until (i >= TimeEventCount) or (TimeEventArray[i].MidiEvent.Event = 9);
      if i < TimeEventCount then
        TimeOffset := TimeEventArray[i].TimeStamp;
      while i < TimeEventCount do
      begin
        with TimeEventArray[i] do begin
          TimeEventArray[i].MidiEvent.var_len :=
            DetailHeader.MsDelayToTicks(round(MilliSekProTag*(TimeStamp - TimeOffset)));
          TimeOffset :=
            TimeOffset + DetailHeader.TicksToMs(MidiEvent.var_len) / MilliSekProTag;
          Stream.AppendEvent(MidiEvent);
        end;
        inc(i);
      end;
      Stream.AppendTrackEnd(true);
      Saved := false;
      while not Saved and SaveDialog1.Execute do
      begin
        if not FileExists(SaveDialog1.FileName) or
          (Warning('File exists! Overwrite?') = IDYES) then
        begin
          Stream.SaveToFile(SaveDialog1.FileName);
          Saved := true;
        end;
      end;
      Stream.Free;
    end;
    btnRecord.Caption := 'Record';
    Deactivate(true);
  end;
end;

procedure TfrmVirtualHarmonica.btnResetMidiClick(Sender: TObject);
begin
//  ResetMidi;
  RegenerateMidi;
end;

procedure TfrmVirtualHarmonica.cbTransInstrumentChange(Sender: TObject);
var
  s: string;
  index: integer;
begin
  if cbTransInstrument.ItemIndex < 0 then
    cbTransInstrument.ItemIndex := 0;
  s := cbTransInstrument.Items[cbTransInstrument.ItemIndex];
  cbTransInstrument.Text := s;

  index := InstrumentIndex(AnsiString(s));
  if index < 0 then
     index := 0;
  Instrument := InstrumentsList[index]^;
  cbxTransInstrumentChange(nil);

  frmAmpel.ChangeInstrument(@Instrument);
  if Sender <> nil then
    Midi.OpenMidiMicrosoft;
end;

procedure TfrmVirtualHarmonica.cbTransInstrumentKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  frmAmpel.FormKeyDown(Sender, Key, Shift);
end;

procedure TfrmVirtualHarmonica.cbTransInstrumentKeyPress(Sender: TObject;
  var Key: Char);
begin
  Key := #0;
end;

procedure TfrmVirtualHarmonica.cbTransInstrumentKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if not frmAmpel.IsActive then
  begin
    frmAmpel.Show;
  end;
  frmAmpel.FormKeyUp(Sender, Key, Shift);
  frmAmpel.SetFocus;
end;

procedure TfrmVirtualHarmonica.cbxMidiInputChange(Sender: TObject);
begin
  Sustain_:= false;
  MidiInput.CloseAll;
  if cbxMidiInput.ItemIndex > 0 then
    MidiInput.Open(cbxMidiInput.ItemIndex - 1);
end;

procedure TfrmVirtualHarmonica.cbxMidiInstrumentChange(Sender: TObject);
begin
  MidiInstr := cbxMidiInstrument.ItemIndex;
  OpenMidiMicrosoft;
end;

procedure TfrmVirtualHarmonica.cbxMidiOutChange(Sender: TObject);
begin
  if cbxMidiOut.ItemIndex >= 0 then
  begin
    if MicrosoftIndex >= 0 then
      MidiOutput.Close(MicrosoftIndex);
    if cbxMidiOut.ItemIndex = 0 then
      MicrosoftIndex := -1
    else
    if iVirtualMidi <> cbxMidiOut.ItemIndex-1 then
      MicrosoftIndex := cbxMidiOut.ItemIndex-1
    else
      cbxMidiOut.ItemIndex := TrueMicrosoftIndex+1;

    OpenMidiMicrosoft;
    frmAmpel.InitLastPush;
  end;
end;

procedure TfrmVirtualHarmonica.cbxTransInstrumentChange(Sender: TObject);
var
  delta: integer;
begin
  if cbxTransInstrument.ItemIndex >= 0 then
  begin
    delta := cbxTransInstrument.ItemIndex - 11;
    delta := delta - Instrument.TransposedPrimes;
    Instrument.Transpose(delta);
  end;
end;

procedure TfrmVirtualHarmonica.cbxVirtualChange(Sender: TObject);
begin
  if iVirtualMidi >= 0 then
    MidiOutput.Close(iVirtualMidi);
  iVirtualMidi := CbxVirtual.ItemIndex - 1;
  if cbxMidiOut.ItemIndex = iVirtualMidi then
  begin
    iVirtualMidi := -1;
    CbxVirtual.ItemIndex := 0;
  end;
  if iVirtualMidi >= 0 then
  begin
    MidiOutput.Open(iVirtualMidi);
  end;
end;

procedure TfrmVirtualHarmonica.cbxShiftIsPushClick(Sender: TObject);
begin
  shiftIsPush := cbxShiftIsPush.Checked;
end;

procedure TfrmVirtualHarmonica.FormCreate(Sender: TObject);
var
  i: integer;
begin
{$ifdef WIN64}
  Caption := Caption + ' (64)';
{$else}
  Caption := Caption + ' (32)';
{$endif}
  SetLength(TimeEventArray, 100000);
  TimeEventCount := 0;

  cbTransInstrument.Items.Clear;
  for i := 0 to High(InstrumentsList) do
    cbTransInstrument.Items.Add(string(InstrumentsList[i].Name));
{$if defined(CONSOLE)}
  if not RunningWine then
    ShowWindow(GetConsoleWindow, SW_SHOWMINIMIZED);
  SetConsoleTitle('VirtualHarmonica - Trace Window');
{$endif}
  Application.OnMessage := frmAmpel.KeyMessageEvent;

  UVirtual.LoopbackName := 'VirtualHarmonica loopback';
  InstallLoopback;
  Sleep(10);
  Application.ProcessMessages;
  CriticalSendOut := TCriticalSection.Create;
end;

procedure TfrmVirtualHarmonica.FormDestroy(Sender: TObject);
begin
  SetLength(TimeEventArray, 0);
  CriticalSendOut.Free;
end;

procedure TfrmVirtualHarmonica.FormShow(Sender: TObject);
begin
  cbTransInstrument.ItemIndex := 2;
  cbTransInstrumentChange(nil);

  RegenerateMidi;
  MidiInput.OnMidiData := frmAmpel.OnMidiInData;

  frmAmpel.ChangeInstrument(@Instrument);
  frmAmpel.Show;
  frmAmpel.SetFocus;
end;

procedure TfrmVirtualHarmonica.RegenerateMidi;
begin
  MidiOutput.GenerateList;
  MidiInput.GenerateList;

  cbxMidiOut.Items.Assign(MidiOutput.DeviceNames);
  cbxMidiOut.Items.Insert(0, '');
  Midi.OpenMidiMicrosoft;
  cbxMidiOut.ItemIndex := MicrosoftIndex + 1;

  cbxMidiInput.Visible := MidiInput.DeviceNames.Count > 0;
  lblKeyboard.Visible := cbxMidiInput.Visible;
  if cbxMidiInput.Visible then
  begin
    cbxMidiInput.Items.Assign(MidiInput.DeviceNames);
    cbxMidiInput.Items.Insert(0, '');
    cbxMidiInput.ItemIndex := 0;
    cbxMidiInputChange(nil);
  end;

  cbxVirtual.Items.Clear;
  cbxVirtual.Items.Assign(MidiOutput.DeviceNames);
  cbxVirtual.Items.Insert(0, '');
  cbxVirtual.ItemIndex := 0;
end;


end.
