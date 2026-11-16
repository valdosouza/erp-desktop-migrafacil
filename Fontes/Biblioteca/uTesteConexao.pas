unit uTesteConexao;

interface

type
  TTesteConexao = class
  public
    // ADatabase vazio = banco do Config.ini. Devolve a versao do MOTOR que respondeu
    // (ENGINE_VERSION, ex.: '2.5.1'); vazio se o servidor nao informar.
    class function Executar(const ADatabase: string = ''): string; static;
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, FireDAC.Comp.Client, FireDAC.Stan.Def,
  FireDAC.Phys.FBDef, FireDAC.Phys.FB, FireDAC.VCLUI.Wait,
  uConfigIni, uConst, uFbClientAutomatico;

class function TTesteConexao.Executar(const ADatabase: string): string;
var
  DriverLink: TFDPhysFBDriverLink;
  Connection: TFDConnection;
  Query: TFDQuery;
  QueryVersao: TFDQuery;
  ArquivoCliente: string;
begin
  Result := EmptyStr;
  // mesma regra do processo principal: fbclient 4.x do Bin ou o cliente proprio
  ArquivoCliente := TFbClientAutomatico.CaminhoCliente(ExtractFilePath(ParamStr(0)));
  if not FileExists(ArquivoCliente) then
    raise Exception.Create('Cliente Firebird 4.x do MigraFacil nao encontrado: ' +
      ArquivoCliente + '. Ele e baixado automaticamente pelo MigraFacil (fbclient.zip).');
  // runtime (msvcp140/vcruntime140) do cliente proprio fica na pasta dele
  SetDllDirectory(PChar(ExtractFilePath(ArquivoCliente)));

  DriverLink := TFDPhysFBDriverLink.Create(nil);
  try
    DriverLink.VendorLib := ArquivoCliente;
    Connection := TFDConnection.Create(nil);
    try
      Connection.LoginPrompt := False;
      Connection.Params.DriverID := 'FB';
      if ADatabase <> '' then
        Connection.Params.Values['Database'] := ADatabase
      else
        Connection.Params.Values['Database'] := TAppConfig.Database;
      Connection.Params.Values['lc_ctype'] := 'WIN1252';
      Connection.Params.Values['User_Name'] := 'sysdba';
      Connection.Params.Values['Password'] := 'masterkey';

      Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text := 'select 1 from rdb$database';
        Connection.Connected := True;
        Query.Open;
      finally
        Query.Free;
      end;

      // versao do motor que respondeu (2.1+). Falha aqui nao reprova a conexao:
      // quem chamou decide o que fazer com a versao desconhecida.
      try
        QueryVersao := TFDQuery.Create(nil);
        try
          QueryVersao.Connection := Connection;
          QueryVersao.SQL.Text :=
            'select rdb$get_context(''SYSTEM'', ''ENGINE_VERSION'') from rdb$database';
          QueryVersao.Open;
          Result := Trim(QueryVersao.Fields[0].AsString);
        finally
          QueryVersao.Free;
        end;
      except
        Result := EmptyStr;
      end;
    finally
      Connection.Free;
    end;
  finally
    try
      DriverLink.Release;
    finally
      DriverLink.Free;
    end;
  end;
end;

end.