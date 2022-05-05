program Virtual;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, UFormHelper, UGriffEvent, UInstrument, UMidiEvent, UMidiSaveStream,
  UMyMemoryStream, UMyMidiStream, UVirtualHarmonica, UBanks, UAmpel;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TfrmVirtualHarmonica, frmVirtualHarmonica);
  Application.CreateForm(TfrmAmpel, frmAmpel);
  Application.Run;
end.

