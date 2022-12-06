unit Ujson;

interface

uses
  SysUtils, Classes,
  UMyMemoryStream, UFormHelper;

type
  TValueType = (vtNone, vtString, vtInt, vtVal);
  Tjson = class
    ValueType: TValueType;
    IsArray: boolean;
    Name: string;
    Value: AnsiString;
    List: array of Tjson;

    constructor Create;
    destructor Destroy; override;

    function Append: Tjson;
    function ListTree: string;
    procedure SaveToFile(FileName: string);
    function FindInList(SearchName: string): Tjson;
  end;

  // json EBNF    (rcf4627.txt)
  //
  // json-value ::= false | null | true | json-object | json-array | number | '"' string '"'
  // json-array ::= '[' [ json-value *( ',' json-value ) ] ']'
  // json-object ::= '{' [ json-member *( ',' json-member ) ] '}'
  // json-member ::= '"' string '"' ':' json-value
  // json-text ::= json-object | json-array

  TjsonParser = class(TMyMemoryStream)
    ErrPos: integer;

    constructor Create;
    procedure NeedChar(c: AnsiChar);
    function SkipSpaces: AnsiChar;
    procedure SetError;

    procedure ParseArray(Node: Tjson);
    function ParseFile(FileName: string; var Root: Tjson): boolean;

    class function LoadFromJsonFile(FileName: string; var Root: Tjson): boolean;
  end;

implementation

constructor Tjson.Create;
begin
  inherited;

  Name := '';
  Value := '';
  ValueType := vtNone;
  SetLength(List, 0);
end;

destructor Tjson.Destroy;
var
  i: integer;
begin
  for i := 0 to Length(List)-1 do
    List[i].Free;
  SetLength(List, 0);

  inherited;
end;

function Tjson.Append: TJson;
begin
  result := Tjson.Create;
  result.IsArray := true;
  SetLength(List, Length(List)+1);
  List[Length(List)-1] := result;
end;

constructor TjsonParser.Create;
begin
  inherited;

  ErrPos := -1;
end;

function TjsonParser.SkipSpaces: AnsiChar;
begin
  while (Position < Size) and
        (NextByte in [0..ord(' ')]) do
    ReadByte;
  result := AnsiChar(NextByte);
end;

procedure TjsonParser.NeedChar(c: AnsiChar);
begin
  if SkipSpaces = c then
    ReadByte
  else
    SetError;
end;

procedure TjsonParser.SetError;
begin
  if ErrPos < 0 then
    ErrPos := Position;
end;

function Tjson.ListTree: string;
const
  CR = '';
var
  i: integer;
begin
  result := '';
  if Name <> '' then
  begin
    result := '"' + Name + '"';
    result := result + ':';
  end;
  if Value <> '' then
  begin
    result := result + CR;
    if ValueType = vtString then
      result := result + '"';
    result := result + string(Value);
    if ValueType = vtString then
      result := result + '"';
  end else
  if Length(List) > 0 then
  begin
    if IsArray then
      result := result + '[' + CR
    else
      result := result + '{' + CR;

    for i:= 0 to Length(List)-1 do
    begin
      if i > 0 then
        result := result + ',';
      result := result + List[i].ListTree;
    end;
    if IsArray then
      result := result + CR + ']'
    else
      result := result + CR + '}';
  end;
end;

procedure Tjson.SaveToFile(FileName: string);
var
  s: String;
  UTF8: AnsiString;
  stream: TMyMemoryStream;
begin
  s := ListTree;
  UTF8 := UTF8encode(s);
  stream := TMyMemoryStream.Create;
  try
    stream.Size := Length(UTF8);
    Move(UTF8[1], PByte(stream.Memory)[0], Length(UTF8));
    stream.SaveToFile(FileName);
  finally
    stream.Free;
  end;
end;

procedure TjsonParser.ParseArray(Node: Tjson);
var
  c: AnsiChar;
  Comma: boolean;
  NewNode: Tjson;

  function GetString: AnsiString;
  var
    c: AnsiChar;
  begin
    result := '';
    NeedChar('"');
    c := AnsiChar(ReadByte);
    while (ErrPos < 0) and (c <> '"') do
    begin
      result := result + c;
      c := AnsiChar(ReadByte);
    end;
  end;

  function GetInt: string;
  var
    c: AnsiChar;
  begin
    result := '';
    c := SkipSpaces;
    if not (c in ['0'..'9', '-', '+']) then
      SetError;
    repeat
      ReadByte;
      result := result + Char(c);
      c := AnsiChar(NextByte);
    until not (c in ['0'..'9', '.', 'E', 'e']) or (ErrPos >= 0);
  end;

  function GetValue: string;
  var
    c: AnsiChar;
  begin
    result := '';
    c := SkipSpaces;
    if not (c in ['a'..'z']) then
      SetError;
    repeat
      ReadByte;
      result := result + Char(c);
      c := AnsiChar(NextByte);
    until not (c in ['a'..'z']);
  end;

  function GetJsonValue(Node: Tjson): string;
  var
    c: AnsiChar;
  begin
    result := '';
    c := SkipSpaces;
    if c in [']', '}'] then
    begin
    end else
    if c = '"' then
    begin
      Node.ValueType := vtString;
      result := UTF8ToString(GetString)
    end else
    if c in ['a'..'z'] then
    begin
      Node.ValueType := vtVal;
      result := GetValue
    end else begin
      Node.ValueType := vtInt;
      result := GetInt;
    end;
    Node.Value := AnsiString(result);
  end;

begin
  if ErrPos >= 0 then
    exit;

  c := SkipSpaces;
  if c in ['{', '['] then
  begin
    Node.IsArray := c = '[';
    ReadByte;
  end else
    SetError;

  c := SkipSpaces;
  repeat
    NewNode := Node.Append;
    if not Node.IsArray then
    begin
      NewNode.Name := string(GetString);
      NeedChar(':');
      c := SkipSpaces;
    end;
    if c in ['[', '{'] then
    begin
      ParseArray(NewNode);
    end else
      GetJsonValue(NewNode);
    Comma := SkipSpaces = ',';
    if Comma then
      ReadByte;
  until not Comma or (ErrPos >= 0);

  if Node.IsArray then
    c := ']'
  else
    c := '}';
  NeedChar(c);
end;

function TjsonParser.ParseFile(FileName: string; var Root: Tjson): boolean;
var
  i, k: integer;
  s: string;
begin
  LoadFromFile(FileName);
  ParseArray(Root);
  result := ErrPos < 0;
  if not result then
  begin
    i := ErrPos - 10;
    if i < 0 then
      i := 0;
    k := 0;
    s := '';
    while (i + k < Size) and (k < 30) do
    begin
      s := s + Char(AnsiChar(GetByte(i + k)));
      inc(k);
    end;
{$ifdef CONSOLE}
    system.writeln(s);
{$else}
    ErrMessage('Parser Error: ' + s);
{$endif}
  end;
end;

class function TjsonParser.LoadFromJsonFile(FileName: string; var Root: Tjson): boolean;
var
  Parser: TjsonParser;
begin
  result := false;
  if not FileExists(FileName) then
    exit;

  Root := Tjson.Create;
  Parser := TjsonParser.Create;
  try
    result := Parser.ParseFile(FileName, Root);
   // Root.SaveToFile(Filename + '_.json');
  finally
    Parser.Free;
    if not result then
      FreeAndNil(Root);
  end;
end;

function Tjson.FindInList(SearchName: string): Tjson;
var
  i: integer;
begin
  result := nil;
  for i := 0 to Length(List)-1 do
    if List[i].Name = SearchName then
    begin
      result := List[i];
      break;
    end;
end;


end.
