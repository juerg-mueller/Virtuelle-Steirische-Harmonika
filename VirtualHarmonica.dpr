program VirtualHarmonica;

uses
  Vcl.Forms,
  UVirtualHarmonica in 'UVirtualHarmonica.pas' {frmVirtualHarmonica},
  UGriffEvent in 'UGriffEvent.pas',
  UVirtual in 'UVirtual.pas',
  teVirtualMIDIdll in 'teVirtual\teVirtualMIDIdll.pas',
  Midi in 'Midi.pas',
  UAmpel in 'UAmpel.pas' {frmAmpel},
  UFormHelper in 'UFormHelper.pas',
  UMidiEvent in 'UMidiEvent.pas',
  UInstrument in 'UInstrument.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmVirtualHarmonica, frmVirtualHarmonica);
  Application.CreateForm(TfrmAmpel, frmAmpel);
  Application.Run;
end.
