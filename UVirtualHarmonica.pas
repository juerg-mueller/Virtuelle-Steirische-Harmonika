unit UVirtualHarmonica;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

{$define _JM}

uses
{$ifndef FPC}
  Winapi.Windows, Winapi.Messages,
  Midi,
{$else}
  Urtmidi,
{$endif}
  Forms, SyncObjs, SysUtils, Graphics, Controls, Dialogs,
  UInstrument, UMidiEvent, StdCtrls, UAmpel, Classes;

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
    cbxVirtual: TComboBox;
    gbInstrument: TGroupBox;
    Label13: TLabel;
    cbxTransInstrument: TComboBox;
    cbTransInstrument: TComboBox;
    Label1: TLabel;
    gbBalg: TGroupBox;
    cbxShiftIsPush: TCheckBox;
    Label2: TLabel;
    GroupBox1: TGroupBox;
    btnRecord: TButton;
    SaveDialog1: TSaveDialog;
    gbMidiInstrument: TGroupBox;
    Label3: TLabel;
    cbxMidiDiskant: TComboBox;
    Label4: TLabel;
    gbMidiBass: TGroupBox;
    Label5: TLabel;
    Label6: TLabel;
    cbxInstrBass: TComboBox;
    cbxBassDifferent: TCheckBox;
    Label7: TLabel;
    cbxBankBass: TComboBox;
    cbxDiskantBank: TComboBox;
    btnResetMidi: TButton;
    procedure cbTransInstrumentChange(Sender: TObject);
    procedure cbxMidiInputChange(Sender: TObject);
    procedure cbxTransInstrumentChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure cbxMidiOutChange(Sender: TObject);
    procedure btnResetMidiClick(Sender: TObject);
    procedure cbxVirtualChange(Sender: TObject);
    procedure cbxShiftIsPushClick(Sender: TObject);
    procedure cbxMidiDiskantChange(Sender: TObject);
    procedure cbTransInstrumentKeyPress(Sender: TObject; var Key: Char);
    procedure cbTransInstrumentKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbTransInstrumentKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnRecordClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbxBassDifferentClick(Sender: TObject);
    procedure cbxDiskantBankChange(Sender: TObject);
  private
    CriticalSendOut: TCriticalSection;
    TimeEventCount: cardinal;
    TimeEventArray: array of TMidiTimeEvent;
    procedure RegenerateMidi;
    procedure SendMidiOut(const aStatus, aData1, aData2: byte);
    procedure BankChange(cbx: TComboBox);
  public
    Instrument: TInstrument;
  end;

var
  frmVirtualHarmonica: TfrmVirtualHarmonica;

implementation

{$ifdef FPC}
  {$R *.lfm}
{$else}
  {$R *.dfm}
{$endif}

uses
{$ifndef FPC}
  UVirtual,
{$endif}
  UFormHelper, UGriffEvent, UMidiSaveStream, UBanks;

{$ifdef FPC}
const
  IDYES = 1;
{$endif}

procedure TfrmVirtualHarmonica.SendMidiOut(const aStatus, aData1, aData2: byte);
var
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
    gbMidiInstrument.Enabled := Ok;
    gbMidiBass.Enabled := Ok;
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
      TimeOffset := 0;
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
        Stream.AppendEvent($C0 + i, MidiInstrDiskant, 0); // Instrument
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
//  RegenerateMidi;
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
  Instrument := InstrumentsList_[index];
  cbxTransInstrumentChange(nil);

  frmAmpel.ChangeInstrument(@Instrument);
  if Sender <> nil then
    OpenMidiMicrosoft;
end;

procedure TfrmVirtualHarmonica.cbTransInstrumentKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if not (Key in [9, 13, 37..40]) then
  begin
    frmAmpel.FormKeyDown(Sender, Key, Shift);
    Key := 0;
  end;
end;

procedure TfrmVirtualHarmonica.cbTransInstrumentKeyPress(Sender: TObject;
  var Key: Char);
begin
  if (Key = #13) and (Sender is TCheckBox) then
    with Sender as TCheckBox do
      Checked := not Checked;
  Key := #0;
end;

procedure TfrmVirtualHarmonica.cbTransInstrumentKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if not (Key in [9, 13, 37..40]) then
  begin
    if not frmAmpel.IsActive then
    begin
      frmAmpel.Show;
    end;
    frmAmpel.FormKeyUp(Sender, Key, Shift);
    frmAmpel.SetFocus;
    Key := 0;
  end;
end;

procedure TfrmVirtualHarmonica.cbxMidiInputChange(Sender: TObject);
begin
  Sustain_:= false;
  MidiInput.CloseAll;
  if cbxMidiInput.ItemIndex > 0 then
    MidiInput.Open(cbxMidiInput.ItemIndex - 1);
end;

procedure TfrmVirtualHarmonica.cbxBassDifferentClick(Sender: TObject);
begin
  cbxBankBass.Enabled := cbxBassDifferent.Checked;
  cbxInstrBass.Enabled := cbxBassDifferent.Checked;
  BassBankActiv := cbxBassDifferent.Checked;

  cbxMidiDiskantChange(Sender);
end;

  function GetIndex(cbxMidi: TComboBox): integer;
  var
    s: string;
  begin
    if cbxMidi.ItemIndex < 0 then
      cbxMidi.ItemIndex := 0;
    s := cbxMidi.Text;
    if Pos(' ', s) > 0 then
      s := Copy(s, 1,Pos(' ', s));
    result := StrToIntDef(trim(s), 0);
  end;

procedure TfrmVirtualHarmonica.BankChange(cbx: TComboBox);
var
  Bank: TArrayOfString;
  i, Index: integer;
begin
  Index := GetIndex(cbx);
  GetBank(Bank, Index);
  if cbx = cbxDiskantBank then
    cbx := cbxMidiDiskant
  else
    cbx := cbxInstrBass;

  cbx.Items.Clear;
  for i := low(Bank) to high(Bank) do
    if Bank[i] <> '' then
      cbx.Items.Add(Bank[i]);
  cbx.ItemIndex := 0;
end;

procedure TfrmVirtualHarmonica.cbxDiskantBankChange(Sender: TObject);
begin
  BankChange(Sender as TComboBox);
  cbxMidiDiskantChange(Sender);
end;

procedure TfrmVirtualHarmonica.cbxMidiDiskantChange(Sender: TObject);
begin
  MidiBankDiskant := GetIndex(cbxDiskantBank);
  MidiInstrDiskant := GetIndex(cbxMidiDiskant);
  if not cbxBassDifferent.Checked then
  begin
    MidiInstrBass := MidiInstrDiskant;
    MidiBankBass := MidiBankDiskant;
  end else begin
    MidiBankBass := GetIndex(cbxBankBass);
    MidiInstrBass := GetIndex(cbxInstrBass);
  end;
  if Sender <> nil then
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
{$ifdef FPC}
    MidiVirtual.Close(iVirtualMidi);
{$else}
    MidiOutput.Close(iVirtualMidi);
{$endif}
  iVirtualMidi := CbxVirtual.ItemIndex - 1;
  if cbxMidiOut.ItemIndex = iVirtualMidi then
  begin
    iVirtualMidi := -1;
    CbxVirtual.ItemIndex := 0;
  end;
  if iVirtualMidi >= 0 then
{$ifdef FPC}
    MidiVirtual.Open(iVirtualMidi);
{$else}
    MidiOutput.Open(iVirtualMidi);
{$endif}
end;

procedure TfrmVirtualHarmonica.cbxShiftIsPushClick(Sender: TObject);
begin
  shiftIsPush := cbxShiftIsPush.Checked;
  frmAmpel.PaintBalg(ShiftUsed);
end;

procedure TfrmVirtualHarmonica.FormCreate(Sender: TObject);
var
  i: integer;
  Bank: TArrayOfString;
begin
{$if defined(CPUX86_64) or defined(WIN64)}
  Caption := Caption + ' (64)';
{$else}
  Caption := Caption + ' (32)';
{$endif}
  SetLength(TimeEventArray, 100000);
  TimeEventCount := 0;

  cbTransInstrument.Items.Clear;
  for i := 0 to High(InstrumentsList_) do
    cbTransInstrument.Items.Add(string(InstrumentsList_[i].Name));
{$ifndef FPC}
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
{$endif}
  CriticalSendOut := TCriticalSection.Create;
  CopyBank(Bank, @bank_list);
  cbxDiskantBank.Items.Clear;
  for i := low(Bank) to high(Bank) do
    if Bank[i] <> '' then
      cbxDiskantBank.Items.Add(Bank[i]);
  cbxBankBass.Items := cbxDiskantBank.Items;
{$ifdef JM}
  cbxDiskantBank.ItemIndex := 25;
  cbxBankBass.ItemIndex := 25;
{$else}
  cbxDiskantBank.ItemIndex := 0;
  cbxBankBass.ItemIndex := 0;
{$endif}

  BankChange(cbxDiskantBank);
  BankChange(cbxBankBass);

{$ifdef JM}
  cbxMidiDiskant.ItemIndex := 9;
  cbxInstrBass.ItemIndex := 9;
{$else}
  cbxMidiDiskant.ItemIndex := 21;
  cbxInstrBass.ItemIndex := 21;
{$endif}
  cbxMidiDiskantChange(nil);
end;

procedure TfrmVirtualHarmonica.FormDestroy(Sender: TObject);
begin
  MidiInput.CloseAll;
  SetLength(TimeEventArray, 0);
  CriticalSendOut.Free;
end;

procedure TfrmVirtualHarmonica.FormShow(Sender: TObject);

  function GetIndex(cbx: TComboBox; const str: string): integer;
  var
    k: integer;
  begin
    result := -1;
    for k := 0 to cbx.items.Count-1 do
      if Pos(str, cbx.Items[k]) > 0 then
      begin
        result := k;
        cbx.ItemIndex := k;
        cbx.OnChange(nil);
      end;
  end;

begin
  GetIndex(cbTransInstrument, 'Steirische ADGC');

  RegenerateMidi;
  MidiInput.OnMidiData := frmAmpel.OnMidiInData;

//{$ifdef JM}
  GetIndex(cbxMidiInput, 'Mobile Keys 49');
  GetIndex(cbxMidiOut, 'UM-ONE');
//{$endif}

  frmAmpel.ChangeInstrument(@Instrument);
  frmAmpel.Show;
end;

{$ifdef FPC}
procedure InsertList(Combo: TComboBox; const arr: array of string);
var
  i: integer;
begin
  for i := 0 to Length(arr)-1 do
    Combo.AddItem(arr[i], nil);
end;
{$else}
procedure InsertList(Combo: TComboBox; arr: TStringList);
var
  i: integer;
begin
  for i := 0 to arr.Count-1 do
    Combo.AddItem(arr[i], nil);
end;
{$endif}

procedure TfrmVirtualHarmonica.RegenerateMidi;
begin
  MidiOutput.GenerateList;
  MidiInput.GenerateList;

  InsertList(cbxMidiOut, MidiOutput.DeviceNames);
  cbxMidiOut.Items.Insert(0, '');
  OpenMidiMicrosoft;
  cbxMidiOut.ItemIndex := MicrosoftIndex + 1;
{$ifdef FPC}
  cbxMidiInput.Visible := Length(MidiInput.DeviceNames) > 0;
{$else}
  cbxMidiInput.Visible := MidiInput.DeviceNames.Count > 0;
{$endif}
  lblKeyboard.Visible := cbxMidiInput.Visible;
  if cbxMidiInput.Visible then
  begin
    InsertList(cbxMidiInput, MidiInput.DeviceNames);
    cbxMidiInput.Items.Insert(0, '');
    cbxMidiInput.ItemIndex := 0;
    cbxMidiInputChange(nil);
  end;

  cbxVirtual.Items.Clear;
  InsertList(cbxVirtual, MidiOutput.DeviceNames);
  cbxVirtual.Items.Insert(0, '');
  cbxVirtual.ItemIndex := 0;
end;


end.
