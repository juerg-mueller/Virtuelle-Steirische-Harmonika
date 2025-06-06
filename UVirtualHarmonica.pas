﻿unit UVirtualHarmonica;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

{$define _JM}

uses
{$ifdef mswindows}
  {$ifndef FPC}
    Winapi.Windows, Winapi.Messages, Vcl.ExtCtrls,
  {$endif}
  Midi,
{$else}
  Urtmidi,
{$endif}
  UMidi, UMidiDataIn,
  Forms, SyncObjs, SysUtils, Graphics, Controls, Dialogs,
  UInstrument, UMidiEvent, StdCtrls, UAmpel, Classes;

type
  TRecordEventArray = record
    TimeStamp: TDateTime;
    MidiEvent: TMidiEvent;
  end;

  { TfrmVirtualHarmonica }

  TfrmVirtualHarmonica = class(TForm)
    gbMidi: TGroupBox;
    lblKeyboard: TLabel;
    Label17: TLabel;
    cbxMidiOut: TComboBox;
    cbxMidiInput: TComboBox;
    gbInstrument: TGroupBox;
    cbTransInstrument: TComboBox;
    Label1: TLabel;
    gbRecord: TGroupBox;
    btnRecordIn: TButton;
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
    sbVolDiscant: TScrollBar;
    lbVolDiskant: TLabel;
    lbVolBass: TLabel;
    sbVolBass: TScrollBar;
    btnReset: TButton;
    btnRecordOut: TButton;
    btnResetMidi: TButton;
    gbHeader: TGroupBox;
    Label8: TLabel;
    Label12: TLabel;
    cbxViertel: TComboBox;
    cbxTakt: TComboBox;
    edtBPM: TEdit;
    cbxMetronom: TCheckBox;
    Label2: TLabel;
    sbMetronom: TScrollBar;
    lbBegleitung: TLabel;
    cbxNurTakt: TCheckBox;
    Label10: TLabel;
    cbxOhneBlinker: TCheckBox;
    Label11: TLabel;
    cbxLimex: TComboBox;
    Label13: TLabel;
    procedure cbTransInstrumentChange(Sender: TObject);
    procedure cbxLimexChange(Sender: TObject);
    procedure cbxMidiInputChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure cbxMidiOutChange(Sender: TObject);
    procedure btnResetMidiClick(Sender: TObject);
    procedure cbxMidiDiskantChange(Sender: TObject);
    procedure cbTransInstrumentKeyPress(Sender: TObject; var Key: Char);
    procedure cbTransInstrumentKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbTransInstrumentKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnRecordInClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbxBassDifferentClick(Sender: TObject);
    procedure cbxDiskantBankChange(Sender: TObject);
    procedure sbVolChange(Sender: TObject);
    procedure cbAccordionMasterClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnRecordOutClick(Sender: TObject);
    procedure cbxMetronomClick(Sender: TObject);
    procedure cbxTaktChange(Sender: TObject);
    procedure cbxViertelChange(Sender: TObject);
    procedure edtBPMExit(Sender: TObject);
    procedure cbxNurTaktClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure edtBPMKeyPress(Sender: TObject; var Key: Char);
    procedure cbxOhneBlinkerClick(Sender: TObject);
    procedure cbxLimexClick(Sender: TObject);
  private

    procedure RegenerateMidi;
    procedure BankChange(cbx: TComboBox);
    procedure SaveMidi;
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
  UFormHelper, UBanks, UMidiDataStream;

{$ifdef FPC}
const
  IDYES = 1;
{$endif}


procedure TfrmVirtualHarmonica.btnRecordInClick(Sender: TObject);

  procedure Deactivate(Ok: boolean);
  begin
    gbInstrument.Enabled := Ok;
    gbMidi.Enabled := Ok;
    gbMidiInstrument.Enabled := Ok;
    gbMidiBass.Enabled := Ok;
    cbxMidiInput.Enabled := Ok;
  end;
var
  j: integer;
begin
  if cbxMidiInput.ItemIndex < 1 then
  begin
    Application.MessageBox('Bitte, wählen Sie einen Midi Input!', 'Fehler');
  end else
  if btnRecordIn.Caption <> 'Stopp' then
  begin
    Deactivate(false);
    InRecorder.Start;
    InRecord := true;
    btnRecordIn.Caption := 'Stopp';
  end else begin
    InRecord := false;
    InRecorder.Stop;

    for j := 0 to 9 do
      SendMidi($B0 + j, 120, 0);
    MidiOutput.Reset;
    SaveMidi;
    btnRecordIn.Caption := 'MIDI IN Aufnahme starten';
    Deactivate(true);
  end;
end;

procedure TfrmVirtualHarmonica.SaveMidi;
var
  name: string;
  SaveStream: TMidiSaveStream;
  Simple: TSimpleDataStream;
  i: integer;
begin
  SaveStream := InRecorder.MakeRecordStream(frmAmpel.Header);
  if SaveStream <> nil then
  begin
    name := 'midi_rekorder';
    if FileExists(name+'.mid') then
    begin
      name := name + '_';
      i := 1;
      while FileExists(name + IntToStr(i) + '.mid', false) do
        inc(i);
      name := name + IntToStr(i);
    end;
    SaveStream.SaveToFile(name+'.mid');
    Simple := TSimpleDataStream.MakeSimpleDataStream(SaveStream);
    if Simple <> nil then
    begin
      Simple.SaveToFile(name + '.mid.txt');
      Simple.Free;
    end;
  {$ifdef FPC}
    Application.MessageBox(PChar(name + ' gespeichert'), '');
  {$else}
    Application.MessageBox(PWideChar(name + ' gespeichert'), '');
  {$endif}
    SaveStream.Free;
  end;
end;

procedure TfrmVirtualHarmonica.btnRecordOutClick(Sender: TObject);

  procedure Deactivate(Ok: boolean);
  begin
    gbInstrument.Enabled := Ok;
    gbMidi.Enabled := Ok;
    gbMidiInstrument.Enabled := Ok;
    gbMidiBass.Enabled := Ok;
    cbxMidiOut.Enabled := Ok;
  end;

begin
  if btnRecordOut.Caption <> 'Stopp' then
  begin
    Deactivate(false);
//    MidiRecOut := TMidiRecord.Create(string(Instrument.Name), ShiftUsed);
//    MidiRecOut.Header := frmAmpel.Header;
//    frmAmpel.AmpelEvents.PRecordMidiOut := MidiRecOut.OnMidiInData;
    btnRecordOut.Caption := 'Stopp';
  end else begin
    frmAmpel.AmpelEvents.PRecordMidiOut := nil;

//    if (MicrosoftIndex >= 0) and MidiRecOut.hasOns then
//      ResetMidiOut;

//    SaveMidi(MidiRecOut);
    btnRecordOut.Caption := 'MIDI OUT Aufnahme starten';
    Deactivate(true);
  end;
end;

procedure TfrmVirtualHarmonica.btnResetClick(Sender: TObject);
begin
  ResetMidiOut;
  frmAmpel.AmpelEvents.AllEventsOff;
end;

procedure TfrmVirtualHarmonica.btnResetMidiClick(Sender: TObject);
var
  sIn, sOut: string;
  i: integer;
begin
  sIn := cbxMidiInput.Text;
  sOut := cbxMidiOut.Text;
  ResetMidiOut;
  RegenerateMidi;
  if sIn <> cbxMidiInput.Text then
  begin
    i := cbxMidiInput.Items.IndexOf(sIn);
    if i >= 0 then
    begin
      cbxMidiInput.ItemIndex := i;
      cbxMidiInputChange(Sender);
    end;
  end;
  if sOut <> cbxMidiOut.Text then
  begin
    i := cbxMidiOut.Items.IndexOf(sOut);
    if i >= 0 then
    begin
      cbxMidiOut.ItemIndex := i;
      cbxMidiOutChange(Sender);
    end;
  end;
end;

procedure TfrmVirtualHarmonica.cbAccordionMasterClick(Sender: TObject);
begin
//  ChangeSzene(cbxScene.ItemIndex, cbAccordionMaster.Checked);
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

  frmAmpel.ChangeInstrument(@Instrument);
  if Sender <> nil then
    OpenMidiMicrosoft;

  if Pos('Oergeli', string(Instrument.Name)) > 0 then
    s := 'Virtuelles Aargauerörgeli'
  else
    s := 'Virtuelle Steirische Harmonika';
{$if defined(CPUX86_64) or defined(WIN64) or defined(darwin)}
  {$ifdef fpc}
    s := s + ' (Lazarus 64)';
  {$else}
    s := s + ' (64)';
  {$endif}
{$else}
  {$ifdef fpc}
    s := s + ' (Lazarus 32)';
  {$else}
    s := s + ' (32)';
  {$endif}
{$endif}
  Caption := s;
end;

procedure TfrmVirtualHarmonica.cbxLimexChange(Sender: TObject);
begin
  IsLimex := cbxLimex.ItemIndex = 1;
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

  btnRecordIn.Enabled := cbxMidiInput.ItemIndex > 0;
end;

procedure TfrmVirtualHarmonica.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := not InRecord;
end;

procedure TfrmVirtualHarmonica.cbxBassDifferentClick(Sender: TObject);
var
  Checked: boolean;
begin
  Checked := cbxBassDifferent.Checked;
  cbxBankBass.Enabled := Checked;
  cbxInstrBass.Enabled := Checked;
  if Checked then
    gbMidiInstrument.Caption := 'MIDI Diskant'
  else
    gbMidiInstrument.Caption := 'MIDI Instrument';

  cbxMidiDiskantChange(Sender);
end;

procedure TfrmVirtualHarmonica.cbxMetronomClick(Sender: TObject);
begin
  frmAmpel.Metronom.SetOn(cbxMetronom.Checked);
  if not frmAmpel.Metronom.On_ then
  begin
    SendMidi($80 + pipChannel, pipFirst, 64);
    SendMidi($80 + pipChannel, pipSecond, 64);
  end;
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
var
  i: integer;
begin
  BankChange(Sender as TComboBox);
  cbxMidiDiskantChange(Sender);

  if MidiBankDiskant > 0 then
  begin
    if pipChannel <> 10 then
    begin
     ChangeBank(MicrosoftIndex, 10, 21, 64);
      pipChannel := 10;
    end;
  end else begin
    if pipChannel <> 9 then
    begin
      ChangeBank(MicrosoftIndex, pipChannel, 0, 21);
      pipChannel := 9;
    end;
  end;

end;

procedure TfrmVirtualHarmonica.cbxLimexClick(Sender: TObject);
begin
  IsLimex := cbxLimex.ItemIndex = 1;
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
  {$ifdef mswindows}
      MicrosoftIndex := cbxMidiOut.ItemIndex-1
    else
      cbxMidiOut.ItemIndex := TrueMicrosoftIndex+1;
  {$else}
    MicrosoftIndex := cbxMidiOut.ItemIndex-1;
  {$endif}

    OpenMidiMicrosoft;
    frmAmpel.InitLastPush;
  end;
end;

procedure TfrmVirtualHarmonica.cbxNurTaktClick(Sender: TObject);
begin
  NurTakt := cbxNurTakt.Checked;
  if frmAmpel.Metronom.On_ and not NurTakt then
  begin
    SendMidi($80 + pipChannel, pipSecond, 64);
  end;
end;

procedure TfrmVirtualHarmonica.cbxOhneBlinkerClick(Sender: TObject);
begin
  OhneBlinker := cbxOhneBlinker.Checked;
end;

procedure TfrmVirtualHarmonica.cbxTaktChange(Sender: TObject);
begin
  frmAmpel.Header.measureFact := cbxTakt.ItemIndex + 2;
  MidiInBuffer.Header := frmAmpel.Header;
end;

procedure TfrmVirtualHarmonica.cbxViertelChange(Sender: TObject);
var
  q: integer;
begin
  case cbxViertel.ItemIndex of
    0: q := 4;
    1: q := 8;
    else q := 4;
  end;
  frmAmpel.Header.MeasureDiv :=  q;
  MidiInBuffer.Header := frmAmpel.Header;
end;

procedure TfrmVirtualHarmonica.edtBPMExit(Sender: TObject);
begin
  frmAmpel.Header.QuarterPerMin := StrToInt(edtBPM.Text);
  cbxViertelChange(Sender);
end;

procedure TfrmVirtualHarmonica.edtBPMKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    cbTransInstrument.SetFocus;
  end;
end;

procedure TfrmVirtualHarmonica.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin

  if btnRecordIn.Caption = 'Stopp' then
    Action := caNone;
end;

procedure TfrmVirtualHarmonica.FormCreate(Sender: TObject);
var
  i: integer;
  Bank: TArrayOfString;
begin
  InRecorder := TMidiEventRecorder.Create;
  cbTransInstrument.Items.Clear;
  for i := 0 to High(InstrumentsList_) do
    cbTransInstrument.Items.Add(string(InstrumentsList_[i].Name));
{$ifndef FPC}
{$if defined(CONSOLE)}
  //if not RunningWine then
  //  ShowWindow(GetConsoleWindow, SW_SHOWNORMAL);
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
  gbRecord.Visible := true;
{$endif}
{
  if not gbSzene.Visible then
    Height := Height - gbSzene.Height;
  if not gbRecord.Visible then
    Height := Height - gbRecord.Height;
}
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

  sbVolDiscant.Min := 20;
  sbVolBass.Min := 20;
  sbVolDiscant.Max := 140;
  sbVolBass.Max := 140;
  sbVolChange(sbVolDiscant);
  sbVolChange(sbVolBass);
  FormResize(self);
end;

procedure TfrmVirtualHarmonica.FormDestroy(Sender: TObject);
begin
  MidiInput.CloseAll;
  InRecorder.Free;
end;

procedure TfrmVirtualHarmonica.FormResize(Sender: TObject);
begin
  VertScrollBar.Visible := Height < VertScrollBar.Range;
{$ifndef FPC}
  if VertScrollBar.Visible then
    VertScrollBar.Size := Height;
{$endif}
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
  GetIndex(cbTransInstrument, 'b-Oergeli'); // 'BEsAsDes');

  RegenerateMidi;
  MidiInput.OnMidiData := frmAmpel.OnMidiInData;

  cbxTaktChange(nil);
  edtBPMExit(nil);
  frmAmpel.ChangeInstrument(@Instrument);
  frmAmpel.Show;
end;

procedure InsertList(Combo: TComboBox; const arr: array of string);
var
  i: integer;
begin
  for i := 0 to Length(arr)-1 do
    Combo.AddItem(arr[i], nil);
end;

procedure TfrmVirtualHarmonica.RegenerateMidi;
begin
  MidiOutput.GenerateList;
  MidiInput.GenerateList;

  cbxMidiOut.Clear;
  InsertList(cbxMidiOut, MidiOutput.DeviceNames);
  cbxMidiOut.Items.Insert(0, '');
  OpenMidiMicrosoft;
  cbxMidiOut.ItemIndex := MicrosoftIndex + 1;
  if cbxMidiInput.Visible then
  begin
    cbxMidiInput.Clear;
    InsertList(cbxMidiInput, MidiInput.DeviceNames);
    cbxMidiInput.Items.Insert(0, '');
    cbxMidiInput.ItemIndex := 0;
    cbxMidiInputChange(nil);
  end;
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
  end else
  if Sender = sbVolDiscant then begin
    lbVolDiskant.Caption := s;
    VolumeDiscant := p;
  end else
  if Sender = sbMetronom then begin
    lbBegleitung.Caption := s;
    VolumeMetronom := p;
  end;
end;

end.

