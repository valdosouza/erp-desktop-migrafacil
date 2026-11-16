unit uGestaoAtualizacao;

interface

uses
  System.SysUtils, Vcl.Graphics, uMigracaoContratos;

type
  TGestaoAtualizacao = class
  private
    FLog: TLogMigracaoEvent;
    FLogTecnico: TLogMigracaoEvent;
    FStatus: TStatusMigracaoEvent;
    FUltimoPercentual: Integer;
    procedure Log(const Texto: string; Cor: TColor);
    procedure LogTecnico(const Texto: string; Cor: TColor);
    procedure AtualizarStatus(const Texto: string);
    procedure HttpReceiveData(const Sender: TObject;
      AContentLength, AReadCount: Int64; var Abort: Boolean);
    procedure DownloadHttpFile(const Url, Destino: string);
    function DiretorioCache: string;
    function DiretorioExtraido: string;
    function ZipCache: string;
    function ZipLocal: string;
    function LocalizarExecutavelExtraido: string;
    function ExtrairPacote(const ArquivoZip: string): string;
    function ArquivoValido(const FileName: string): Boolean;
    function ProcessoGestaoExecutando: Boolean;
    procedure ValidarGestaoFechado;
    procedure SubstituirExecutavel(const NovoExecutavel: string);
  public
    constructor Create(const ALog, ALogTecnico: TLogMigracaoEvent;
      const AStatus: TStatusMigracaoEvent);
    function ExecutavelAtual: string;
    function CriarBackup(const DiretorioBackup: string): string;
    function ObterNovoExecutavel: string;
    procedure Preparar(const DiretorioBackup: string;
      var BackupCriado, NovoExecutavel: string);
    procedure Aplicar(const DiretorioBackup: string;
      var BackupCriado, NovoExecutavel: string);
  end;

implementation

uses
  Winapi.Windows, Winapi.TlHelp32, System.Classes, System.IOUtils,
  System.Types, System.Zip, System.Net.URLClient, System.Net.HttpClient,
  Vcl.Forms, uConst;

const
  CACHE_APLICACAO = 'SetesSafeMigrator';
  PASTA_ATUALIZACOES = 'Updates';
  PASTA_GESTAO = 'Gestao';
  ARQUIVO_PACOTE = 'gestao.zip';

constructor TGestaoAtualizacao.Create(const ALog,
  ALogTecnico: TLogMigracaoEvent; const AStatus: TStatusMigracaoEvent);
begin
  inherited Create;
  FLog := ALog;
  FLogTecnico := ALogTecnico;
  FStatus := AStatus;
end;

procedure TGestaoAtualizacao.Log(const Texto: string; Cor: TColor);
begin
  if Assigned(FLog) then
    FLog(Texto, Cor);
end;

procedure TGestaoAtualizacao.LogTecnico(const Texto: string; Cor: TColor);
begin
  if Assigned(FLogTecnico) then
    FLogTecnico(Texto, Cor);
end;

procedure TGestaoAtualizacao.AtualizarStatus(const Texto: string);
begin
  if Assigned(FStatus) then
    FStatus(Texto);
end;

function TGestaoAtualizacao.ExecutavelAtual: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    GESTAO_EXECUTAVEL;
end;

function TGestaoAtualizacao.DiretorioCache: string;
begin
  Result := TPath.Combine(TPath.GetTempPath, CACHE_APLICACAO);
  Result := TPath.Combine(Result, PASTA_ATUALIZACOES);
  Result := TPath.Combine(Result, PASTA_GESTAO);
end;

function TGestaoAtualizacao.DiretorioExtraido: string;
begin
  Result := TPath.Combine(DiretorioCache, 'extraido');
end;

function TGestaoAtualizacao.ZipCache: string;
begin
  Result := TPath.Combine(DiretorioCache, ARQUIVO_PACOTE);
end;

function TGestaoAtualizacao.ZipLocal: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    ARQUIVO_PACOTE;
end;

function TGestaoAtualizacao.ArquivoValido(const FileName: string): Boolean;
var
  Stream: TFileStream;
begin
  Result := False;
  if not FileExists(FileName) then
    Exit;

  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    Result := Stream.Size > 0;
  finally
    Stream.Free;
  end;
end;

function TGestaoAtualizacao.LocalizarExecutavelExtraido: string;
var
  Arquivos: TStringDynArray;
  Arquivo: string;
begin
  Result := EmptyStr;
  if not DirectoryExists(DiretorioExtraido) then
    Exit;

  Arquivos := TDirectory.GetFiles(DiretorioExtraido, GESTAO_EXECUTAVEL,
    TSearchOption.soAllDirectories);
  for Arquivo in Arquivos do
    if ArquivoValido(Arquivo) then
    begin
      Result := Arquivo;
      Exit;
    end;
end;

function TGestaoAtualizacao.ExtrairPacote(
  const ArquivoZip: string): string;
begin
  Result := EmptyStr;
  if not FileExists(ArquivoZip) then
    Exit;

  if DirectoryExists(DiretorioExtraido) then
    TDirectory.Delete(DiretorioExtraido, True);
  ForceDirectories(DiretorioExtraido);

  LogTecnico('Extraindo atualização do sistema Gestão...', clGray);
  AtualizarStatus('Extraindo atualização do sistema Gestão...');
  TZipFile.ExtractZipFile(ArquivoZip, DiretorioExtraido);

  Result := LocalizarExecutavelExtraido;
  if Result = EmptyStr then
    raise Exception.Create(
      'O gestao.zip foi extraído, mas Gestao.exe não foi encontrado.');

  Log('Atualização do Gestão pronta para aplicar.', clLime);
  LogTecnico('Novo Gestao.exe preparado em: ' + Result, clGray);
end;

procedure TGestaoAtualizacao.HttpReceiveData(const Sender: TObject;
  AContentLength, AReadCount: Int64; var Abort: Boolean);
var
  Percentual: Integer;
begin
  if AContentLength > 0 then
  begin
    Percentual := Integer((AReadCount * 100) div AContentLength);
    if Percentual > 100 then
      Percentual := 100;

    AtualizarStatus(Format('Baixando atualização do Gestão... %d%%',
      [Percentual]));
    if (Percentual = 100) or
       (Percentual >= FUltimoPercentual + 10) then
    begin
      FUltimoPercentual := Percentual;
      LogTecnico(Format('Download do gestao.zip: %d%%.',
        [Percentual]), clGray);
    end;
  end
  else
    AtualizarStatus(Format(
      'Baixando atualização do Gestão... %.1f MB recebidos.',
      [AReadCount / 1024 / 1024]));

  Application.ProcessMessages;
end;

procedure TGestaoAtualizacao.DownloadHttpFile(const Url, Destino: string);
var
  HttpClient: THTTPClient;
  Response: IHTTPResponse;
  FileStream: TFileStream;
  ArquivoParcial: string;
begin
  ArquivoParcial := Destino + '.download';
  if FileExists(ArquivoParcial) and
     (not DeleteFile(PChar(ArquivoParcial))) then
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
          'Servidor respondeu HTTP %d ao baixar gestao.zip.',
          [Response.StatusCode]);

      if FileExists(Destino) and (not DeleteFile(PChar(Destino))) then
        raise Exception.Create(
          'Não foi possível substituir o gestao.zip anterior: ' + Destino);

      if not RenameFile(ArquivoParcial, Destino) then
        raise Exception.Create(
          'Não foi possível finalizar o arquivo baixado: ' + Destino);
    except
      if FileExists(ArquivoParcial) then
        DeleteFile(PChar(ArquivoParcial));
      raise;
    end;
  finally
    HttpClient.Free;
  end;
end;

function TGestaoAtualizacao.ObterNovoExecutavel: string;
var
  PacoteCache: string;
  PacoteLocal: string;
  DownloadUrl: string;
begin
  ForceDirectories(DiretorioCache);
  PacoteCache := ZipCache;
  PacoteLocal := ZipLocal;
  DownloadUrl := GESTAO_ZIP_URL + '?v=' +
    FormatDateTime('yyyymmddhhnnss', Now);

  try
    Log('Baixando a versão mais recente do sistema Gestão...', clYellow);
    LogTecnico('URL da atualização: ' + DownloadUrl, clGray);
    LogTecnico('Destino do ZIP: ' + PacoteCache, clGray);
    DownloadHttpFile(DownloadUrl, PacoteCache);
    LogTecnico('Download da atualização do sistema Gestão concluído.', clGray);
  except
    on E: Exception do
    begin
      Log('Não foi possível baixar a versão mais recente do sistema Gestão. ' +
        'Tentando usar o cache local...', clYellow);
      LogTecnico('Falha ao baixar Gestao.zip: ' + E.Message, clRed);

      if FileExists(PacoteLocal) then
      begin
        Log('Usando gestao.zip ao lado do MigraFacil como alternativa offline.',
          clYellow);
        LogTecnico('Pacote local: ' + PacoteLocal, clGray);

        if FileExists(PacoteCache) and
           (not DeleteFile(PChar(PacoteCache))) then
          raise Exception.Create(
            'Não foi possível substituir o gestao.zip em cache: ' +
            PacoteCache);

        if not CopyFile(PChar(PacoteLocal), PChar(PacoteCache), True) then
          raise Exception.Create(
            'Não foi possível copiar o gestao.zip local para o cache.');

        Result := ExtrairPacote(PacoteCache);
        Exit;
      end;

      Result := LocalizarExecutavelExtraido;
      if Result <> EmptyStr then
      begin
        Log('Atualização do sistema Gestão carregada do cache offline.',
          clYellow);
        Exit;
      end;

      if FileExists(PacoteCache) then
      begin
        Result := ExtrairPacote(PacoteCache);
        Log('Atualização do sistema Gestão extraída do cache offline.',
          clYellow);
        Exit;
      end;

      raise Exception.Create(
        'Não foi possível baixar a atualização do sistema Gestão e ' +
        'não existe um cache local válido. ' + E.Message);
    end;
  end;

  Result := ExtrairPacote(PacoteCache);
end;
function TGestaoAtualizacao.ProcessoGestaoExecutando: Boolean;
var
  Snapshot: THandle;
  Entrada: TProcessEntry32;
begin
  Result := False;
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot = INVALID_HANDLE_VALUE then
    Exit;

  try
    ZeroMemory(@Entrada, SizeOf(Entrada));
    Entrada.dwSize := SizeOf(Entrada);
    if Process32First(Snapshot, Entrada) then
      repeat
        if SameText(string(Entrada.szExeFile), GESTAO_EXECUTAVEL) then
        begin
          Result := True;
          Exit;
        end;
      until not Process32Next(Snapshot, Entrada);
  finally
    CloseHandle(Snapshot);
  end;
end;

procedure TGestaoAtualizacao.ValidarGestaoFechado;
begin
  if ProcessoGestaoExecutando then
    raise Exception.Create(
      'Gestao.exe está em execução. Feche o sistema Gestão em todas as sessões antes de iniciar a migração.');
end;

function TGestaoAtualizacao.CriarBackup(
  const DiretorioBackup: string): string;
var
  Origem: string;
begin
  Result := EmptyStr;
  Origem := ExecutavelAtual;
  if not ArquivoValido(Origem) then
    raise Exception.Create(
      'Gestao.exe original não encontrado ao lado do MigraFacil: ' + Origem);

  if not DirectoryExists(DiretorioBackup) then
    ForceDirectories(DiretorioBackup);

  Result := IncludeTrailingPathDelimiter(DiretorioBackup) +
    ChangeFileExt(ExtractFileName(Origem), EmptyStr) +
    '_ORIGINAL_FB25_' + FormatDateTime('yyyymmdd_hhnnss', Now) +
    ExtractFileExt(Origem);

  Log('Copiando Gestao.exe original para segurança...', clYellow);
  LogTecnico('Destino da cópia do Gestao.exe: ' + Result, clGray);

  if not CopyFile(PChar(Origem), PChar(Result), True) then
    raise Exception.Create(
      'Não foi possível copiar o Gestao.exe original para segurança: ' +
      SysErrorMessage(GetLastError));

  if not ArquivoValido(Result) then
    raise Exception.Create(
      'A cópia de segurança do Gestao.exe não foi confirmada: ' + Result);

  Log('Gestao.exe original preservado em: ' + Result, clLime);
end;

procedure TGestaoAtualizacao.SubstituirExecutavel(
  const NovoExecutavel: string);
var
  Destino: string;
  ArquivoNovo: string;
  UltimoErro: DWORD;
begin
  Destino := ExecutavelAtual;
  if not ArquivoValido(Destino) then
    raise Exception.Create(
      'Gestao.exe original não encontrado para substituição: ' + Destino);
  if not ArquivoValido(NovoExecutavel) then
    raise Exception.Create(
      'Novo Gestao.exe não encontrado ou inválido: ' + NovoExecutavel);

  ValidarGestaoFechado;

  ArquivoNovo := Destino + '.novo';
  if FileExists(ArquivoNovo) and
     (not DeleteFile(PChar(ArquivoNovo))) then
    raise Exception.Create(
      'Não foi possível remover a atualização temporária anterior: ' +
      ArquivoNovo);

  if not CopyFile(PChar(NovoExecutavel), PChar(ArquivoNovo), True) then
    raise Exception.Create(
      'Não foi possível preparar o novo Gestao.exe: ' +
      SysErrorMessage(GetLastError));

  if not ArquivoValido(ArquivoNovo) then
  begin
    DeleteFile(PChar(ArquivoNovo));
    raise Exception.Create('O novo Gestao.exe preparado está inválido.');
  end;

  Log('Substituindo Gestao.exe pela nova versão...', clYellow);
  LogTecnico('Novo Gestao.exe: ' + NovoExecutavel, clGray);
  LogTecnico('Destino oficial: ' + Destino, clGray);

  if not MoveFileEx(PChar(ArquivoNovo), PChar(Destino),
    MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then
  begin
    UltimoErro := GetLastError;
    raise Exception.Create(
      'Não foi possível substituir Gestao.exe. O executável original foi mantido. ' +
      'A nova versão permanece em: ' + ArquivoNovo + '. Detalhe: ' +
      SysErrorMessage(UltimoErro));
  end;

  Log('Gestao.exe atualizado com sucesso.', clLime);
end;

procedure TGestaoAtualizacao.Preparar(const DiretorioBackup: string;
  var BackupCriado, NovoExecutavel: string);
begin
  ValidarGestaoFechado;

  if (BackupCriado = EmptyStr) or (not ArquivoValido(BackupCriado)) then
    BackupCriado := CriarBackup(DiretorioBackup);

  if (NovoExecutavel = EmptyStr) or
     (not ArquivoValido(NovoExecutavel)) then
    NovoExecutavel := ObterNovoExecutavel;
end;

procedure TGestaoAtualizacao.Aplicar(const DiretorioBackup: string;
  var BackupCriado, NovoExecutavel: string);
begin
  ValidarGestaoFechado;

  if (BackupCriado = EmptyStr) or (not ArquivoValido(BackupCriado)) then
    BackupCriado := CriarBackup(DiretorioBackup);

  if (NovoExecutavel = EmptyStr) or
     (not ArquivoValido(NovoExecutavel)) then
    NovoExecutavel := ObterNovoExecutavel;

  SubstituirExecutavel(NovoExecutavel);
end;

end.