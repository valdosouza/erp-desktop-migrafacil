unit uFirebirdPacotes;

interface

uses
  System.SysUtils, Vcl.Graphics, uMigracaoContratos, Winapi.Windows;

type
  TFirebirdPacotes = class
  private type
    TConfiguracaoPacote = record
      NomeVersao: string;
      PastaCache: string;
      InstaladorX64: string;
      InstaladorX86: string;
      UrlX64: string;
      UrlX86: string;
      AceitarX86ComoAlternativo: Boolean;
    end;
  private
    FLog: TLogMigracaoEvent;
    FLogTecnico: TLogMigracaoEvent;
    FStatus: TStatusMigracaoEvent;
    FNomeVersao: string;
    FUltimoPercentual: Integer;
    constructor Create(const ALog, ALogTecnico: TLogMigracaoEvent;
      const AStatus: TStatusMigracaoEvent);
    procedure Log(const Texto: string; Cor: TColor);
    procedure LogTecnico(const Texto: string; Cor: TColor);
    procedure AtualizarStatus(const Texto: string);
    procedure HttpReceiveData(const Sender: TObject;
      AContentLength, AReadCount: Int64; var Abort: Boolean);
    procedure DownloadHttpFile(const Url, Destino: string);
    function ObterInstalador(const Config: TConfiguracaoPacote): string;
  public
    class function ObterInstalador5(
      const Log, LogTecnico: TLogMigracaoEvent;
      const Status: TStatusMigracaoEvent): string; static;
    class function ObterInstalador25(
      const Log, LogTecnico: TLogMigracaoEvent;
      const Status: TStatusMigracaoEvent): string; static;
  end;

implementation

uses
  System.Classes, System.IOUtils, System.Types, System.Zip,
  System.Net.URLClient, System.Net.HttpClient, Vcl.Forms,
  uFirebirdAmbiente;

const
  CACHE_APLICACAO = 'SetesSafeMigrator';

constructor TFirebirdPacotes.Create(const ALog, ALogTecnico: TLogMigracaoEvent;
  const AStatus: TStatusMigracaoEvent);
begin
  inherited Create;
  FLog := ALog;
  FLogTecnico := ALogTecnico;
  FStatus := AStatus;
end;

procedure TFirebirdPacotes.Log(const Texto: string; Cor: TColor);
begin
  if Assigned(FLog) then
    FLog(Texto, Cor);
end;

procedure TFirebirdPacotes.LogTecnico(const Texto: string; Cor: TColor);
begin
  if Assigned(FLogTecnico) then
    FLogTecnico(Texto, Cor);
end;

procedure TFirebirdPacotes.AtualizarStatus(const Texto: string);
begin
  if Assigned(FStatus) then
    FStatus(Texto);
end;

procedure TFirebirdPacotes.HttpReceiveData(const Sender: TObject;
  AContentLength, AReadCount: Int64; var Abort: Boolean);
var
  Percentual: Integer;
begin
  if AContentLength > 0 then
  begin
    Percentual := Integer((AReadCount * 100) div AContentLength);
    if Percentual > 100 then
      Percentual := 100;

    AtualizarStatus(Format('Baixando instalador do %s... %d%%',
      [FNomeVersao, Percentual]));

    if (Percentual = 100) or
       (Percentual >= FUltimoPercentual + 10) then
    begin
      FUltimoPercentual := Percentual;
      LogTecnico(Format('Download do %s: %d%%.',
        [FNomeVersao, Percentual]), clGray);
    end;
  end
  else
    AtualizarStatus(Format(
      'Baixando instalador do %s... %.1f MB recebidos.',
      [FNomeVersao, AReadCount / 1024 / 1024]));

  Application.ProcessMessages;
end;

procedure TFirebirdPacotes.DownloadHttpFile(const Url, Destino: string);
var
  HttpClient: THTTPClient;
  Response: IHTTPResponse;
  FileStream: TFileStream;
  ArquivoParcial: string;
begin
  ArquivoParcial := Destino + '.download';

  if FileExists(ArquivoParcial) and (not DeleteFile(Pchar(ArquivoParcial))) then
    raise Exception.Create(
      'Não foi possível remover o download incompleto anterior: ' +
      ArquivoParcial);

  HttpClient := THTTPClient.Create;
  try
    HttpClient.ConnectionTimeout := 15000;
    HttpClient.ResponseTimeout := 300000;
    HttpClient.OnReceiveData := HttpReceiveData;
    FUltimoPercentual := -10;

    try
      FileStream := TFileStream.Create(ArquivoParcial, fmCreate);
      try
        Response := HttpClient.Get(Url, FileStream);
      finally
        FileStream.Free;
      end;

      if (Response.StatusCode < 200) or (Response.StatusCode >= 300) then
        raise Exception.CreateFmt(
          'Servidor respondeu HTTP %d ao baixar o instalador.',
          [Response.StatusCode]);

      if FileExists(Destino) and (not DeleteFile(Pchar(Destino))) then
        raise Exception.Create(
          'Não foi possível substituir o ZIP anterior: ' + Destino);

      if not RenameFile(ArquivoParcial, Destino) then
        raise Exception.Create(
          'Não foi possível finalizar o arquivo baixado: ' + Destino);
    except
      if FileExists(ArquivoParcial) then
        DeleteFile(Pchar(ArquivoParcial));
      raise;
    end;
  finally
    HttpClient.Free;
  end;
end;

function TFirebirdPacotes.ObterInstalador(
  const Config: TConfiguracaoPacote): string;
var
  Windows64: Boolean;
  InstallerName: string;
  DownloadUrl: string;
  DiretorioTemporario: string;
  DiretorioExtraido: string;
  ZipFileName: string;
  InstallerLocal: string;
  InstallerLocalAlternativo: string;
  ArquivosEncontrados: TStringDynArray;

  function LocalizarInstaladorExtraido: string;
  begin
    Result := EmptyStr;
    ArquivosEncontrados := TDirectory.GetFiles(DiretorioExtraido,
      InstallerName, TSearchOption.soAllDirectories);

    if Length(ArquivosEncontrados) = 0 then
      ArquivosEncontrados := TDirectory.GetFiles(DiretorioExtraido,
        'Firebird*.exe', TSearchOption.soAllDirectories);

    if Length(ArquivosEncontrados) > 0 then
      Result := ArquivosEncontrados[0];
  end;

  function ExtrairZipExistente: Boolean;
  begin
    Result := False;
    if not FileExists(ZipFileName) then
      Exit;

    Log('ZIP do ' + Config.NomeVersao +
      ' já encontrado no cache temporário.', clAqua);
    LogTecnico('ZIP em cache: ' + ZipFileName, clGray);
    Log('Extraindo o instalador do ' + Config.NomeVersao + '...', clYellow);
    AtualizarStatus('Extraindo instalador do ' + Config.NomeVersao + '...');

    TZipFile.ExtractZipFile(ZipFileName, DiretorioExtraido);
    Result := LocalizarInstaladorExtraido <> EmptyStr;
  end;
begin
  Windows64 := TFirebirdAmbiente.WindowsEh64Bits;
  FNomeVersao := Config.NomeVersao;

  if Windows64 then
  begin
    InstallerName := Config.InstaladorX64;
    DownloadUrl := Config.UrlX64;
  end
  else
  begin
    InstallerName := Config.InstaladorX86;
    DownloadUrl := Config.UrlX86;
  end;

  InstallerLocal := IncludeTrailingPathDelimiter(
    ExtractFilePath(ParamStr(0))) + InstallerName;
  InstallerLocalAlternativo := EmptyStr;
  if Config.AceitarX86ComoAlternativo then
    InstallerLocalAlternativo := IncludeTrailingPathDelimiter(
      ExtractFilePath(ParamStr(0))) + Config.InstaladorX86;

  DiretorioTemporario := TPath.Combine(TPath.GetTempPath, CACHE_APLICACAO);
  DiretorioTemporario := TPath.Combine(DiretorioTemporario, 'Installers');
  DiretorioTemporario := TPath.Combine(DiretorioTemporario,
    Config.PastaCache);

  if Windows64 then
    DiretorioTemporario := TPath.Combine(DiretorioTemporario, 'x64')
  else
    DiretorioTemporario := TPath.Combine(DiretorioTemporario, 'x86');

  DiretorioExtraido := TPath.Combine(DiretorioTemporario, 'extraido');
  ZipFileName := TPath.Combine(DiretorioTemporario,
    ChangeFileExt(InstallerName, '.zip'));
  ForceDirectories(DiretorioExtraido);

  Result := LocalizarInstaladorExtraido;
  if Result <> EmptyStr then
  begin
    Log('Instalador do ' + Config.NomeVersao +
      ' encontrado no cache temporário.', clAqua);
    LogTecnico('Instalador em cache: ' + Result, clGray);
    Exit;
  end;

  if FileExists(InstallerLocal) then
  begin
    Result := InstallerLocal;
    Log('Instalador do ' + Config.NomeVersao +
      ' encontrado ao lado do migrador.', clAqua);
    LogTecnico('Instalador local: ' + Result, clGray);
    Exit;
  end;

  if (InstallerLocalAlternativo <> EmptyStr) and
     (not SameText(InstallerLocalAlternativo, InstallerLocal)) and
     FileExists(InstallerLocalAlternativo) then
  begin
    Result := InstallerLocalAlternativo;
    Log('Instalador do ' + Config.NomeVersao +
      ' encontrado ao lado do migrador.', clAqua);
    LogTecnico('Instalador local: ' + Result, clGray);
    Exit;
  end;

  try
    if ExtrairZipExistente then
    begin
      Result := LocalizarInstaladorExtraido;
      Log('Instalador extraído com sucesso.', clLime);
      LogTecnico('Instalador extraído: ' + Result, clGray);
      Exit;
    end;
  except
    on E: Exception do
      LogTecnico('Falha ao usar ZIP em cache do ' + Config.NomeVersao +
        ': ' + E.Message, clRed);
  end;

  try
    Log('Baixando o instalador do ' + Config.NomeVersao + ' para ' +
      TFirebirdAmbiente.ArquiteturaWindows + '...', clYellow);
    LogTecnico('URL do instalador: ' + DownloadUrl, clGray);
    LogTecnico('Destino do ZIP: ' + ZipFileName, clGray);

    DownloadHttpFile(DownloadUrl, ZipFileName);
    Log('Download do ' + Config.NomeVersao + ' concluído.', clLime);

    if not ExtrairZipExistente then
      raise Exception.Create(
        'O ZIP foi extraído, mas o instalador não foi encontrado: ' +
        InstallerName);

    Result := LocalizarInstaladorExtraido;
    Log('Instalador extraído com sucesso.', clLime);
    LogTecnico('Instalador extraído: ' + Result, clGray);
  except
    on E: Exception do
    begin
      Log('Não foi possível baixar ou extrair o instalador: ' +
        E.Message, clRed);

      if FileExists(InstallerLocal) then
        Result := InstallerLocal
      else if (InstallerLocalAlternativo <> EmptyStr) and
              FileExists(InstallerLocalAlternativo) then
        Result := InstallerLocalAlternativo
      else
        raise Exception.Create('Não foi possível preparar o instalador do ' +
          Config.NomeVersao + '. ' + E.Message);

      Log('Usando o instalador local como alternativa.', clYellow);
      LogTecnico('Instalador local: ' + Result, clGray);
    end;
  end;
end;

class function TFirebirdPacotes.ObterInstalador5(
  const Log, LogTecnico: TLogMigracaoEvent;
  const Status: TStatusMigracaoEvent): string;
var
  Pacotes: TFirebirdPacotes;
  Config: TConfiguracaoPacote;
begin
  Config.NomeVersao := 'Firebird 5';
  Config.PastaCache := 'Firebird5';
  Config.InstaladorX64 := 'Firebird-5.0.4.1812-0-windows-x64.exe';
  Config.InstaladorX86 := 'Firebird-5.0.4.1812-0-windows-x86.exe';
  Config.UrlX64 := 'https://www.setes.com.br/Gestao2026/Firebird-5.0.4.1812-0-windows-x64.zip';
  Config.UrlX86 := 'https://www.setes.com.br/Gestao2026/Firebird-5.0.4.1812-0-windows-x86.zip';
  Config.AceitarX86ComoAlternativo := False;

  Pacotes := TFirebirdPacotes.Create(Log, LogTecnico, Status);
  try
    Result := Pacotes.ObterInstalador(Config);
  finally
    Pacotes.Free;
  end;
end;

class function TFirebirdPacotes.ObterInstalador25(
  const Log, LogTecnico: TLogMigracaoEvent;
  const Status: TStatusMigracaoEvent): string;
var
  Pacotes: TFirebirdPacotes;
  Config: TConfiguracaoPacote;
begin
  Config.NomeVersao := 'Firebird 2.5';
  Config.PastaCache := 'Firebird25';
  Config.InstaladorX64 := 'Firebird-2.5.x64.exe';
  Config.InstaladorX86 := 'Firebird-2.5.exe';
  Config.UrlX64 := 'https://www.setes.com.br/Gestao2016/Firebird-2.5.x64.zip';
  Config.UrlX86 := 'https://www.setes.com.br/Gestao2016/Firebird-2.5.zip';
  Config.AceitarX86ComoAlternativo := True;

  Pacotes := TFirebirdPacotes.Create(Log, LogTecnico, Status);
  try
    Result := Pacotes.ObterInstalador(Config);
  finally
    Pacotes.Free;
  end;
end;

end.