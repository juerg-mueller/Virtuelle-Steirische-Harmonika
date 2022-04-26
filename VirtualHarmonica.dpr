program VirtualHarmonica;

uses
  Vcl.Forms,
  UVirtualHarmonica in 'UVirtualHarmonica.pas' {frmVirtualHarmonica},
  UInstrument in 'UInstrument.pas',
  UEventArray in 'UEventArray.pas',
  UGriffArray in 'UGriffArray.pas',
  UGriffEvent in 'UGriffEvent.pas',
  UMyMemoryStream in 'UMyMemoryStream.pas',
  UMyMidiStream in 'UMyMidiStream.pas',
  UVirtual in 'UVirtual.pas',
  teVirtualMIDIdll in 'teVirtual\teVirtualMIDIdll.pas',
  Midi in 'Midi.pas',
  UAmpel in 'UAmpel.pas' {frmAmpel},
  UMidiDataStream in 'UMidiDataStream.pas',
  UFormHelper in 'UFormHelper.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmVirtualHarmonica, frmVirtualHarmonica);
  Application.CreateForm(TfrmAmpel, frmAmpel);
  Application.Run;
end.
