program VirtualHarmonica;

{$mode objfpc}{$H+}

uses
  {$ifdef unix}
  cthreads,
  pthreads,
  {$endif}
  UMidi in 'umidi.pas',
  {$ifdef mswindows}
  midi,
  {$else}
  RtMidi, Urtmidi,
  {$endif}
  Interfaces, // this includes the LCL widgetset
  Forms, UInstrument, UMyMidiStream, UMyMemoryStream, UMidiEvent,
  UVirtualHarmonica, UAmpel, UBanks, UMidiDataIn, UEventArray,
  UMidiDataStream;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TfrmVirtualHarmonica, frmVirtualHarmonica);
  Application.CreateForm(TfrmAmpel, frmAmpel);
  Application.Run;
end.

