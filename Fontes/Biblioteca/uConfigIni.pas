unit uConfigIni;

interface

uses
  System.SysUtils, System.IniFiles, Vcl.Forms;

type
  TAppConfig = class
  private
    class var FIni: TIniFile;

    class function Ini: TIniFile; static;
    class function IniPath: string; static;
    class function NormalizeDatabase(const Value: string): string; static;
  public
    class function Database: string;
    { Grava [Path] Database no Config.ini (forma normalizada, a mesma que o Gestao le). }
    class procedure SalvarDatabase(const Value: string); static;

    class procedure Finalize; static;
  end;

implementation

uses uConst;

class function TAppConfig.IniPath: string;
begin
  Result := ExtractFilePath(Application.ExeName) + CONFIG_INI;
end;

class function TAppConfig.Ini: TIniFile;
begin
  if FIni = nil then
    FIni := TIniFile.Create(IniPath);

  Result := FIni;
end;

class function TAppConfig.NormalizeDatabase(const Value: string): string;
begin
  Result := Trim(Value);
  if Result = EmptyStr then
    Exit;

  if (Length(Result) >= 3) and (Result[2] = ':') and
     ((Result[3] = '\') or (Result[3] = '/')) then
    Result := '127.0.0.1/3050:' + Result
  else if SameText(Copy(Result, 1, Length('localhost/')), 'localhost/') then
    Result := '127.0.0.1/' + Copy(Result, Length('localhost/') + 1, MaxInt)
  else if SameText(Copy(Result, 1, Length('localhost:')), 'localhost:') then
    Result := '127.0.0.1:' + Copy(Result, Length('localhost:') + 1, MaxInt);
end;

//[Path]
//Database=localhost/3050:C:\Modelo\Gestao2016\database\IBGCOM.FDB
//Database=127.0.0.1/3050:C:\Modelo\Gestao2016\database\IBGCOM.FDB
class function TAppConfig.Database: string;
begin
  Result := NormalizeDatabase(
    Ini.ReadString('Path', 'Database', EmptyStr));
end;

class procedure TAppConfig.SalvarDatabase(const Value: string);
begin
  Ini.WriteString('Path', 'Database', NormalizeDatabase(Value));
end;

class procedure TAppConfig.Finalize;
begin
  FIni.Free;
end;

initialization

finalization
  TAppConfig.Finalize;

end.

