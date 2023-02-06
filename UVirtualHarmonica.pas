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
  UInstrument, UMidiEvent, StdCtrls, UAmpel, Classes,
  UMidiSaveStream;

type
  TRecordEventArray = record
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
    gbRecord: TGroupBox;
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
    Label8: TLabel;
    cbxUseBanks: TCheckBox;
    sbVolDiscant: TScrollBar;
    lbVolDiskant: TLabel;
    lbVolBass: TLabel;
    sbVolBass: TScrollBar;
    gbSzene: TGroupBox;
    cbxScene: TComboBox;
    Label9: TLabel;
    cbAccordionMaster: TCheckBox;
    btnReset: TButton;
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
    procedure sbVolChange(Sender: TObject);
    procedure cbAccordionMasterClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private

    procedure RegenerateMidi;
    procedure BankChange(cbx: TComboBox);
  public
    MidiRec: TMidiRecord;
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
  UFormHelper, UGriffEvent, UBanks;

{$ifdef FPC}
const
  IDYES = 1;
{$endif}

procedure TfrmVirtualHarmonica.btnRecordClick(Sender: TObject);

  procedure Deactivate(Ok: boolean);
  begin
    gbInstrument.Enabled := Ok;
    gbMidi.Enabled := Ok;
    gbBalg.Enabled := Ok;
    gbMidiInstrument.Enabled := Ok;
    gbMidiBass.Enabled := Ok;
    gbSzene.Enabled := Ok;
    cbxMidiInput.Enabled := Ok;
  end;

var
  i: integer;
  SaveStream: TMidiSaveStream;
  Saved: boolean;
  p: pointer;
begin
  if btnRecord.Caption <> 'Stopp' then
  begin
    Deactivate(false);
    MidiRec := TMidiRecord.Create;
    frmAmpel.PRecordMidiIn := MidiRec.OnMidiInData;
    btnRecord.Caption := 'Stopp';
  end else begin
    frmAmpel.PRecordMidiIn := nil;

    if (MicrosoftIndex >= 0) and MidiRec.hasOns then
      ResetMidiOut;

    SaveStream := TMidiSaveStream.BuildSaveStream(MidiRec);
    FreeAndNil(MidiRec);
    if SaveStream <> nil then
    begin
      while not Saved and SaveDialog1.Execute do
      begin
        if not FileExists(SaveDialog1.FileName) or
          (Warning('Datei existiert bereits! Überschreiben?') = IDYES) then
        begin
          SaveStream.SaveToFile(SaveDialog1.FileName);
          Saved := true;
        end;
      end;
      SaveStream.Free;
    end;
    btnRecord.Caption := 'MIDI IN Aufnahme starten';
    Deactivate(true);
  end;
end;

procedure TfrmVirtualHarmonica.btnResetClick(Sender: TObject);
begin
  ResetMidiOut;
  frmAmpel.AmpelEvents.AllEventsOff;
end;

procedure TfrmVirtualHarmonica.btnResetMidiClick(Sender: TObject);
begin
//  ResetMidi;
//  RegenerateMidi;
end;

procedure TfrmVirtualHarmonica.cbAccordionMasterClick(Sender: TObject);
begin
  ChangeSzene(cbxScene.ItemIndex, cbAccordionMaster.Checked);
end;

procedure TfrmVirtualHarmonica.cbTransInstrumentChange(Sender: TObject);
var
  s: string;
  index: integer;
  isOergeli: boolean;
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

  if Pos('Oergeli', string(Instrument.Name)) > 0 then
    s := 'Virtuelles Aargauerörgeli'
  else
    s := 'Virtuelle Steirische Harmonika';
{$if defined(CPUX86_64) or defined(WIN64)}
  s := s + ' (64)';
{$else}
  s := s + ' (32)';
{$endif}
  Caption := s;
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
var
  Checked: boolean;
begin
  Checked := cbxBassDifferent.Checked;
  cbxBankBass.Enabled := Checked;
  cbxInstrBass.Enabled := Checked;
  BassBankActiv := Checked;
  if Checked then
    gbMidiInstrument.Caption := 'MIDI Diskant'
  else
    gbMidiInstrument.Caption := 'MIDI Instrument';

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

procedure TfrmVirtualHarmonica.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if btnRecord.Caption = 'Stop' then
    Action := caNone;
end;

procedure TfrmVirtualHarmonica.FormCreate(Sender: TObject);
var
  i: integer;
  Bank: TArrayOfString;
begin
  MidiRec := nil;
  cbTransInstrument.Items.Clear;
  for i := 0 to High(InstrumentsList_) do
    cbTransInstrument.Items.Add(string(InstrumentsList_[i].Name));
{$ifndef FPC}
{$if defined(CONSOLE)}
  //if not RunningWine then
    ShowWindow(GetConsoleWindow, SW_SHOWNORMAL);
  SetConsoleTitle('VirtualHarmonica - Trace Window');
{$endif}
  Application.OnMessage := frmAmpel.KeyMessageEvent;

  UVirtual.LoopbackName := 'VirtualHarmonica loopback';
  InstallLoopback;
  Sleep(10);
  Application.ProcessMessages;
{$endif}
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
  gbSzene.Visible := false;
  gbBalg.Visible := false;
  gbRecord.Visible := true;
{$endif}

  if not gbSzene.Visible then
    Height := Height - gbSzene.Height;
  if not gbBalg.Visible then
    Height := Height - gbBalg.Height;
  if not gbRecord.Visible then
    Height := Height - gbRecord.Height;

  BankChange(cbxDiskantBank);
  BankChange(cbxBankBass);

{$ifdef JM}
  cbxMidiDiskant.ItemIndex := 9;
  cbxInstrBass.ItemIndex := 45;
{$else}
  cbxMidiDiskant.ItemIndex := 21;
  cbxInstrBass.ItemIndex := 21;
{$endif}
  cbxMidiDiskantChange(nil);
  SaveDialog1.InitialDir := ExtractFilePath(ParamStr(0));

  sbVolChange(sbVolDiscant);
  sbVolChange(sbVolBass);
end;

procedure TfrmVirtualHarmonica.FormDestroy(Sender: TObject);
begin
  MidiInput.CloseAll;
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
  GetIndex(cbTransInstrument, 'BEsAsDes');  // 'b-Oergeli');

  RegenerateMidi;
  MidiInput.OnMidiData := frmAmpel.OnMidiInData;

{$ifdef JM}
  cbxBassDifferent.Checked := true;
  GetIndex(cbxMidiInput, 'Mobile Keys 49');
  GetIndex(cbxMidiOut, 'UM-ONE');
{$endif}
//  cbAccordionMasterClick(nil);

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


procedure TfrmVirtualHarmonica.sbVolChange(Sender: TObject);
var
  s: string;
  p: double;
begin
  with Sender as TScrollBar do
  begin
    s := Format('Lautstärke  (%d %%)', [Position]);
    p := Position / 100.0;
  end;
  if Sender = sbVolBass then
  begin
    lbVolBass.Caption := s;
    VolumeBass := p;
  end else begin
    lbVolDiskant.Caption := s;
    VolumeDiscant := p;
  end;

end;

end.

