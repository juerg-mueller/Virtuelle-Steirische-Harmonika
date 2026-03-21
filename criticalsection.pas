unit CriticalSection;

interface

uses
{$ifdef use_get32}
  SyncObjs,
{$endif}
  Classes, SysUtils;

type
{$ifdef fpc}
  TCriticalSection = class
  private
    Critical: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy;

    function Acquire: boolean;
    procedure Release;
  end;
{$else}
  TCriticalSection = class
  private
    Critical: syncobjs.TCriticalSection;
  public
    constructor Create;
    destructor Destroy;

    function Acquire: boolean;
    procedure Release;
  end;
{$endif}

implementation

{$ifdef fpc}
constructor TCriticalSection.Create;
begin
  InitCriticalSection(Critical);
end;

destructor TCriticalSection.Destroy;
begin
  DoneCriticalsection(Critical);
end;

function TCriticalSection.Acquire: boolean;
begin
  EnterCriticalSection(Critical);
  result := true;
end;

procedure TCriticalSection.Release;
begin
  LeaveCriticalsection(Critical);
end;

{$else}

constructor TCriticalSection.Create;
begin
  Critical := syncobjs.TCriticalSection.Create;
end;

destructor TCriticalSection.Destroy;
begin
  Critical.Free;
end;

function TCriticalSection.Acquire: boolean;
begin
  result := true;
  Critical.Acquire;
end;

procedure TCriticalSection.Release;
begin
  Critical.Release;
end;
{$endif}

end.

