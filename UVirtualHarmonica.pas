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
    gbSzene: TGroupBox;
    cbxScene: TComboBox;
    Label9: TLabel;
    cbAccordionMaster: TCheckBox;
    btnReset: TButton;
    btnRecordOut: TButton;
    btnResetMidi: TButton;
    gbHeader: TGroupBox;
    Label8: TLabel;
    Label12: TLabel;
    cbxViertel: TComboBox;
    cbxTakt: TComboBox;
    edtBPM: TEdit;
    cbxBegleitung: TCheckBox;
    Label2: TLabel;
    sbBegleitung: TScrollBar;
    lbBegleitung: TLabel;
    cbxNurTakt: TCheckBox;
    Label10: TLabel;
    procedure cbTransInstrumentChange(Sender: TObject);
    procedure cbxMidiInputChange(Sender: TObject);
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
    procedure cbxBegleitungClick(Sender: TObject);
    procedure cbxTaktChange(Sender: TObject);
    procedure cbxViertelChange(Sender: TObject);
    procedure edtBPMExit(Sender: TObject);
    procedure cbxNurTaktClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private

    procedure RegenerateMidi;
    procedure BankChange(cbx: TComboBox);
    procedure SaveMidi(var MidiRec: TMidiRecord);
  public
    MidiRecIn: TMidiRecord;
    MidiRecOut: TMidiRecord;
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

procedure TfrmVirtualHarmonica.btnRecordInClick(Sender: TObject);

  procedure Deactivate(Ok: boolean);
  begin
    gbInstrument.Enabled := Ok;
    gbMidi.Enabled := Ok;
    gbMidiInstrument.Enabled := Ok;
    gbMidiBass.Enabled := Ok;
    gbSzene.Enabled := Ok;
    cbxMidiInput.Enabled := Ok;
  end;

begin
  if btnRecordIn.Caption <> 'Stopp' then
  begin
    Deactivate(false);
    MidiRecIn := TMidiRecord.Create(string(Instrument.Name));
    MidiRecIn.Header := frmAmpel.Header;
    frmAmpel.PRecordMidiIn := MidiRecIn.OnMidiInData;
    btnRecordIn.Caption := 'Stopp';
  end else begin
    frmAmpel.PRecordMidiIn := nil;

    if (MicrosoftIndex >= 0) and MidiRecIn.hasOns then
      ResetMidiOut;

    SaveMidi(MidiRecIn);
    btnRecordIn.Caption := 'MIDI IN Aufnahme starten';
    Deactivate(true);
  end;
end;

procedure TfrmVirtualHarmonica.SaveMidi(var MidiRec: TMidiRecord);
var
  Saved: boolean;
  s: string;
  SaveStream: TMidiSaveStream;
begin
  Saved := false;
  SaveStream := TMidiSaveStream.BuildSaveStream(MidiRec);
  FreeAndNil(MidiRec);
  if SaveStream <> nil then
  begin
    while not Saved and SaveDialog1.Execute do
    begin
      s := SaveDialog1.FileName;
      if ExtractFileExt(s) <> '.mid' then
        s := s + '.mid';
      if not FileExists(s) or
        (Warning('Eine Datei mit diesem Namen existiert bereits! Überschreiben?') = IDYES) then
      begin

        SaveStream.SaveToFile(s);
        Saved := true;
      end;
    end;
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
    gbSzene.Enabled := Ok;
    cbxMidiOut.Enabled := Ok;
  end;

begin
  if btnRecordOut.Caption <> 'Stopp' then
  begin
    Deactivate(false);
    MidiRecOut := TMidiRecord.Create(string(Instrument.Name));
    MidiRecOut.Header := frmAmpel.Header;
    frmAmpel.AmpelEvents.PRecordMidiOut := MidiRecOut.OnMidiInData;
    btnRecordOut.Caption := 'Stopp';
  end else begin
    frmAmpel.AmpelEvents.PRecordMidiOut := nil;

    if (MicrosoftIndex >= 0) and MidiRecOut.hasOns then
      ResetMidiOut;

    SaveMidi(MidiRecOut);
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
begin
  ResetMidiOut;
  RegenerateMidi;
end;

procedure TfrmVirtualHarmonica.cbAccordionMasterClick(Sender: TObject);
begin
  ChangeSzene(cbxScene.ItemIndex, cbAccordionMaster.Checked);
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
{$if defined(CPUX86_64) or defined(WIN64)}
//  s := s + ' (64)';
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

  btnRecordIn.Enabled := cbxMidiInput.ItemIndex > 0;
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

procedure TfrmVirtualHarmonica.cbxBegleitungClick(Sender: TObject);
begin
  frmAmpel.Begleitung := cbxBegleitung.Checked;
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

procedure TfrmVirtualHarmonica.cbxNurTaktClick(Sender: TObject);
begin
  NurTakt := cbxNurTakt.Checked;
end;

procedure TfrmVirtualHarmonica.cbxTaktChange(Sender: TObject);
begin
  frmAmpel.Header.measureFact := cbxTakt.ItemIndex + 2;
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
end;

procedure TfrmVirtualHarmonica.edtBPMExit(Sender: TObject);
begin
  frmAmpel.Header.beatsPerMin := StrToInt(edtBPM.Text);
  cbxViertelChange(Sender);
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
  MidiRecIn := nil;
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
  gbSzene.Visible := false;
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
end;

procedure TfrmVirtualHarmonica.FormDestroy(Sender: TObject);
begin
  MidiInput.CloseAll;
end;

procedure TfrmVirtualHarmonica.FormResize(Sender: TObject);
begin
  VertScrollBar.Visible := Height < VertScrollBar.Range;
  if VertScrollBar.Visible then
    VertScrollBar.Size := Height;
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
  GetIndex(cbTransInstrument, 'b-Oergeli'); //    'BEsAsDes');

  RegenerateMidi;
  MidiInput.OnMidiData := frmAmpel.OnMidiInData;

{$ifdef JM}
  cbxBassDifferent.Checked := true;
  GetIndex(cbxMidiInput, 'Mobile Keys 49');
  GetIndex(cbxMidiOut, 'UM-ONE');
{$endif}
//  cbAccordionMasterClick(nil);

  cbxTaktChange(nil);
  edtBPMExit(nil);
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

  cbxMidiOut.Clear;
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
  if Sender = sbBegleitung then begin
    lbBegleitung.Caption := s;
    VolumeBegleitung := p;
  end;


end;

end.

