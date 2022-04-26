unit UVirtualHarmonica;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  UInstrument;

type
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
  private
    procedure MessageEvent(var Msg: TMsg; var Handled: Boolean);
    procedure RegenerateMidi;
  public
    Instrument: TInstrument;
  end;

var
  frmVirtualHarmonica: TfrmVirtualHarmonica;

implementation

{$R *.dfm}

uses
  UAmpel, Midi, UVirtual, UMidiDataStream, UFormHelper, UGriffEvent;

procedure TfrmVirtualHarmonica.MessageEvent(var Msg: TMsg; var Handled: Boolean);
begin
  if ((Msg.message = WM_KEYDOWN) or (Msg.message = WM_KEYUP)) then
  begin
    //writeln(Msg.wParam, '  ', IntToHex(Msg.lParam));
    if frmAmpel.IsActive then
    begin
      if (Msg.lParam and $fff0000) = $0150000 then    // Z
        Msg.wParam := 90;
      if (Msg.lParam and $fff0000) = $02c0000 then    // Y
        Msg.wParam := 89;
      // 4. Reihe ' ^
      if (Msg.lParam and $fff0000) = $00c0000 then
        Msg.wParam := 219;
      if (Msg.lParam and $fff0000) = $00d0000 then
        Msg.wParam := 221;
      // 3. Reihe ü ¨
      if RunningWine then
      begin
        if (Msg.lParam and $fff0000) = $0600000 then
          Msg.wParam := 186;
      end else
      if (Msg.lParam and $fff0000) = $01a0000 then
        Msg.wParam := 186;
      if (Msg.lParam and $fff0000) = $01b0000 then
        Msg.wParam := 192;
      // 2. Reihe ö ä $
      if (Msg.lParam and $fff0000) = $0270000 then
        Msg.wParam := 222;
      if (Msg.lParam and $fff0000) = $0280000 then
        Msg.wParam := 220;
      if (Msg.lParam and $fff0000) = $02b0000 then
        Msg.wParam := 223;
      // 1. Reihe , . -
      if (Msg.lParam and $fff0000) = $0330000 then
        Msg.wParam := 188;
      if (Msg.lParam and $fff0000) = $0340000 then
        Msg.wParam := 190;
      if (Msg.lParam and $fff0000) = $0350000 then
        Msg.wParam := 189;
      if (Msg.lParam and $fff0000) = $0560000 then
        Msg.wParam := 226;
    end;
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
  cbTransInstrument.Items.Clear;
  for i := 0 to High(InstrumentsList) do
    cbTransInstrument.Items.Add(string(InstrumentsList[i].Name));
{$if defined(CONSOLE)}
  if not RunningWine then
    ShowWindow(GetConsoleWindow, SW_SHOWMINIMIZED);
  SetConsoleTitle('VirtualHarmonica - Trace Window');
{$endif}
  Application.OnMessage := MessageEvent;

  UVirtual.LoopbackName := 'VirtualHarmonica loopback';
  InstallLoopback;
  Sleep(10);
  Application.ProcessMessages;
end;

procedure TfrmVirtualHarmonica.FormShow(Sender: TObject);
var
  i: integer;
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
