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
unit UfrmGriff;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Menus,
  Controls, Forms, Dialogs, Types,
  UGriffPartitur, UMyMidiStream, Midi, UGriffEvent, UAmpel;

type

  TCursorMovePos = (cmpLeft, cmpRight, cmpTop, cmpBottom, cmpDrag);

  PRubberProc = procedure (const Rect: TRect) of object;
  
  TfrmGriff = class(TForm)
    procedure FormPaint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    procedure GetClippedMousePos(var Pos : TPoint; X, Y : integer);
//    function GetKeyIndex(var Event: UAmpel.TMouseEvent; Key: word): boolean;
    procedure DrawGriff(ClipRect: TRect; Horz_pos: integer);

  public
    IsActive: boolean;

    xRGB, yRGB : integer;

    sChangingCursor : set of TCursorMovePos;
    pDrag : TPoint;

    RubberChanges: PRubberProc;
    SelectedChanges: PSelectedProc;
    procedure SetPlayRect(rect: TRect);
    procedure ShowSelected;
    procedure GenerateNewNote(Event: TMouseEvent);

  end;

var
  frmGriff: TfrmGriff;
  UseEllipses: boolean = false;

implementation

{$R *.dfm}

uses UInstrument, UMidiEvent;

function OverLine(x, Left, Right, y, Top, Delta : integer) : boolean;
begin
  result:= (Left-Delta <= x) and (x <= Right+Delta) and
           (abs(Top - y) <= Delta);
end;

function OverPoint(x, y : integer; p : TPoint; Delta : integer) : boolean;
begin
  result:= (abs(p.X - x) <= Delta) and
           (abs(p.Y - y) <= Delta);
end;

procedure MakeOriginalRect(var rect : TRect); overload;
var r : integer;
begin
  if rect.Left > rect.Right then begin
    r:= rect.Left;
    rect.Left:= rect.Right;
    rect.Right:= r;
  end;
  if rect.Top > rect.Bottom then begin
    r:= rect.Top;
    rect.Top:= rect.Bottom;
    rect.Bottom:= r;
  end;
end;

procedure ClipRect(var rect : TRect; XMax, YMax : integer);
begin
  if rect.Left < 0 then
    rect.Left:= 0;
  if rect.Top < 0 then
    rect.Top:= 0;
  if rect.Right > XMax then
    rect.Right:= XMax;
  if rect.Bottom > YMax then
    rect.Bottom:= YMax;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TfrmGriff.FormActivate(Sender: TObject);
begin
   IsActive := true;
end;

procedure TfrmGriff.FormCreate(Sender: TObject);
begin
  GriffPartitur_.playLocation := -1;
  MidiOutput.GenerateList;
  MidiInput.GenerateList;
  if (System.ParamCount = 1) and
     FileExists(System.ParamStr(1)) and
     (ExtractFileExt(System.ParamStr(1)) = '.griff') then
  begin
    if GriffPartitur_.LoadFromGriffFile(System.ParamStr(1)) then
    begin
      Caption := ExtractFilename(System.ParamStr(1));
      Show;
    end;
  end;
end;

procedure TfrmGriff.FormDeactivate(Sender: TObject);
begin
  IsActive := false;
end;

procedure TfrmGriff.GetClippedMousePos(var Pos : TPoint; X, Y : integer);
var w, h : integer;
begin
{$ifdef UseBitmap}
  w:= bmPaint.Width;
  h:= bmPaint.Height;
{$else}
  if GriffPartitur_.quarterNote = 0 then
  begin
    Pos := TPoint.Create(0, 0);
    exit;
  end;
  w:= Width + HorzScrollBar.Position - 20;
  h:= Height + VertScrollBar.Position;
{$endif}
  Pos.X := Max(0, Min(w, X));
  Pos.Y := Max(0, Min(h, Y));
end;

procedure TfrmGriff.ShowSelected;
var
  size, i, w: integer;
begin
  // HorzScrollBar anpassen
  i := GriffPartitur_.UsedEvents - 10;
  if i < 0 then
    i := 0;
  Size := 0;
  while i < GriffPartitur_.UsedEvents do
  begin
    if Size < GriffPartitur_.GriffEvents[i].AbsRect.Right then
      Size := GriffPartitur_.GriffEvents[i].AbsRect.Right;
    inc(i);
  end;
  HorzScrollBar.Range := GriffPartitur_.TickToScreen(Size) + 8*pitch_width;

  // Selected soll sichtbar sein
  if GriffPartitur_.Selected >= 0 then
  begin
    w := GriffPartitur_.SelectedEvent.AbsRect.Right + GriffPartitur_.quarterNote;
    if HorzScrollBar.Position + Width < GriffPartitur_.TickToScreen(w) then
    begin
      HorzScrollBar.Position :=
        GriffPartitur_.TickToScreen(GriffPartitur_.SelectedEvent.AbsRect.Right) - 3*Width div 4;
    end else
    if HorzScrollBar.Position > GriffPartitur_.TickToScreen(GriffPartitur_.SelectedEvent.AbsRect.Left) then
    begin
      if HorzScrollBar.Position > Width div 4 then
        HorzScrollBar.Position := HorzScrollBar.Position - Width div 4
      else
        HorzScrollBar.Position := 0;
    end;
  end;
end;
{
function TfrmGriff.GetKeyIndex(var Event: UAmpel.TMouseEvent; Key: word): boolean;
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
    Event.Index_ := Key - vk_F5 + 1;
    Result := true;
  end else
  for Row := 1 to 4 do
    for i := 0 to High(TKeys) do
      if (TastKeys[Row][i] > #0) and (TastKeys[Row][i] = AnsiChar(Key)) then
      begin
        Event.Row_ := Row;
        Event.Index_ := 11-i;
        result := GriffPartitur_.Instrument.Push.Col[Row][Event.Index_] > 0;
        break;
      end;
  if (Event.Row_ = 4) and (GriffPartitur_.Instrument.Columns = 3) then
  begin
    Event.Row_ := 5;
    if Event.Index_>= 2  then
    begin
      dec(Event.Index_, 2);
      result := true;
    end;
  end;
end;
}
procedure TfrmGriff.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Event: UAmpel.TMouseEvent;
begin
  if (GetKeyState(vk_RMenu) < 0) and
     frmAmpel.GetKeyIndex(Event, Key) then
  begin
    GenerateNewNote(Event);
    exit;
  end;
  if Key = 27 then
  begin
    with GriffPartitur_ do
    begin
      Unselect;
      if @RubberChanges <> nil then
        RubberChanges(rectRubberBand);
      Selected := -1;
    end;
    if @SelectedChanges <> nil then
      SelectedChanges(GriffPartitur_.SelectedEvent);
    invalidate;
  end else
  if GriffPartitur_.KeyDown(Key, Shift) then
  begin
    GriffPartitur_.SortEvents;
    if @SelectedChanges <> nil then
      SelectedChanges(GriffPartitur_.SelectedEvent);

    ShowSelected;

    if (GriffPartitur_.SelectedEvent = nil) and
       not GriffPartitur_.bRubberBand and not GriffPartitur_.bRubberBandOk then
    begin
      sChangingCursor := [];
      Cursor:= crDefault;
    end;
    invalidate;
  end;
end;

procedure TfrmGriff.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
//
end;

procedure TfrmGriff.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Pos, NotenPoint : TPoint;
  iEvent: integer;
begin
  if mbLeft = Button then begin
    GetClippedMousePos(Pos, X + HorzScrollBar.Position, Y + VertScrollBar.Position);
    GriffPartitur_.ScreenToNotePoint(NotenPoint, Pos);
    pDrag := NotenPoint;

    GriffPartitur_.bRubberBand:= false;
    GriffPartitur_.bRubberBandOk:= false;
    if Cursor = crDefault then
    begin
      iEvent := GriffPartitur_.SearchGriffEvent(NotenPoint);
      if GriffPartitur_.Selected = iEvent then
      begin
        iEvent := -1;
        GriffPartitur_.BackEvent := -1;
      end;
      GriffPartitur_.Selected := iEvent;
      if (iEvent >= 0) and (GriffPartitur_.BackEvent >= 0) then
      begin
        x := iEvent;
        y := GriffPartitur_.BackEvent;
        if x < y then
        begin
          x := y;
          y := iEvent;
        end;
        with GriffPartitur_ do
        begin
          rectRubberBand.Top := 4*row_height;
          rectRubberBand.Height := 22*row_height;
          rectRubberBand.Left := TickToScreen(GriffEvents[y].AbsRect.Left) + 1;
          rectRubberBand.Right := TickToScreen(GriffEvents[x].AbsRect.Right) - 1;
          bRubberBand := false;
          bRubberBandOk := true;
          BackEvent := -1;
          Selected := -1;
        end;
      end else
      if @SelectedChanges <> nil then
        SelectedChanges(GriffPartitur_.SelectedEvent);
      sChangingCursor := [];
      invalidate;
    end;
  end else
  if mbRight = Button then begin
    if sChangingCursor <> [] then begin
    end else begin
      with GriffPartitur_ do
      begin
        GetClippedMousePos(rectRubberBand.TopLeft, X + HorzScrollBar.Position,
                                                   Y + VertScrollBar.Position);
        rectRubberBand.Right:= rectRubberBand.Left;
        rectRubberBand.Bottom:= rectRubberBand.Top;
        bRubberBand:= true;
        bRubberBandOk:= false;
      end;
      GriffPartitur_.Selected := -1;
      sChangingCursor:= [];
      Cursor:= crDefault;

      SetCaptureControl(self);
    end;
  end;

end;

procedure TfrmGriff.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
const Delta = 5;
var
  NotenPoint, Pos: TPoint;
  rect: TRect;
begin
  xRGB:= X + HorzScrollBar.Position;
  yRGB:= Y + VertScrollBar.Position;
  with GriffPartitur_ do
  begin
    if bRubberBand then begin
      GetClippedMousePos(rectRubberBand.BottomRight, xRGB, yRGB);
    //  writeln(rectRubberBand.Bottom);
      bRubberBandOk:= true;
      Rubber_In_Push := true;
      if @RubberChanges <> nil then
        RubberChanges(rectRubberBand);
      sChangingCursor:= [];
      Cursor:= crDefault;
      Invalidate;
    end else
    if bRubberBandOk then begin
      if ssRight in Shift then begin
        if sChangingCursor <> [] then begin
          if cmpTop in sChangingCursor then
            rectRubberBand.Top:=    Min(yRGB, rectRubberBand.Bottom-2);
          if cmpBottom in sChangingCursor then
            rectRubberBand.Bottom:= Max(yRGB, rectRubberBand.Top+2);
          if cmpLeft in sChangingCursor then
            rectRubberBand.Left:=   Min(xRGB, rectRubberBand.Right-2);
          if cmpRight in sChangingCursor then
            rectRubberBand.Right:=  Max(xRGB, rectRubberBand.Left+2);
          if [cmpDrag] = sChangingCursor then begin
            // Rechteck verschieben.
            xRGB:= pDrag.X - xRGB;
            yRGB:= pDrag.Y - yRGB;
            if rectRubberBand.Left - xRGB < 0 then
              xRGB:= rectRubberBand.Left;
            if rectRubberBand.Right - xRGB > HorzScrollBar.Range then
              xRGB:= rectRubberBand.Right - HorzScrollBar.Range;
            if rectRubberBand.Top - yRGB < 0 then
              yRGB:= rectRubberBand.Top;
            if rectRubberBand.Bottom - yRGB > VertScrollBar.Range then
              yRGB:= rectRubberBand.Bottom - VertScrollBar.Range;

            rectRubberBand.Offset(-xRGB, -yRGB);
            dec(pDrag.X, xRGB);
            dec(pDrag.Y, yRGB);
          end;
          invalidate;
        end;
      end else begin
        sChangingCursor:= [];
        if OverLine(xRGB, rectRubberBand.Left, rectRubberBand.Right, yRGB,
                    rectRubberBand.Top, Delta) then
          sChangingCursor:= sChangingCursor + [cmpTop];

        if OverLine(xRGB, rectRubberBand.Left, rectRubberBand.Right, yRGB,
                    rectRubberBand.Bottom-1, Delta) then
          sChangingCursor:= sChangingCursor + [cmpBottom];

        if OverLine(yRGB, rectRubberBand.Top, rectRubberBand.Bottom, xRGB,
                    rectRubberBand.Left, Delta) then
          sChangingCursor:= sChangingCursor + [cmpLeft];
        if OverLine(yRGB, rectRubberBand.Top, rectRubberBand.Bottom, xRGB,
                    rectRubberBand.Right-1, Delta) then
          sChangingCursor:= sChangingCursor + [cmpRight];

        pDrag.X:= xRGB;
        pDrag.Y:= yRGB;
        if (sChangingCursor = []) and
           rectRubberBand.Contains(pDrag) then
          sChangingCursor:= [cmpDrag];

        if ([cmpTop, cmpLeft] = sChangingCursor) or
           ([cmpBottom, cmpRight] = sChangingCursor) then begin
          Cursor:= crSizeNWSE;
        end else
        if ([cmpBottom, cmpLeft] = sChangingCursor) or
           ([cmpTop, cmpRight] = sChangingCursor) then begin
          Cursor:= crSizeNESW;
        end else
        if (cmpTop in sChangingCursor) or
           (cmpBottom in sChangingCursor) then begin
          Cursor:= crSizeNS;
        end else
        if (cmpLeft in sChangingCursor) or
           (cmpRight in sChangingCursor) then begin
          Cursor:= crSizeWE;
        end else
        if cmpDrag in sChangingCursor then
          Cursor:= crDrag
        else
          Cursor:= crDefault;
      end;
    end else begin
      Pos.X:= xRGB;
      Pos.Y:= yRGB;
      GriffPartitur_.ScreenToNotePoint(NotenPoint, Pos);
      if (SelectedEvent <> nil) and (Shift = []) then
      begin
        rect := SelectedEvent.AbsRect;
        if rect.Contains(NotenPoint) then
        begin
          Cursor := crDrag;
          sChangingCursor := [cmpDrag];
          exit;
        end else
        if NotenPoint.Y = rect.Top then
        begin
          if (NotenPoint.X >= rect.Right) and (NotenPoint.X < rect.Right + 20) then
          begin
            Cursor := crSizeWE;
            sChangingCursor := [cmpRight];
            exit;
          end;
          if (NotenPoint.X < rect.Left) and (NotenPoint.X >= rect.Left - 20) then
          begin
            Cursor := crSizeWE;
            sChangingCursor := [cmpLeft];
            exit;
          end;
        end;
      end;
      Cursor:= crDefault;
    end;
  end;
end;

procedure TfrmGriff.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Pos, NotenPoint: TPoint;
  Event: TGriffEvent;
  w, h: integer;
begin
  with GriffPartitur_ do
  begin
    if (mbRight = Button) and bRubberBand then begin
      bRubberBand:= false;
      MouseCapture:= false;
      GetClippedMousePos(rectRubberBand.BottomRight, X + HorzScrollBar.Position,
                                                     Y + VertScrollBar.Position);
      MakeOriginalRect(rectRubberBand);
      bRubberBandOk:= (rectRubberBand.Right > 1) and
                      (rectRubberBand.Bottom > 1) and
                      (rectRubberBand.Right > rectRubberBand.Left+1) and
                      (rectRubberBand.Bottom > rectRubberBand.Top+1);
      if @RubberChanges <> nil then
        RubberChanges(rectRubberBand);
      sChangingCursor:= [];
      Cursor:= crDefault;
      invalidate;
    end else
    if mbRight = Button then
    begin
        Cursor:= crDefault;
        sChangingCursor:= [];
    end else
    if (sChangingCursor <> []) and (Button = mbLeft) and (SelectedEvent <> nil) then
    begin
      GetClippedMousePos(Pos, X + HorzScrollBar.Position, Y + VertScrollBar.Position);
      GriffPartitur_.ScreenToNotePoint(NotenPoint, Pos);
      w := NotenPoint.X - pDrag.X;
      w := GriffHeader.Details.GetRaster(w);
      h := NotenPoint.Y - pDrag.Y;
      Event := SelectedEvent^;
      if (w = 0) and (h = 0) then
      begin
        GriffPartitur_.Selected := -1;
        if @SelectedChanges <> nil then
          SelectedChanges(GriffPartitur_.SelectedEvent);
      end else
      if cmpDrag in sChangingCursor then
      begin
        if Event.NoteType = ntDiskant then
        begin
          Event.AbsRect.Top := NotenPoint.Y;
          Event.AbsRect.Height := 1;
        end else
          h := 0;
        if ChangeNote(@Event, h <> 0) then
        begin
          Event.AbsRect.Offset(w, 0);
          SelectedEvent^ := Event;
        end;
      end else begin
        if cmpLeft in sChangingCursor then
        begin
          w := -w;
          if Event.AbsRect.Width + w < GriffHeader.Details.smallestNote then
            w := GriffHeader.Details.smallestNote - Event.AbsRect.Width;
          SelectedEvent^.AbsRect.Offset(-w, 0);
          SelectedEvent^.AbsRect.Width := Event.AbsRect.Width + w;
        end else begin
          if Event.AbsRect.Width + w < GriffHeader.Details.smallestNote then
            w := GriffHeader.Details.smallestNote - Event.AbsRect.Width;
          SelectedEvent^.AbsRect.Width := Event.AbsRect.Width + w;
        end;
      end;
      if @SelectedChanges <> nil then
        SelectedChanges(GriffPartitur_.SelectedEvent);
      sChangingCursor := [];
      GriffPartitur_.SortEvents;
      invalidate;
      Cursor := crDefault;
    end;
  end;
end;

procedure TfrmGriff.FormPaint(Sender: TObject);
var rect, rectSource, rectFrame : TRect;
    w, h : integer;
begin
  if not GriffPartitur_.PartiturLoaded then
    exit;
    
  Canvas.CopyMode:= cmSrcCopy;
  Canvas.Brush.Color:= Color;
  rectSource.Left:= 0;
  rectSource.Top:= 0;
  w:= width + HorzScrollBar.Position - 20;
  h:= row_height*(rows + 6);
  rectSource.Right:= w;
  rectSource.Bottom:= h;
  rectFrame:= rectSource;
  rect:= Canvas.ClipRect;
  inc(rectSource.Left, HorzScrollBar.Position + rect.Left);
  inc(rectSource.Top, VertScrollBar.Position + rect.Top);

  // Der Punkt rect.(Left, Top) entspricht dem Punkt rectSource.(Left, Top) in
  // der Bitmap.
  // Jetzt sollen die Rechtecke gleich gross gemacht werden.
  if rect.Right - rect.Left < rectSource.Right - rectSource.Left then begin
    rectSource.Right:= rectSource.Left + rect.Right - rect.Left;
  end else
    rect.Right:= rect.Left + rectSource.Right - rectSource.Left;
  if rect.Bottom - rect.Top < rectSource.Bottom - rectSource.Top then begin
    rectSource.Bottom:= rectSource.Top + rect.Bottom - rect.Top;
  end else
    rect.Bottom:= rect.Top + rectSource.Bottom - rectSource.Top;

  DrawGriff(canvas.ClipRect, HorzScrollBar.Position);

  if GriffPartitur_.bRubberBandOk then begin
    // Das Band liegt auf den Punkten, die noch kopiert werden sollen.
    rect:= GriffPartitur_.rectRubberBand;
    MakeOriginalRect(rect);
    ClipRect(rect, w, h);
    rect.Offset(-HorzScrollBar.Position, -VertScrollBar.Position);
    if (rect.Right >= 0) and (rect.Bottom >= 0) and
       ((rect.Left <> rect.Right) or (rect.Top <> rect.Bottom)) then begin
      Canvas.Brush.Color:= (not clBlack) and $ffffff;
      Canvas.DrawFocusRect(rect);
      Canvas.Brush.Color:= Color;
    end;
  end;
end;

procedure TfrmGriff.FormShortCut(var Msg: TWMKey; var Handled: Boolean);
var
  KeyCode: word;
  Key: word;
  Shift: TShiftState;
begin
  if (Msg.KeyData and $40000000) <> 0 then // auto repeat
  begin
    Handled := true;
    exit;
  end;
  KeyCode := {Menus.}ShortCut(Msg.CharCode, KeyDataToShiftState(Msg.KeyData));
  Key := KeyCode and $ff;
  Shift := [];
  if (scShift and KeyCode) <> 0 then
    Shift := [ssShift];
  if (scCtrl and KeyCode) <> 0 then
    Shift := Shift + [ssCtrl];
  if (scAlt and KeyCode) <> 0 then
    Shift := Shift + [ssAlt];

//  if not GriffPartitur_.PlayControl(Msg.CharCode, Msg.KeyData) then
    case Key of
      VK_TAB: FormKeyDown(self, Key, Shift);
      else begin
        //writeln(IntToHex(KeyCode));
        if KeyCode <> 32786 then
          Exit;
      end;
    end;

  Handled := true;
end;

procedure TfrmGriff.FormShow(Sender: TObject);
begin
  if GriffPartitur_.PartiturLoaded then
  begin
 //   HorzScrollBar.Size := ClientWidth; //    Lazarus
    HorzScrollBar.Range := pitch_width*GriffPartitur_.GetRelTotalDuration + 500
  end;
end;

procedure TfrmGriff.SetPlayRect(rect: TRect);
var
  p: integer;
begin
  if (rect.Left < HorzScrollBar.Position) then
  begin
    HorzScrollBar.Position := rect.Left - Width div 4;
    Invalidate;
  end else
  if rect.Right >= HorzScrollBar.Position + Width - {50} 2*pitch_width then
  begin
    p := GriffPartitur_.GriffHeader.Details.MeasureFact*pitch_width;
    HorzScrollBar.Position := p*(rect.Left div p - 1);
    Invalidate;
  end else begin  
    rect.Offset(-HorzScrollBar.Position, 0);
    DrawGriff(rect, HorzScrollBar.Position);
  end;
end;


procedure TfrmGriff.DrawGriff(ClipRect: TRect; Horz_pos: integer);
type
  TNotenWeight = (nwFullDot, nwFull, nwHalfDot, nwHalf, nwQuarterDot, nwQuarter, nwEightDot, nwEight, nwShort);

  procedure DrawCross(rect: TRect);
  var
    w, c: cardinal;
  begin
    w := Canvas.Pen.Width;
    c := Canvas.Pen.Color;
    Canvas.Pen.Width := 2;
    Canvas.Pen.Color := 0;//$ffffff;
 //   if UseEllipses then
    begin
      inc(rect.Left, 3);
      dec(rect.Right, 3);
      inc(rect.Top, 3);
      dec(rect.Bottom, 3);
    end;
    canvas.MoveTo(rect.Left+1, rect.Top+1);
    canvas.LineTo(rect.Right-1, rect.Bottom-1);
    canvas.MoveTo(rect.Left+1, rect.Bottom-1);
    canvas.LineTo(rect.Right-1, rect.Top+1);
    Canvas.Pen.Width := w;
    Canvas.Pen.Color := c;
  end;

  procedure DrawNote(rect: TRect);
  begin
    if UseEllipses then
      canvas.Ellipse(rect)
    else begin
  //    if odd((rect.Top + 5) div row_height) then
  //      inc(rect.Top);
      canvas.Pen.Color := 0;
      canvas.FillRect(rect);

      canvas.MoveTo(rect.Left, rect.Top + 2);
      canvas.LineTo(rect.Left, rect.Bottom - 2);
      canvas.LineTo(rect.Right-1, rect.Bottom - 2);
      canvas.LineTo(rect.Right-1, rect.Top + 2);
      canvas.LineTo(rect.Left, rect.Top + 2);
    end;
  end;

  procedure PaintNote(x, y: integer; Cross: boolean; Weight: TNotenWeight);
  var
    rect, rect1: TRect;
  begin
    rect.Left := x;
    rect.Top := y;
    rect.Width := 14;
    rect.Height := 9;
    canvas.Pen.Color := 0;
    if Weight >= nwQuarterDot then
    begin
      canvas.Brush.Color := 0;
      canvas.Pen.Width := 1;
    end else begin
      canvas.Brush.Color := $ffffff;
      canvas.Pen.Width := 2;
    end;
    canvas.Brush.Style := bsSolid;
    canvas.Ellipse(rect);
    if Cross then
    begin
      rect1 := rect;
      rect1.Offset(-7, 2);
      rect1.Width := 5;
      rect1.Height := 5;
      canvas.Pen.Width := 2;
      canvas.MoveTo(rect1.Left, rect1.Top);
      canvas.LineTo(rect1.Right, rect1.Bottom);
      canvas.MoveTo(rect1.Left, rect1.Bottom);
      canvas.LineTo(rect1.Right, rect1.Top);
    end;
    if Weight in [nwFullDot, nwHalfDot, nwQuarterDot, nwEightDot] then
    begin
      canvas.Pen.Width := 1;
      canvas.Brush.Color := 0;
      rect1 := rect;
      rect1.Offset(16, 4);
      rect1.Height := 5;
      rect1.Width := 5;
      canvas.Ellipse(rect1);
    end;
    if Weight >= nwHalfDot then
    begin
      canvas.Pen.Width := 2;
      rect1 := rect;
      rect1.Offset(14, 5);
      canvas.MoveTo(rect1.Left, rect1.Top);
      canvas.LineTo(rect1.Left, rect1.Top - 25);
      if Weight >= nwEightDot then
      begin
        canvas.LineTo(rect1.Left + 6, rect1.Top - 16);
        if Weight = nwShort then
        begin
          canvas.MoveTo(rect1.Left, rect1.Top - 19);
          canvas.LineTo(rect1.Left + 6, rect1.Top - 10);
        end;
      end;
    end;
  end;

 var
   w, h: integer;
   d, tickDur: TGriffDuration;
   quot: double;

  procedure DrawSmallNotes(klingend: boolean);
  var
    i, j, k: integer;
    Weight: TNotenWeight;
    NotenVersatz: integer;
    rect: TRect;
  begin
    // kleines Notensystem unten
  //  NotenVersatz := 440;

 // if Instrument.bigInstrument then
    NotenVersatz := 460;
  // waagrechte Striche zeichnen
  canvas.Pen.Color := 0;
  for i := 1 to 5 do
  begin
    canvas.MoveTo(ClipRect.Left - Horz_pos, i*8 + MoveVert + NotenVersatz);
    canvas.LineTo(ClipRect.Right - Horz_pos, i*8 + MoveVert + NotenVersatz);
  end;

  // senkrechte Striche zeichnen
  for i := clipRect.Left div pitch_width to (w div pitch_width) do
  begin
    j := i*pitch_width;

    // Taktstrich zeicnen
    if (i mod GriffPartitur_.GriffHeader.Details.MeasureFact) = 0 then
    begin
      if (clipRect.Left <= j) and (j < clipRect.Right) then
      begin
        canvas.Pen.Color := 0;
        Canvas.MoveTo(j - Horz_pos, 8 + MoveVert + NotenVersatz);
        Canvas.LineTo(j - Horz_pos, 5*8 + MoveVert + NotenVersatz);
      end;

    end;
    // oben blaue Striche
    canvas.Pen.Color := $ff7f7f;
    Canvas.MoveTo(j - Horz_pos, 8 + MoveVert + NotenVersatz);
    Canvas.LineTo(j - Horz_pos, 8 + MoveVert + NotenVersatz - 10);

    if j > clipRect.Right then
      break;
  end;


  canvas.Pen.Color := 0;
  canvas.Brush.Color := 0;
  canvas.Brush.Style := bsClear;
  for i := 0 to GriffPartitur_.GriffHeader.UsedEvents-1 do
    with GriffPartitur_, GriffEvents[i] do
    begin
      d := GetDuration;
      if (NoteType = ntBass) or
         not d.IsIntersect(tickDur) then
        continue;

      rect := AbsRect;
      rect.Left := round(rect.Left*quot);
      rect.Right := round(rect.Right*quot);
      rect.Offset(0, MoveVert);
      if not rect.IntersectsWith(clipRect) then
        continue;

      rect.Offset(-Horz_pos + 9, 0);
      rect.Top := (MaxGriffIndex - AbsRect.Top - 1)*4 - 28 + + MoveVert + NotenVersatz;

      // Zusatzstriche
      for j := 20 to AbsRect.Top+3 do
        if not odd(j) then
        begin
          k := (MaxGriffIndex-j)*4 + MoveVert + NotenVersatz - 16;
          canvas.MoveTo(rect.Left + 22, k);
          canvas.LineTo(rect.Left - 4, k);
        end;
      for j := 8 downto AbsRect.Top+3 do
        if not odd(j) then
        begin
          k := (MaxGriffIndex-j)*4 + MoveVert + NotenVersatz - 16;
          canvas.MoveTo(rect.Left + 22, k);
          canvas.LineTo(rect.Left - 4, k);
        end;

      j := round((GriffEvents[i].AbsRect.Width + GriffHeader.Details.DeltaTimeTicks/32.0)/(GriffHeader.Details.DeltaTimeTicks/4.0));
      case j of
        0, 1: Weight := nwShort;
        2:    Weight := nwEight;    // 2
        3:    Weight := nwEightDot;
        4, 5: Weight := nwQuarter;  // 4
        6:    Weight := nwQuarterDot;
        7..10: Weight := nwHalf;    // 8
        11..14: Weight := nwHalfDot;
        15..20: Weight := nwFull;  // 16
        else  Weight := nwFullDot
      end;
{      if (i + 1 < UsedEvents) and
         (Weight > nwQuarter) and (abs(AbsRect.Left - GriffEvents[i+1].AbsRect.Left) < 20) then
        Weight := nwQuarter;   }
      PaintNote(rect.Left, rect.Top, Cross, Weight);
    end;
  end;

var
  rect, rectSelected: TRect;
  CrossSelected: boolean;

  i, j: integer;
  smallDiff: integer;
  pushDur, noPushDur: integer;
  PushStart: integer;
  s: string;
  FontSize: integer;
  rhalbe: integer;
begin
  GriffPartitur_.SortEvents;

  canvas.Brush.Color := $ffffff;
  canvas.FillRect(clipRect);
  FontSize := Canvas.Font.Size;

  clipRect.Offset(Horz_pos, 0);

  quot := pitch_width/GriffPartitur_.GriffHeader.Details.GetMeasureDiv;
  tickDur.Left := trunc(clipRect.Left/quot);
  tickDur.Right := trunc(clipRect.Right/quot)+1;

  w:= pitch_width*GriffPartitur_.GetRelTotalDuration + 500;
  h:= row_height*(MaxGriffIndex+1);
  rhalbe := row_height div 2;

  // blaue Zeilen zeichnen
  canvas.Pen.Width := 1;
  Canvas.Pen.Color := $ff0000; // blau
  for i := 0 to MaxGriffIndex do
  begin
    if not odd(i) or
       (not GriffPartitur_.Instrument.bigInstrument and (i in [0..1, 25..26]))  then
      continue;

    if i in [8..16] then
      continue;

    rect.Create(0, i*row_height - 1 + rhalbe, w, 0);
    rect.Bottom := rect.Top + 1;
    rect.Offset(0, MoveVert);
    rect.Intersect(clipRect);
    dec(rect.Left);
    inc(rect.Right);
    rect.Offset(-Horz_pos, 0);
    if not rect.IsEmpty then
    begin
      canvas.MoveTo(rect.left, rect.Top);
      canvas.LineTo(rect.right, rect.Top);
    end;
  end;

  canvas.Pen.Width := 3;

  // senkrechte Striche zeichnen
  canvas.Brush.Color := $ffffff; // für Nummerierung
  smallDiff := 0;
  if not GriffPartitur_.Instrument.bigInstrument then
    smallDiff := 2;
  for i := clipRect.Left div pitch_width to (w div pitch_width) do
  begin
    if (i mod GriffPartitur_.GriffHeader.Details.MeasureFact) = 0 then
      Canvas.Pen.Color := $c0c0c0
    else
      Canvas.Pen.Color := $f0f0f0;
    j := i*pitch_width;
    if (clipRect.Left <= j) and (j < clipRect.Right) then
    begin
      Canvas.MoveTo(j - Horz_pos, MoveVert+smallDiff*row_height+rhalbe);
      Canvas.LineTo(j - Horz_pos, h+MoveVert-{smallDiff*}row_height+rhalbe);
    end;

    // Taktnummer
    if (i mod GriffPartitur_.GriffHeader.Details.MeasureFact) = 0 then
    begin
      s := IntToStr((i div GriffPartitur_.GriffHeader.Details.MeasureFact) + 1);
      Canvas.TextOut(j - Horz_pos -  Canvas.TextWidth(s) div 2,
                     2 + smallDiff*row_height, s);
    end;
    if j > clipRect.Right then
      break;
  end;

  // schwarze Zeilen zeichnen
  Canvas.Brush.Color := 0;
  for i := 0 to MaxGriffIndex do
  begin
     if not odd(i) or
       (not GriffPartitur_.Instrument.bigInstrument and (i in [0..2, 22..26]))  then
      continue;

    if not (i in [8..18]) then
      continue;

    rect.Create(0, i*row_height + rhalbe - 2, w, 0);
    rect.Bottom := rect.Top + 5;
    rect.Offset(0, MoveVert);
    rect.Intersect(clipRect);
    dec(rect.Left);
    inc(rect.Right);
    rect.Offset(-Horz_pos, 0);
    if not rect.IsEmpty then
      Canvas.FillRect(rect);
  end;

  rectSelected.Create(0, 0, 0, 0);
  CrossSelected := false;
  canvas.Pen.Color := $000000;
  // Noten-Rechtecke zeichnen
  for i := 0 to GriffPartitur_.GriffHeader.UsedEvents-1 do
    with GriffPartitur_.GriffEvents[i] do
    begin
      d := GetDuration;
      if not d.IsIntersect(tickDur) then
        continue;
      rect := AbsRect;
      rect.Left := round(rect.Left*quot);
      rect.Right := round(rect.Right*quot);
      rect.Top := (MaxGriffIndex - rect.Top)*row_height;
      rect.Height := row_height;
      inc(rect.Left, 2);
      dec(rect.Right, 1);
      rect.Offset(0, MoveVert);
      if not rect.IntersectsWith(clipRect) then
        continue;
      rect.Offset(-Horz_pos, 0);
      canvas.Brush.Color := GriffPartitur_.ColorNote;
      if (i = GriffPartitur_.Selected) and (NoteType <> ntBass) then
      begin
        rectSelected := rect;
        CrossSelected := Cross;
        continue;
      end;
      if NoteType <> ntBass then
      begin
        if NoteType > ntBass then
        begin
          if Repeat_ <> rRegular then
            canvas.Brush.Color := $00e0e0
          else
            canvas.Brush.Color := $ffffff;
        end else
        if Repeat_ > rRegular then
          canvas.Brush.Color := $00ffff
        else
        if InPush then
          canvas.Brush.Color := $ff00ff
        else
          canvas.Brush.Color := $ffff00; //ColorNote;
        DrawNote(rect);
        if Cross then
          DrawCross(rect);
      end else begin
        if not GriffPartitur_.Instrument.bigInstrument then
          rect.Offset(0, 2*row_height);
        if (GriffPitch in [1..8]) and GriffPartitur_.Instrument.bigInstrument then
        begin
          s := GetSteiBass;
        end else
          s := IntToStr(GriffPitch);
        if i = GriffPartitur_.Selected then
          canvas.Brush.Color := GriffPartitur_.ColorSelected
        else
        if Repeat_ > rRegular then
          canvas.Brush.Color := $00ffff
        else
        if GriffPartitur_.Instrument.BassDiatonic and InPush then
          canvas.Brush.Color := $df00df
        else
          canvas.Brush.Color := $ffffff;
//        fact := Canvas.TextWidth(s);
        if Cross  and not GriffPartitur_.Instrument.bigInstrument then
        begin
          Canvas.Font.Size := FontSize;
        end else begin
          Canvas.Font.Size := FontSize + 4;
         // rect.Offset(4, 0);
        end;
        rect.Offset(0, -smallDiff*row_height);
        Canvas.TextOut(rect.Left, rect.Top + rect.Height div 2, s);
      end;
    end;
    Canvas.Font.Size := FontSize;

  if not rectSelected.IsEmpty then
  begin
    if GriffPartitur_.GriffEvents[GriffPartitur_.Selected].NoteType = ntBass then
    begin
    end else begin
      canvas.Brush.Color := GriffPartitur_.ColorSelected;
      DrawNote(rectSelected);
      if CrossSelected then
      begin
        i := trunc(sqrt((sqr(GriffPartitur_.ColorSelected shr 16) +
                         sqr((GriffPartitur_.ColorSelected shr 8) and $ff) +
                         sqr(GriffPartitur_.ColorSelected and $ff)) / 3));
        if i >= $80 then
          canvas.Pen.Color := 0
        else
          canvas.Pen.Color := $ffffff;
        DrawCross(rectSelected);
      end;
    end;
  end;

  // Balg-Information
  PushStart := 0;
  for i := 0 to GriffPartitur_.GriffHeader.UsedEvents-1 do
  begin
    with GriffPartitur_.GriffEvents[i] do
    begin
      if not GriffPartitur_.GriffEvents[i].IsDiatonic(GriffPartitur_.Instrument) or
         not GetDuration.IsIntersect(tickDur) then
        continue;

      pushDur := GriffPartitur_.GetDrawDuration(i, true);
      noPushDur := GriffPartitur_.GetDrawDuration(i, false);
      if (noPushDur > 0) and (pushDur = 0) then
        continue;

      if (pushDur > 0) and (noPushDur > 0) then
        canvas.Brush.Color := $c0c0c0  // grau: ungültig
      else
        canvas.Brush.Color := $000000; // blau: push

      rect := AbsRect;
      if (NoteType = ntBass) and (rect.Width < GriffPartitur_.quarterNote div 2) then
        rect.Width := GriffPartitur_.quarterNote div 2;

      if PushStart > rect.Left then
        rect.Left := PushStart;
      rect.Create(round(quot*rect.Left), (MaxGriffIndex+3)*row_height,
                  round(quot*rect.Right),(MaxGriffIndex+4)*row_height);
      rect.Height := 6;
      rect.Offset(0, MoveVert + 2);
      rect.Intersect(clipRect);
      rect.Offset(-Horz_pos, 0);
      if not rect.IsEmpty then
        canvas.FillRect(rect);
      PushStart := AbsRect.Right;
    end;
  end;

  // play position
  canvas.Pen.Width := 1;
  if GriffPartitur_.playLocation-Horz_pos >= 0 then
  begin
    canvas.Pen.Color := $0000ff;
    if GriffPartitur_.Instrument.bigInstrument then
    begin
      canvas.MoveTo(GriffPartitur_.playLocation-Horz_pos, MoveVert);
      canvas.LineTo(GriffPartitur_.playLocation-Horz_pos, 25*row_height-2+MoveVert)
    end else begin
      canvas.MoveTo(GriffPartitur_.playLocation-Horz_pos, 3*row_height+MoveVert);
      canvas.LineTo(GriffPartitur_.playLocation-Horz_pos, 24*row_height-2+MoveVert);
    end;
  end;

  DrawSmallNotes(false);
//  DrawSmallNotes(true);

  Canvas.Font.Size := FontSize;
  canvas.Font.Style := [fsBold];
  canvas.Brush.Style := bsSolid;
end;

procedure TfrmGriff.GenerateNewNote(Event: UAmpel.TMouseEvent);
var
  GriffEvent: TGriffEvent;
begin
  if GriffPartitur_.PartiturLoaded and
     (Event.Row_ > 0) then
  begin
    if (GriffPartitur_.SelectedEvent <> nil) then
    begin
      GriffEvent := GriffPartitur_.SelectedEvent^;
      GriffEvent.AbsRect.Offset(GriffPartitur_.SelectedEvent.AbsRect.Width, 0);
    end else
      GriffEvent := GriffPartitur_.GriffEvents[GriffPartitur_.UsedEvents-1];
    GriffEvent.NoteType := ntDiskant;
    if Event.Row_ > 4 then
      GriffEvent.NoteType := ntBass;
    GriffEvent.Cross := Event.Row_ in [3,4];
    if Event.Row_ <= 4 then
    begin
      GriffEvent.SoundPitch :=
        GriffPartitur_.Instrument.RowIndexToSound(Event.Row_, Event.Index_, Event.Push_);
      GriffEvent.NoteType := ntDiskant;
      inc(Event.Index_, Event.Index_);
      if not odd(Event.Row_) then
        inc(Event.Index_);
      GriffEvent.GriffPitch := UInstrument.IndexToGriff(Event.Index_);
      GriffEvent.AbsRect.Top := Event.Index_;
    end else begin
      GriffEvent.GriffPitch := Event.Index_;
      GriffEvent.Cross := Event.Row_ = 6;
      if GriffPartitur_.Instrument.BassDiatonic and not Event.Push_ then
        GriffEvent.SoundPitch := GriffPartitur_.Instrument.PullBass[Event.Row_ = 6, Event.Index_]
      else
        GriffEvent.SoundPitch := GriffPartitur_.Instrument.Bass[Event.Row_ = 6, Event.Index_];
      GriffEvent.AbsRect.Top := -1;
    end;
    GriffEvent.AbsRect.Height := 1;
    GriffEvent.InPush := Event.Push_;
    GriffPartitur_.InsertNewSelected(GriffEvent);

    frmGriff.ShowSelected;
  end;
end;


end.
