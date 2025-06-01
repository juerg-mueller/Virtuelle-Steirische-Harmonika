program VirtualHarmonica;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  {$ifdef mswindows}
  midi,
  {$else}
  RtMidi, Urtmidi,
  {$endif}
  Interfaces, // this includes the LCL widgetset
  Forms, UInstrument, UMyMidiStream, UMyMemoryStream,
  UMidiSaveStream, UMidiEvent,
  UVirtualHarmonica, UAmpel, UBanks, UMidi;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TfrmVirtualHarmonica, frmVirtualHarmonica);
  Application.CreateForm(TfrmAmpel, frmAmpel);
  Application.Run;
end.

