unit UGenInstrList;

interface
uses
  SysUtils, Classes, IOUtils,
  UInstrument, Ujson, UMyMemoryStream;

var
  InstrumentList_: array of TInstrument;

implementation

uses
  UFormHelper;

var
  NewInstrument: TInstrument;

procedure AddInstrument(FileName: string);
var
  Root: Tjson;
  Instrument: TInstrument;
begin
  if TjsonParser.LoadFromJsonFile(FileName, Root) then
  begin
    Instrument := NewInstrument;
    if Instrument.UseJson(Root) then
    begin
      SetLength(InstrumentList_, Length(InstrumentList_)+1);
      InstrumentList_[Length(InstrumentList_)-1] := Instrument;
    end;
  end;
end;

procedure ReadInstruments(Path: string);
var
  SR      : TSearchRec;
  DirList : TStringList;
  i: integer;
begin
  SetLength(InstrumentList_, 0);
{$if defined(WIN32) or defined(WIN64)}
  DirList := TStringList.Create;
  if FindFirst(Path + '*.json', faNormal, SR) = 0 then
  begin
    repeat
      DirList.Add(SR.Name); //Fill the list
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;

  for i := 0 to DirList.Count-1 do
    AddInstrument(Path + DirList[i]);

  DirList.Free;
{$endif}
  if Length(InstrumentList_) = 0 then
  begin
    Warning('No instruments found!'#10#13'The internal ones are therefore used.');
    SetLength(InstrumentList_, Length(InstrumentList));
    for i := 0 to Length(InstrumentList)-1 do
    begin
      InstrumentList_[i] := InstrumentList[i]^;
    end;
  end;
end;

begin
  if DirectoryExists('../../instruments') then
    ReadInstruments('../../instruments/')
  else
    ReadInstruments('instruments/');
end.

