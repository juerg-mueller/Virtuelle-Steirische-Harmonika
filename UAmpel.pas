//
// Copyright (C) 2022 Jürg Müller, CH-5524
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program. If not, see http://www.gnu.org/licenses/ .
//

// Zusatzinformationen, welche im Synthesizer-Midi-Kanal mitgeliefert werden.
// ==========================================================================
//
// Midi-Balg-Information, wird bei jedem Wechsel ausgegeben:
//   B7 1f 00/01    01 für Push; 00 für Pull
//
// Die Tastatur-Spalten werden je einem eigenen Midi-Kanal zugewiesen.
//   91 nn xx  für die äusserste Diskant-Spalte
//   ..
//   96 nn xx  Für die äusserste Bass-Spalte
//
//
// Tastatureingabe
// ===============
//
// Mit der Tastatur (Buchstaben, Zahlen und Sonderzeichen) wird die Diskantseite
// der Steirischen Harmonika abgebildet. Der Gleichton (mit Kreuz markiert) ist die H-Taste.
//
// F5 bis F12 wird für die Bässe verwendet.
// Mit Ctrl schaltet man von der äusseren Bassreihe auf die innere.
//
// Mit der Shift-Taste ändert man die Balgbewegung.
//
unit UAmpel;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Touch.GestureMgr, SyncObjs, UITypes,
  UInstrument, UGriffEvent, Menus, Midi;

type
  TSoundGriff = procedure (Row: byte; index: byte; Push: boolean; On_:boolean) of object;
  TSendMidiOut = procedure (const aStatus, aData1, aData2: byte) of object;


  TMouseEvent = record
    P: TPoint;
    Pitch: byte;
    Row_, Index_: integer;
    Push_: boolean;
    Key: word;

    procedure Clear;
    function NewPushForPitch(NewPush: boolean): boolean;
  end;

  TfrmAmpel = class;

  TLastPush = (unknown, LastPush_, LastPull_);
  TAmpelEvents = class
  private
    frmAmpel: TfrmAmpel;
    CriticalAmpel: TCriticalSection;
    MouseEvents: array [0..10] of TMouseEvent;
    FUsedEvents: integer;
    LastPush: TLastPush;

    procedure DoAmpel(Index: integer; On_: boolean);
    procedure SendPush(Push: boolean);
  public
    PSendMidiOut: TSendMidiOut;

    constructor Create(Ampel: TfrmAmpel);
    destructor Destroy; override;
    procedure NewPush(Push, Ctrl: boolean);
    procedure NewEvent(const Event: TMouseEvent);
    procedure EventOff(const Event: TMouseEvent);
    procedure GetKeyEvent(Key: integer; var Event: TMouseEvent);
    procedure CheckMovePoint(const P: TPoint; Down: boolean);
    procedure InitLastPush;
    procedure SendMidiOut(const aStatus, aData1, aData2: byte);

    property UsedEvents : integer read FUsedEvents;
  end;


  PPlayControl = function(CharCode: word; KeyData: Longint): boolean of object;

  PKeyDown = procedure (Sender: TObject; var Key: Word; Shift: TShiftState) of object;

  TfrmAmpel = class(TForm)
    btnFlip: TButton;
    btnFlipHorz: TButton;
    lbUnten: TLabel;
    cbxLinkshaender: TCheckBox;
    cbxVerkehrt: TCheckBox;
    lbTastatur: TLabel;
    procedure FormPaint(Sender: TObject);
    procedure btnFlipClick(Sender: TObject);
    procedure btnFlipHorzClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure cbSizeChange(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure cbxLinkshaenderClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
    CriticalMidiIn: TCriticalSection;
    function MakeMouseDown(const P: TPoint; Push: boolean): TMouseEvent;
    function FlippedHorz: boolean;
  public
    Instrument: PInstrument;
    AmpelEvents: TAmpelEvents;
    FlippedVert: boolean;
    FlippedHorz_: boolean;
    //SoundGriff: TSoundGriff;
    SelectedChanges: PSelectedProc;
    KnopfGroesse: integer;
    MinIndex, MaxIndex: integer;
    PlayControl: PPlayControl;
    KeyDown: PKeyDown;
    IsActive: boolean;

    procedure ChangeInstrument(Instrument_: PInstrument);
    function KnopfRect(Row: byte {1..6}; index: byte {0..10}): TRect;
    procedure PaintAmpel(Row: byte {1..6}; index: integer {0..10}; Push, On_: boolean);
    function GetKeyIndex(var Event: TMouseEvent; Key: word): boolean;
    procedure InitLastPush;
    procedure KeyMessageEvent(var Msg: TMsg; var Handled: Boolean);
    procedure OnMidiInData(aDeviceIndex: integer; aStatus, aData1, aData2: byte; Timestamp: integer);
  end;

  TKeys = array [0..11] of AnsiChar;
  TTastKeys = array [1..4] of TKeys;

const
  TastKeys: TTastKeys =
    (( #226,'Y','X','C','V','B','N','M',#188,#190,#189,#0), // ','
     ( 'A','S','D','F','G','H','J','K','L',#222,#220,#223),   // Ö  Ä
     ( 'Q', 'W','E','R','T','Z','U','I','O','P',#186,#192), // Ü
     ( '2','3','4','5','6','7','8','9','0',#219,#221, #0)
    );

var
  frmAmpel: TfrmAmpel;

implementation

{$R *.dfm}

uses
{$ifndef __VIRTUAL__}
  UfrmGriff,
{$endif}
  UFormHelper, UMidiEvent;

procedure TMouseEvent.Clear;
begin
  P.X := -1;
  P.Y := -1;
  Row_ := 0;
  Index_ := -1;
  Key := 0;
  Pitch := 0;
end;

function TMouseEvent.NewPushForPitch(NewPush: boolean): boolean;
begin
  result := false;
end;

constructor TAmpelEvents.Create(Ampel: TfrmAmpel);
begin
  frmAmpel := Ampel;
  CriticalAmpel := TCriticalSection.Create;
  FUsedEvents := 0;
  LastPush := unknown;
end;

destructor TAmpelEvents.Destroy;
begin
  CriticalAmpel.Free;

  inherited;
end;

procedure TAmpelEvents.InitLastPush;
begin
  LastPush := unknown;
end;

procedure TfrmAmpel.InitLastPush;
begin
  AmpelEvents.InitLastPush;
end;

procedure TAmpelEvents.SendMidiOut(const aStatus, aData1, aData2: byte);
begin
  if (MicrosoftIndex >= 0) then
    MidiOutput.Send(MicrosoftIndex, aStatus, aData1, aData2);
  if @PSendMidiOut <> nil then
    PSendMidiOut(aStatus, aData1, aData2);
end;


procedure TAmpelEvents.SendPush(Push: boolean);
begin
  if (LastPush = LastPull_) = Push then
  begin
    if Push then
      LastPush := LastPush_
    else
      LastPush := LastPull_;

    SendMidiOut($B0, ControlSustain, ord(Push));
  end;
end;

procedure TAmpelEvents.NewPush(Push, Ctrl: boolean);
var
  i: integer;
  Event: TMouseEvent;
  GriffEvent: TGriffEvent;
  PushChanges: boolean;
begin
  CriticalAmpel.Acquire;
  try
    if UsedEvents = 0 then
      exit;

    // Control wechselt: Bass Reihe ändert (Tastatur F5 bis F12)
    for i := 0 to UsedEvents-1 do
      if (MouseEvents[i].Pitch = 0) and // nicht für Midi-Eingabe vom Keyboard
         (MouseEvents[i].Key > 0) and   // nur für Tastatur
         (((MouseEvents[i].Row_ = 5) and not Ctrl) or
          ((MouseEvents[i].Row_ = 6) and Ctrl)) then
      begin
        DoAmpel(i, false);
        MouseEvents[i].Row_ := MouseEvents[i].Row_ xor 3;
        DoAmpel(i, true);
      end;

    PushChanges := (LastPush = LastPull_) = Push;
    if not PushChanges then
      exit;

    for i := 0 to UsedEvents-1 do
    begin
      Event := MouseEvents[i];
      if (Event.Row_ >= 5) and not frmAmpel.Instrument.BassDiatonic then
      begin
      end else
      if Event.Pitch > 0 then  // MIDI Eingabe
      begin
        Event.Push_ := Push;
        GriffEvent.Clear;
        GriffEvent.SoundPitch := Event.Pitch;
        GriffEvent.InPush := Event.Push_;
        if GriffEvent.SoundToGriff(frmAmpel.Instrument^) and
           (GriffEvent.InPush = Event.Push_) then
        begin
          Event.Row_ := GriffEvent.GetRow;
          Event.Index_ := GriffEvent.GetIndex;
          if (Event.Row_ > 0) and (Event.Index_ >= 0) then
          begin
            DoAmpel(i, false);
            MouseEvents[i] := Event;
          end;
        end;
      end else begin
        DoAmpel(i, false);
        MouseEvents[i].Push_ := Push;
      end;
    end;

    SendPush(Push);

    for i := 0 to UsedEvents-1 do
    begin
      Event := MouseEvents[i];
      if (Event.Row_ >= 5) and not frmAmpel.Instrument.BassDiatonic then
      begin
      end else
      if Event.Pitch > 0 then  // MIDI Eingabe
      begin
        GriffEvent.Clear;
        GriffEvent.SoundPitch := Event.Pitch;
        GriffEvent.InPush := Event.Push_;
        if GriffEvent.SoundToGriff(frmAmpel.Instrument^) and
           (GriffEvent.InPush = Event.Push_) then
        begin
          Event.Row_ := GriffEvent.GetRow;
          Event.Index_ := GriffEvent.GetIndex;
          if (Event.Row_ > 0) and (Event.Index_ >= 0) then
          begin
            DoAmpel(i, true);
          end;
        end;
      end else begin
        DoAmpel(i, true);
      end;
    end;
  finally
    CriticalAmpel.Release;
  end;
end;

procedure TAmpelEvents.NewEvent(const Event: TMouseEvent);
var
  i: integer;
begin
  if UsedEvents >= High(MouseEvents) then
    exit;

  CriticalAmpel.Acquire;
  try
    for i := 0 to UsedEvents-1 do
      if (MouseEvents[i].Row_ = Event.Row_) and
         (MouseEvents[i].Index_ = Event.Index_) and
         (MouseEvents[i].Pitch = 0) then
        exit;

      MouseEvents[UsedEvents] := Event;
      inc(fUsedEvents);
      if LastPush = unknown then
      begin
        if not Event.Push_ then
          LastPush := LastPush_
        else
          LastPush := LastPull_;
        SendPush(Event.Push_);
      end;

      DoAmpel(UsedEvents-1, true);
  finally
    CriticalAmpel.Release;
  end;
end;

procedure UseVirtualMidi(Event: TMouseEvent; On_: boolean);
var
  b: integer;
  c: integer;
  d: integer;
begin
  if iVirtualMidi >= 0 then
  begin
    case Event.Row_ of
      1: b := 0;
      2: b := 14;
      3: b := 26;
      4: b := 38;
      5: b := 100;
      6: b := 110;
      else b := 0;
    end;
    inc(b, Event.Index_);
    if (not Event.Push_) and (Event.Row_ <= 4) then
      inc(b, 50);
    if (RowIndexToGriff(Event.Row_, Event.Index_) > 0) or
       (Event.Row_ > 4) then
    begin
      if On_ then
        c := $90
      else
        c := $80;
      d := $40;
      if Event.Push_ and On_ then
        inc(d, $10);
      MidiOutput.Send(iVirtualMidi, c, b, d);
//      write(Format('$%2.2x $%2.2x $%2.2x', [c, b, d]));
//      writeln(Format('  (%d  %d  %d)', [c, b, d]));
    end;
  end;
end;

procedure TAmpelEvents.DoAmpel(Index: integer; On_: boolean);
var
  Event: TGriffEvent;
  d: byte;
begin
  with MouseEvents[Index] do
  begin
    frmAmpel.PaintAmpel(Row_, Index_, Push_, On_);
    Event.SetEvent(Row_, Index_, Push_, frmAmpel.Instrument^);
    if Row_ in [1..6] then
    begin
      if On_ then
      begin
        d := $5f;
        if Row_ >= 5 then
          d := $6F;
        SendMidiOut($90 + Row_ , Event.SoundPitch, d)
      end else begin
        SendMidiOut($80 + Row_, Event.SoundPitch, $40);
      end;
    end;
    UseVirtualMidi(MouseEvents[Index], On_);
    frmAmpel.PaintAmpel(Row_, Index_, Push_, On_);

    if assigned(frmAmpel.SelectedChanges) then
    begin
      if not On_ then
      begin
        frmAmpel.SelectedChanges(nil)
      end else
        frmAmpel.SelectedChanges(@Event);
    end;
  end
end;

procedure TAmpelEvents.EventOff(const Event: TMouseEvent);
var
  i, j: integer;
begin
  CriticalAmpel.Acquire;
  try
    for i := 0 to UsedEvents-1 do
      if ((MouseEvents[i].Row_ = Event.Row_) and (MouseEvents[i].Index_ = Event.Index_)) or
         ((MouseEvents[i].Pitch = Event.Pitch) and (Event.Pitch > 0)) then
      begin
        DoAmpel(i, false);
        for j := i+1 to UsedEvents-1 do
          MouseEvents[j-1] := MouseEvents[j];
        dec(fUsedEvents);
        break;
      end;
  finally
    CriticalAmpel.Release;
  end;
end;

procedure TAmpelEvents.GetKeyEvent(Key: integer; var Event: TMouseEvent);
var
  i: integer;
begin
  CriticalAmpel.Acquire;
  try
    Event.Clear;
    for i := 0 to UsedEvents-1 do
      if (MouseEvents[i].Key = Key) then
      begin
        Event := MouseEvents[i];
        break;
      end;
  finally
    CriticalAmpel.Release;
  end;
end;

procedure TAmpelEvents.CheckMovePoint(const P: TPoint; Down: boolean);
var
  i, Index: integer;
  distance: double;
  Event: TMouseEvent;
  rect: TRect;
  Cont: boolean;
begin
  Index := -1;
  CriticalAmpel.Acquire;
  try
    if UsedEvents > 0 then
    begin
      distance := P.Distance(MouseEvents[0].P);
      Index := 0;
      for i := 1 to UsedEvents-1 do
        if distance > P.Distance(MouseEvents[i].P) then
        begin
          Index := i;
          distance := P.Distance(MouseEvents[i].P);
        end;
    end;

    cont := false;
    if Index >= 0 then
    begin
      Event := MouseEvents[index];
      rect := frmAmpel.KnopfRect(Event.Row_, Event.index_);
      cont := rect.Contains(P);
    end;
  finally
    CriticalAmpel.Release;
  end;

  if (Index >= 0) then
  begin
    if not cont or not Down then
    begin
      EventOff(Event);
    end;
  end else
  if Down then  
    frmAmpel.MakeMouseDown(P, ShiftUsed);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TfrmAmpel.ChangeInstrument(Instrument_: PInstrument);
var
  Row: byte;
begin
  Instrument := Instrument_;
  if Instrument <> nil then
  begin
    MaxIndex := Instrument.GetMaxIndex(row);
    MinIndex := Instrument.GetMinIndex(row);
    Caption := String(Instrument.Name);
  end else
    Caption := '';
  FormShow(nil);
  FormResize(nil);
  invalidate;
end;

procedure TfrmAmpel.btnFlipClick(Sender: TObject);
begin
  FlippedVert := not FlippedVert;
  cbSizeChange(nil);
  invalidate;
end;

procedure TfrmAmpel.btnFlipHorzClick(Sender: TObject);
begin
  FlippedHorz_ := not FlippedHorz_;
  cbSizeChange(nil);
  invalidate;
end;

procedure TfrmAmpel.cbSizeChange(Sender: TObject);
var
  rect, rect1, rect2: TRect;
  rectMin, rectMax: TRect;
  i: integer;
  Mitte: integer;
  d: integer;
begin
  if FlippedHorz then
    lbUnten.Caption := 'Fuss'
  else
    lbUnten.Caption := 'Kopf';

  if Instrument = nil then
    exit;

  i := 2;
  if Instrument.Columns = 4 then
    i := 1;
  rectMin := KnopfRect(i, MinIndex);
  rectMax := KnopfRect(i, MaxIndex);
  if not FlippedHorz then
  begin
    rect := rectMin; rectMin := rectMax; rectMax := rect;
  end;

  rect1 := KnopfRect(Instrument.Columns, 4);
  rect2 := KnopfRect(5, 4);
  Mitte := (rect1.Right + rect2.Left) div 2;
  btnFlip.Left := Mitte - btnFlip.Width div 2;
  btnFlip.Top := rectMin.Top - btnFlip.Height div 2;

 // rect := KnopfRect(i, (MaxIndex - MinIndex) div 2);
  btnFlipHorz.Left := Mitte - btnFlipHorz.Width div 2;
  btnFlipHorz.Top := (rectMax.Bottom + rectMin.Top) div 2 +
                     (rectMax.Height - btnFlipHorz.Height) div 2;

  lbUnten.Top := rectMax.Bottom + 10;
  lbUnten.Left := Mitte - lbUnten.Width div 2;

  if FlippedVert then
    rect2.Offset(-rect2.Width, 0);
  lbTastatur.Left := rect2.Left;
  cbxVerkehrt.Left := rect2.Left;
  cbxLinkshaender.Left := rect2.Left;
  d := btnFlip.Top - lbTastatur.Top;
  lbTastatur.Top := lbTastatur.Top + d;
  cbxLinkshaender.Top := cbxLinkshaender.Top + d;
  cbxVerkehrt.Top := cbxVerkehrt.Top + d;
  Invalidate;
end;

procedure TfrmAmpel.cbxLinkshaenderClick(Sender: TObject);
begin
  cbSizeChange(nil);
  invalidate;
end;

procedure TfrmAmpel.FormActivate(Sender: TObject);
begin
  IsActive := true;
end;

procedure TfrmAmpel.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := true;
//  WindowState := wsMinimized;
end;

procedure TfrmAmpel.FormCreate(Sender: TObject);
begin
  CriticalMidiIn := TCriticalSection.Create;
  AmpelEvents := TAmpelEvents.Create(self);
  KnopfGroesse := 52;
  FlippedHorz_ := true;
  btnFlipClick(Sender);
  btnFlipHorzClick(Sender);
end;

procedure TfrmAmpel.FormDeactivate(Sender: TObject);
begin
  IsActive := false;
end;

procedure TfrmAmpel.FormDestroy(Sender: TObject);
begin
  AmpelEvents.Free;
  CriticalMidiIn.Free;
end;

function TfrmAmpel.GetKeyIndex(var Event: TMouseEvent; Key: word): boolean;
var
  i: integer;
  Row: byte;
begin
  result := false;
  Event.Clear;
  Event.Key := Key;
  Event.P := TPoint.Create(0, 0);
  if Key in [vk_F5 .. vk_F12] then
  begin
    if GetKeyState(vk_Control) < 0 then
      Event.Row_ := 5
    else
      Event.Row_ := 6;
    Event.Index_ := Key - vk_F5 + 1; // 1..8
  end else
  for Row := 1 to 4 do
    for i := 0 to High(TKeys) do
      if (TastKeys[Row][i] > #0) and (TastKeys[Row][i] = AnsiChar(Key)) then
      begin
        Event.Row_ := Row;
        Event.Index_ := i;
        break;
      end;

  if cbxVerkehrt.Checked then
  begin
    if (Key = ord('1')) or (Key = 191) then
    begin
      Event.Row_ := 4;
      Event.Index_ := -1;
      if (Key = 191) then
        dec(Event.Index_);
    end;
    if (Event.Row_ >= 5) or
       ((Event.Row_ = 1) and (Instrument.Columns = 3)) then
      Event.Row_ := 0;
    if Event.Row_ in [1..4] then
    begin
      Event.Row_ := 5 - Event.Row_;
      Event.Index_ := 10 - Event.Index_;
    end;
  end;

  if (Event.Row_ = 4) and (Instrument.Columns = 3) then
  begin
    Event.Row_ := 5;
    dec(Event.Index_, 2);
  end;

  if cbxLinksHaender.Checked then
  begin
    case Event.Row_ of
      1, 3: Event.Index_ := 11 - Event.Index_;
      2, 4: Event.Index_ := 10 - Event.Index_;
      5, 6: Event.Index_ := 9 - Event.Index_;
      else begin end;
    end;
  end;
  if (Event.Index_ >= 0) and (Event.Row_ in [1..6]) then
  begin
    if Event.Row_ >= 5 then
    begin
      result := true; //(Instrument.Bass[Event.Row_ = 6] > 0)
    end else
      result := (Instrument.Push.Col[Event.Row_][Event.Index_] > 0);
  end;
end;

procedure TfrmAmpel.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Push, Ctrl: boolean;
  Event: TMouseEvent;
begin
  if Key in [vk_Left, vk_Right, vk_Up, vk_Down, vk_Tab,
             vk_Insert, vk_Delete] then
  begin
    if (@KeyDown <> nil) then
      KeyDown(Sender, Key, Shift);
    exit;
  end;

  Push := ShiftUsed;
  Ctrl := GetKeyState(vk_Control) < 0;
  AmpelEvents.NewPush(Push, Ctrl);

  Event.Clear;
  Event.Push_ := Push;
  if GetKeyIndex(Event, Key) then
  begin
    if (Sender <> nil) then
      AmpelEvents.NewEvent(Event);
  end;
end;

procedure TfrmAmpel.FormKeyPress(Sender: TObject; var Key: Char);
begin
  //
end;

procedure TfrmAmpel.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Event: TMouseEvent;
begin
  if Key in [vk_Shift, vk_Control, vk_Capital] then
  begin
    FormKeyDown(nil, Key, Shift);
    exit;
  end;

  AmpelEvents.GetKeyEvent(Key, Event);
  AmpelEvents.EventOff(Event);
end;

procedure TfrmAmpel.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
  Event: TMouseEvent;
begin
  P.X := X;
  P.Y := Y;
  Event := MakeMouseDown(P, ShiftUsed);

{$ifndef __VIRTUAL__}
  if (@KeyDown <> nil) and
     ((GetKeyState(vk_scroll) = 1) or //   numlock pause scroll
      (GetKeyState(vk_RMenu) < 0)) then // AltGr
    frmGriff.GenerateNewNote(Event);
{$endif}
end;

function TfrmAmpel.MakeMouseDown(const P: TPoint; Push: boolean): TMouseEvent;
var
  Row, Index: byte;
  Event: TMouseEvent;
begin
  Event.Clear;
  Event.P := P;
  Event.Row_ := 0;
  Event.Index_ := 0;
  Event.Push_ := Push;
  result := Event;
  if Instrument = nil then
    exit;

  for Row := 1 to Instrument.Columns do
  begin
    for Index := 0 to 12 do
      if Instrument^.Push.Col[Row, Index] > 0 then
        if KnopfRect(Row, Index).Contains(Event.P) then
        begin
          Event.Row_ := Row;
          Event.Index_ := Index;
          break;
        end;
    if Event.Row_ > 0 then
      break;
  end;

  if Event.Row_ = 0 then
    for Index := 1 to 9 do
      if Instrument^.Bass[false, Index] > 0 then
        if KnopfRect(5, Index).Contains(Event.P) then
        begin
          Event.Row_ := 5;
          Event.Index_ := Index;
          break;
        end;
  if Event.Row_ = 0 then
    for Index := 1 to 9 do
      if Instrument^.Bass[true, Index] > 0 then
        if KnopfRect(6, Index).Contains(Event.P) then
        begin
          Event.Row_ := 6;
          Event.Index_ := Index;
          break;
        end;

  AmpelEvents.NewEvent(Event);
  result := Event;
end;

procedure TfrmAmpel.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  Q: TPoint;
begin
  if not (ssLeft in Shift) then
    exit;

  Q.X := X;
  Q.Y := Y;
  AmpelEvents.CheckMovePoint(Q, true);
end;

procedure TfrmAmpel.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Q: TPoint;
begin
  Q.X := X;
  Q.Y := Y;

  AmpelEvents.CheckMovePoint(Q, false);
end;

function TfrmAmpel.KnopfRect(Row: byte {1..6}; index: byte {0..12}): TRect;
var
  y: integer;
  Knopf, kDelta: integer;
  neuner: boolean;
begin
  kDelta := 10;
  Knopf := KnopfGroesse + kDelta div 2;
  result := TRect.Create(0, 0, KnopfGroesse, KnopfGroesse);
  if Instrument = nil then
    exit;

  if FlippedHorz then
  begin
    if not odd(Row) then
      result.Offset(0, Knopf)
    else
      result.Offset(0, Knopf div 2);
  end else
  if odd(Row) then
    result.Offset(0, Knopf div 2);

  result.Offset(-KnopfGroesse div 2, 0);

  if Row <= 4 then
  begin
    if not FlippedHorz then
    begin
      index := MaxIndex - index;
      if (Instrument.Columns = 3)  then
        inc(index);
    end;

    if FlippedVert then
    begin
      case Instrument.Columns of
        2: Row := Row xor 1;
        3: if Row in [1,3] then
             Row := Row xor 2;
        4: if Row in [1,4] then
             Row := Row xor 5  // 1, 5
           else
             Row := Row xor 1; // 2, 3
      end;
      result.Offset(3*Knopf, 0);
    end;

    result.Offset(Row*KnopfGroesse, Index*Knopf);
  end else begin
    neuner := Instrument.Bass[false, 9] > 0;
    if Instrument.BassDiatonic then
    begin
      if not FlippedHorz then
        index := 9 - Index;
    end else
    if {not} FlippedHorz then
      index := 9 - Index;
    if Instrument.bigInstrument then
    begin
      if FlippedHorz then
      begin
        if Row = 6 then
          result.Offset(0, -Knopf);
      end else
      if (Row = 5) then
        result.Offset(0, -Knopf);
    end;

    y := (index + (MaxIndex - MinIndex - 7) div 2);
    y := y * Knopf;
    if neuner then
    begin
      if not FlippedHorz then // !!!
        dec(y, Knopf div 2)
      else
        inc(y, Knopf div 2);
    end else
    if FlippedHorz then
      dec(y, Knopf div 2)
    else
      inc(y, Knopf div 2);

    result.Offset(-kDelta div 2, 0);

    if FlippedVert then
      result.Offset(KnopfGroesse*(7 - Row), y)
    else
      result.Offset((Instrument.Columns+2)*Knopf +
                    KnopfGroesse*(Row-5), y);
  end;
end;


procedure TfrmAmpel.FormPaint(Sender: TObject);
var
  i, k: integer;
begin
  if Instrument = nil then
    exit;

  canvas.Brush.Color := $7f0000;
  canvas.Pen.Color := $ffffff;
  for i := 1 to Instrument.Columns do
    for k := 0 to 12 do
      if Instrument^.Push.Col[i, k] > 0 then
        PaintAmpel(i, k, false, false);
  for k := 1 to 9 do
    if Instrument.Bass[false, k] > 0 then
      PaintAmpel(5, k, false, false);
  for k := 1 to 9 do
    if Instrument.Bass[true, k] > 0 then
      PaintAmpel(6, k, false, false);
end;

procedure TfrmAmpel.FormResize(Sender: TObject);

  function GetWidth: integer;
  var
    rect: TRect;
  begin
    if FlippedVert then
      rect := KnopfRect(1, 5)
    else
      rect := KnopfRect(6, 4);
    result := rect.Right + rect.Width;
  end;

var
  w1, w2: integer;
begin
  w1 := GetWidth;
  repeat
    if w1 > Width then
    begin
      if Knopfgroesse < 15 then
        break;
      w2 := w1;
      dec(KnopfGroesse);
      w1 := GetWidth;
    end else
    if w1 < Width then
    begin
      if KnopfGroesse > 200 then
        break;
      inc(KnopfGroesse);
      w2 := GetWidth;
    end else
      break;
  until (w1 < Width) and (w2 >= Width);
  cbSizeChange(nil);
end;

procedure TfrmAmpel.FormShortCut(var Msg: TWMKey; var Handled: Boolean);
var
  KeyCode: word;
begin
  if (Msg.KeyData and $40000000) <> 0 then // auto repeat
  begin
    Handled := true;
    exit;
  end;
  KeyCode := {Menus.}ShortCut(Msg.CharCode, KeyDataToShiftState(Msg.KeyData));
  //writeln(IntToHex(Keycode));
  if (KeyCode and $fff) = vk_F10 then
  begin
    KeyCode := vk_F10;
    FormKeyDown(self, KeyCode, []);
    Handled := true;
  end;
end;

procedure TfrmAmpel.FormShow(Sender: TObject);
var
  rect: TRect;
begin
  cbSizeChange(nil);
  if FlippedVert then
    rect := KnopfRect(1, 5)
  else
    rect := KnopfRect(6, 4);
  Width := rect.Right + rect.Width;

  Height := lbUnten.Top + 100;
end;

procedure TfrmAmpel.PaintAmpel(Row: byte {1..6}; index: integer {0..12}; Push, On_: boolean);
var
  rect, rect1: TRect;
begin

  if (Instrument = nil) or (Instrument.GetPitch(Row, Index, Push) <= 0) then
    exit;

  if (Row >= 5) and not Instrument.BassDiatonic then
    Push := false;

  rect := KnopfRect(Row, index);
  if not On_ then
    canvas.Brush.Color := $7f0000
  else
  if Push then
    canvas.Brush.Color := TColors.Magenta
  else
    canvas.Brush.Color := TColors.Cyan;
  canvas.Ellipse(rect);

  if (index = 5) and
     (row = 2) {and (Instrument.Columns = 3)} then   // Kreuz
  begin
    canvas.Pen.Color := $ffffff;
    canvas.MoveTo(rect.Left + 5, rect.Top + 5);
    canvas.LineTo(rect.Right - 5, rect.Bottom - 5);

    canvas.MoveTo(rect.Right - 5, rect.Top + 5);
    canvas.LineTo(rect.Left + 5, rect.Bottom - 5);
  end;

  // Balg-Strich
  if (Row <= 4) or Instrument.BassDiatonic then
  begin
    if Push and On_ then
      canvas.Brush.Color := 0
    else
      canvas.Brush.Color := Color;
    if FlippedHorz then
      rect := KnopfRect(2, 10)
    else
      rect := KnopfRect(2, 0);

    rect.Height := rect.Height div 4;
    if FlippedVert and Instrument.bigInstrument then
      rect.Offset(-rect.Width, 0);
    rect.Offset(-rect.Width, lbUnten.Top - rect.Top - (rect.Height - lbUnten.Height) div 2);
    rect.Width := Instrument.Columns*rect.Width;
    canvas.FillRect(rect);

    if Instrument.BassDiatonic then
    begin
      if FlippedVert then
        rect1 := KnopfRect(6, 0)
      else
        rect1 := KnopfRect(5, 0);
      rect.Left := rect1.Left;
      rect.Width := 2*rect1.Width;
      canvas.FillRect(rect);
    end;
  end;
end; 

function TfrmAmpel.FlippedHorz: boolean;
begin
  result := FlippedHorz_ = not cbxLinksHaender.Checked;
end;

procedure TfrmAmpel.OnMidiInData(aDeviceIndex: integer; aStatus, aData1, aData2: byte; Timestamp: integer);
var
  Event: TMouseEvent;
  Key: word;
  GriffEvent: TGriffEvent;

  function GetInstr(var Event: TMouseEvent): boolean;
  var
    Vocal: TVocalArray;
    Bass: TBassArray;
  begin
    if Event.Row_ in [1..4] then
    begin
      if Event.Push_ then
        Vocal := Instrument.Push
      else
        Vocal := Instrument.Pull;
      Event.Index_ := GetIndexToPitchInArray(Event.Pitch, Vocal.Col[Event.Row_]);
    end else
    if Event.Row_ in [5..6] then
    begin
      if not Event.Push_ and Instrument.BassDiatonic then
        Bass := Instrument.PullBass
      else
        Bass := Instrument.Bass;
      Event.Index_ := GetBassIndex(Bass[Event.Row_ = 6], Event.Pitch);
    end;
    result := Event.Index_ >= 0;
  end;

begin
  Event.Clear;
  Event.Pitch := aData1;
  Event.Row_ := 1;
  Event.Index_ := -1;
  Event.Push_ := ShiftUsed;

  CriticalMidiIn.Acquire;
  try
    if ((aStatus = $b0) and (aData1 = 64)) or
       ((aStatus = $b7) and (aData1 = ControlSustain)) then
    begin
      Sustain_ := aData2 > 0;
      Key := 0;
      frmAmpel.FormKeyDown(self, Key, []);
    end;
    if aStatus = $80 then
    begin
      AmpelEvents.EventOff(Event);
    end else
    if aStatus = $90 then
    begin
      GriffEvent.Clear;
      GriffEvent.InPush := Event.Push_;
      GriffEvent.SoundPitch := aData1;
      if GriffEvent.SoundToGriff(Instrument^) and
         (GriffEvent.InPush = Event.Push_) then
      begin
        Event.Row_ := GriffEvent.GetRow;
        Event.Index_ := GriffEvent.GetIndex;
        if (Event.Row_ > 0) and (Event.Index_ >= 0) then
        begin
          AmpelEvents.NewEvent(Event);
  {$ifndef __VIRTUAL__}
          if (GetKeyState(vk_scroll) = 1) then // numlock pause scroll
            frmGriff.GenerateNewNote(Event);
  {$endif}
        end;
      end;
    end else
    if ((aStatus and $f) in [1..6]) and
       ((aStatus shr 4) in [8, 9]) then
    begin
      Event.Row_ := (aStatus and $f);
      if GetInstr(Event) then
      begin
        if (aStatus shr 4) = 9 then
          AmpelEvents.NewEvent(Event)
        else
          AmpelEvents.EventOff(Event);
      end;
    end;
  finally
    CriticalMidiIn.Release;
  end;
end;

procedure TfrmAmpel.KeyMessageEvent(var Msg: TMsg; var Handled: Boolean);
begin
  if ((Msg.message = WM_KEYDOWN) or (Msg.message = WM_KEYUP)) then
  begin
{$ifdef CONSOLE}
//    writeln(Msg.wParam, '  ', IntToHex(Msg.lParam));
{$endif}
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
        if (Msg.lParam and $fff0000) = $01b0000 then
          Msg.wParam := 192;
        if (Msg.lParam and $fff0000) = $0600000 then
          Msg.wParam := 186;
        // 2. Reihe ö ä $
        if (Msg.lParam and $fff0000) = $0610000 then
          Msg.wParam := 222;
        if (Msg.lParam and $fff0000) = $0620000 then
          Msg.wParam := 220;
        if (Msg.lParam and $fff0000) = $0630000 then
          Msg.wParam := $29;
      end else begin
        if (Msg.lParam and $fff0000) = $01a0000 then
          Msg.wParam := 186;
        // 2. Reihe ö ä
 //       if (Msg.lParam and $fff0000) = $0270000 then
 //         Msg.wParam := 222;
        if (Msg.lParam and $fff0000) = $0280000 then
          Msg.wParam := 126;
        if (Msg.lParam and $fff0000) = $01b0000 then
          Msg.wParam := 192;
      end;
      // 2. Reihe  $
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

end.
