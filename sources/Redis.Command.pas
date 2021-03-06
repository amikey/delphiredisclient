unit Redis.Command;

interface

uses
  System.SysUtils, System.Generics.Collections, Redis.Commons;

type
  TRedisCommand = class(TRedisClientBase, IRedisCommand)
  private
    FCommandIsSet: Boolean;
    function GetBinaryRedisToken(const Index: Integer): TBytes;
  protected
    FParts: TList<TBytes>;

  const
    ASTERISK_BYTE: Byte = Byte('*');
    DOLLAR_BYTE: Byte = Byte('$');
  public
    constructor Create(AIsUnicode: Boolean); virtual;
    destructor Destroy; override;
    function GetToken(const Index: Integer): TBytes;
    procedure Clear;
    function Count: Integer;
    function Add(ABytes: TBytes): IRedisCommand; overload;
    function Add(AString: string): IRedisCommand; overload;
    function SetCommand(AString: string): IRedisCommand; overload;
    function AddRange(AStrings: array of string): IRedisCommand;
    function ToRedisCommand: TBytes;
  end;

implementation

function TRedisCommand.Add(ABytes: TBytes): IRedisCommand;
begin
  FParts.Add(ABytes);
  Result := Self;
end;

function TRedisCommand.Add(AString: string): IRedisCommand;
begin
  FParts.Add(BytesOf(AString));
  Result := Self;
end;

function TRedisCommand.AddRange(AStrings: array of string): IRedisCommand;
var
  s: string;
begin
  for s in AStrings do
    Add(s);
  Result := Self;
end;

procedure TRedisCommand.Clear;
begin
  FParts.Clear;
  FCommandIsSet := False;
end;

function TRedisCommand.Count: Integer;
begin
  Result := FParts.Count;
end;

constructor TRedisCommand.Create(AIsUnicode: Boolean);
begin
  inherited Create;
  FParts := TList<TBytes>.Create;
  FUnicode := AIsUnicode;
end;

destructor TRedisCommand.Destroy;
begin
  FParts.Free;
  inherited;
end;

function TRedisCommand.GetBinaryRedisToken(
  const
  Index:
  Integer): TBytes;
begin
end;

function TRedisCommand.GetToken(
  const
  Index:
  Integer): TBytes;
begin
  Result := FParts[index];
end;

function TRedisCommand.SetCommand(AString: string): IRedisCommand;
begin
  FParts.Clear;
  FParts.Add(TEncoding.ASCII.GetBytes(AString));
  FCommandIsSet := True;
end;

function TRedisCommand.ToRedisCommand: TBytes;
var
  L: TList<Byte>;
  I: Integer;
begin
  if not FCommandIsSet then
    raise ERedisException.Create('Command is not set. Use SetCommand.');
  L := TList<Byte>.Create;
  try
    L.Add(ASTERISK_BYTE); // bytesof('*')[0]);
    L.AddRange(bytesof(IntToStr(Count)));
    L.Add(Byte(#13));
    L.Add(Byte(#10));

    for I := 0 to Count - 1 do
    begin
      L.Add(DOLLAR_BYTE); // bytesof('$')[0]);
      L.AddRange(bytesof(IntToStr(Length(FParts[I]))));
      L.Add(Byte(#13));
      L.Add(Byte(#10));
      L.AddRange(FParts[I]);
      L.Add(Byte(#13));
      L.Add(Byte(#10));
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

end.
