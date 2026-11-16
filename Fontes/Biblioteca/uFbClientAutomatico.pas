unit uFbClientAutomatico;

{ Cliente Firebird 4.x (x86) do proprio MigraFacil.

  O MigraFacil precisa de um fbclient 4.x: ele fala com o Firebird 2.5 (antes) e
  com o 5.0 (testes do banco convertido). Decisao de 03/10/2026 (Valdo): MigraFacil
  e GestaoUpdate sao independentes, entao o Bin pode estar em qualquer fase. O
  cliente usado e escolhido assim (CaminhoCliente, mesma regra no processo
  principal e no filho /testeconexao):
    1) <pasta do exe>\fbclient.dll, se for 4.x ou superior (Bin ja no pacote 2026);
    2) senao, <pasta do exe>\FbClientMigraFacil\fbclient.dll (cliente proprio).
  O fbclient.dll do Bin NUNCA e alterado aqui: o Bin e do GestaoUpdate.

  Garantir baixa o cliente proprio quando falta: <site>/Gestao2026/fbclient.zip
  (fbclient.dll + runtime VC++), publicado junto com o atualizacao.ini (chaves
  opcionais FbClientZip, FbClientBytes e FbClientSHA256, gravadas pelo
  publica-atualizacao.ps1). Um fbclient.zip ao lado do .exe vale como alternativa
  offline.

  Regras:
  - A DLL nunca e carregada neste processo (so lida como arquivo); senao
    ValidarFbClientDescarregado acusaria o cliente carregado.
  - Sempre confere arquitetura (x86) e versao principal (>= 4) da DLL; confere o
    tamanho e o SHA256 do zip quando o atualizacao.ini os informa.
  - O runtime (msvcp140 etc.) vai para a mesma subpasta do cliente proprio; o
    processo filho chama SetDllDirectory nela antes de carregar o fbclient. }

interface

uses
  System.SysUtils, uMigracaoContratos;

type
  TFbClientAutomatico = class
  public
    const
      PASTA_CLIENTE_PROPRIO = 'FbClientMigraFacil';
      VERSAO_MINIMA = 4;
    // fbclient.dll que o MigraFacil usa (pode ainda nao existir: ver Garantir).
    class function CaminhoCliente(const PastaExe: string): string; static;
    // Devolve o fbclient.dll a usar, baixando o cliente proprio se preciso.
    // Levanta excecao com orientacao quando nao consegue obter um cliente valido.
    class function Garantir(const PastaExe: string;
      const Log, LogTecnico: TLogMigracaoEvent;
      const Status: TStatusMigracaoEvent): string; static;
  end;

implementation

uses
  Winapi.Windows, System.Classes, System.IOUtils, System.IniFiles, System.Hash,
  System.Zip, System.Types, System.Net.URLClient, System.Net.HttpClient,
  Vcl.Graphics, Vcl.Forms, uConst, uPreRequisitosConversao;

const
  CACHE_APLICACAO = 'SetesSafeMigrator';
  PASTA_CACHE = 'FbClient';
  MAQUINA_X86 = $014C;

type
  TFbClientDownload = class
  private
    FLog: TLogMigracaoEvent;
    FLogTecnico: TLogMigracaoEvent;
    FStatus: TStatusMigracaoEvent;
    FUltimoPercentual: Integer;
    procedure Info(const Texto: string; Cor: TColor);
    procedure Tecnico(const Texto: string; Cor: TColor);
    procedure AtualizarStatus(const Texto: string);
    procedure ReceberDados(const Sender: TObject; AContentLength,
      AReadCount: Int64; var Abort: Boolean);
    function DiretorioCache: string;
    procedure LerPublicacao(out ZipNome: string; out Bytes: Int64;
      out Sha: string);
    procedure Baixar(const Url, Destino: string);
    procedure ConferirZip(const Zip: string; Bytes: Int64; const Sha: string);
    procedure Instalar(const Zip, PastaDestino: string);
  public
    constructor Create(const ALog, ALogTecnico: TLogMigracaoEvent;
      const AStatus: TStatusMigracaoEvent);
    procedure Executar(const PastaExe, PastaDestino: string);
  end;

function TamanhoArquivo(const Arquivo: string): Int64;
var
  Fs: TFileStream;
begin
  Fs := TFileStream.Create(Arquivo, fmOpenRead or fmShareDenyNone);
  try
    Result := Fs.Size;
  finally
    Fs.Free;
  end;
end;

// Campo Machine do cabecalho PE ($014C = x86, $8664 = x64); 0 = nao e PE valido.
function MaquinaDoPE(const Arquivo: string): Word;
var
  Fs: TFileStream;
  Dos: array[0..63] of Byte;
  Offset: Integer;
  Assinatura: Cardinal;
  Maquina: Word;
begin
  Result := 0;
  Fs := TFileStream.Create(Arquivo, fmOpenRead or fmShareDenyNone);
  try
    if Fs.Size < SizeOf(Dos) then
      Exit;
    Fs.ReadBuffer(Dos, SizeOf(Dos));
    if (Dos[0] <> Ord('M')) or (Dos[1] <> Ord('Z')) then
      Exit;
    Offset := PInteger(@Dos[$3C])^;
    if (Offset <= 0) or (Int64(Offset) + 6 > Fs.Size) then
      Exit;
    Fs.Position := Offset;
    Fs.ReadBuffer(Assinatura, SizeOf(Assinatura));
    if Assinatura <> $00004550 then
      Exit;
    Fs.ReadBuffer(Maquina, SizeOf(Maquina));
    Result := Maquina;
  finally
    Fs.Free;
  end;
end;

// Copia via arquivo .novo + MoveFileEx: nunca deixa DLL pela metade no destino.
procedure CopiarArquivo(const Origem, Destino: string; SoSeNaoExistir: Boolean);
var
  Temporario: string;
  Erro: DWORD;
begin
  if SoSeNaoExistir and FileExists(Destino) then
    Exit;
  Temporario := Destino + '.novo';
  if not CopyFile(PChar(Origem), PChar(Temporario), False) then
    raise Exception.Create('Nao foi possivel gravar ' + Temporario + ': ' +
      SysErrorMessage(GetLastError));
  if not MoveFileEx(PChar(Temporario), PChar(Destino),
    MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then
  begin
    Erro := GetLastError;
    System.SysUtils.DeleteFile(Temporario);
    raise Exception.Create('Nao foi possivel gravar ' + Destino + ': ' +
      SysErrorMessage(Erro));
  end;
end;

{ TFbClientDownload }

constructor TFbClientDownload.Create(const ALog, ALogTecnico: TLogMigracaoEvent;
  const AStatus: TStatusMigracaoEvent);
begin
  inherited Create;
  FLog := ALog;
  FLogTecnico := ALogTecnico;
  FStatus := AStatus;
end;

procedure TFbClientDownload.Info(const Texto: string; Cor: TColor);
begin
  if Assigned(FLog) then
    FLog(Texto, Cor);
end;

procedure TFbClientDownload.Tecnico(const Texto: string; Cor: TColor);
begin
  if Assigned(FLogTecnico) then
    FLogTecnico(Texto, Cor);
end;

procedure TFbClientDownload.AtualizarStatus(const Texto: string);
begin
  if Assigned(FStatus) then
    FStatus(Texto);
end;

procedure TFbClientDownload.ReceberDados(const Sender: TObject; AContentLength,
  AReadCount: Int64; var Abort: Boolean);
var
  Percentual: Integer;
begin
  if AContentLength > 0 then
  begin
    Percentual := Integer((AReadCount * 100) div AContentLength);
    if Percentual > 100 then
      Percentual := 100;
    AtualizarStatus(Format('Baixando o cliente Firebird (fbclient)... %d%%',
      [Percentual]));
    if (Percentual = 100) or (Percentual >= FUltimoPercentual + 25) then
    begin
      FUltimoPercentual := Percentual;
      Tecnico(Format('Download do fbclient.zip: %d%%.', [Percentual]), clGray);
    end;
  end;
  Application.ProcessMessages;
end;

function TFbClientDownload.DiretorioCache: string;
begin
  Result := TPath.Combine(TPath.Combine(TPath.GetTempPath, CACHE_APLICACAO),
    PASTA_CACHE);
end;

// Le as chaves FbClient* do atualizacao.ini. Ini fora do ar nao impede o
// download: valem os padroes (sem tamanho/hash; a DLL e conferida de qualquer jeito).
procedure TFbClientDownload.LerPublicacao(out ZipNome: string; out Bytes: Int64;
  out Sha: string);
var
  Http: THTTPClient;
  Resposta: IHTTPResponse;
  Linhas: TStringList;
  Ini: TMemIniFile;
begin
  ZipNome := FB_CLIENT_ZIP;
  Bytes := 0;
  Sha := EmptyStr;
  Http := THTTPClient.Create;
  try
    Http.ConnectionTimeout := 15000;
    Http.ResponseTimeout := 30000;
    try
      Resposta := Http.Get(SITE_GESTAO2026 + ATUALIZACAO_INI);
      if (Resposta.StatusCode < 200) or (Resposta.StatusCode >= 300) then
      begin
        Tecnico('atualizacao.ini respondeu HTTP ' +
          IntToStr(Resposta.StatusCode) + '; seguindo sem conferencia de hash.',
          clGray);
        Exit;
      end;
      Linhas := TStringList.Create;
      try
        Linhas.Text := Resposta.ContentAsString(TEncoding.UTF8);
        Ini := TMemIniFile.Create(EmptyStr);
        try
          Ini.SetStrings(Linhas);
          ZipNome := Trim(Ini.ReadString('Publicacao', 'FbClientZip',
            FB_CLIENT_ZIP));
          // so o nome do arquivo: nunca um caminho
          if (ZipNome = EmptyStr) or (ExtractFileName(ZipNome) <> ZipNome) or
             (Pos('/', ZipNome) > 0) or (Pos(':', ZipNome) > 0) then
            ZipNome := FB_CLIENT_ZIP;
          Bytes := StrToInt64Def(Ini.ReadString('Publicacao', 'FbClientBytes',
            '0'), 0);
          Sha := UpperCase(Trim(Ini.ReadString('Publicacao', 'FbClientSHA256',
            '')));
        finally
          Ini.Free;
        end;
      finally
        Linhas.Free;
      end;
    except
      on E: Exception do
        Tecnico('atualizacao.ini indisponivel (' + E.Message +
          '); seguindo sem conferencia de hash.', clGray);
    end;
  finally
    Http.Free;
  end;
end;

procedure TFbClientDownload.Baixar(const Url, Destino: string);
var
  Http: THTTPClient;
  Resposta: IHTTPResponse;
  Fs: TFileStream;
  Parcial: string;
begin
  Parcial := Destino + '.download';
  if FileExists(Parcial) and (not System.SysUtils.DeleteFile(Parcial)) then
    raise Exception.Create('Nao foi possivel remover o download incompleto ' +
      'anterior: ' + Parcial);

  Http := THTTPClient.Create;
  try
    Http.ConnectionTimeout := 15000;
    Http.ResponseTimeout := 120000;
    Http.OnReceiveData := ReceberDados;
    FUltimoPercentual := -25;
    try
      Fs := TFileStream.Create(Parcial, fmCreate);
      try
        Resposta := Http.Get(Url, Fs);
      finally
        Fs.Free;
      end;
      if (Resposta.StatusCode < 200) or (Resposta.StatusCode >= 300) then
        raise Exception.CreateFmt('O servidor respondeu HTTP %d ao baixar %s.',
          [Resposta.StatusCode, Url]);
      if FileExists(Destino) and (not System.SysUtils.DeleteFile(Destino)) then
        raise Exception.Create('Nao foi possivel substituir ' + Destino);
      if not RenameFile(Parcial, Destino) then
        raise Exception.Create('Nao foi possivel finalizar o arquivo baixado: ' +
          Destino);
    except
      if FileExists(Parcial) then
        System.SysUtils.DeleteFile(Parcial);
      raise;
    end;
  finally
    Http.Free;
  end;
end;

procedure TFbClientDownload.ConferirZip(const Zip: string; Bytes: Int64;
  const Sha: string);
begin
  if (Bytes > 0) and (TamanhoArquivo(Zip) <> Bytes) then
    raise Exception.CreateFmt('O fbclient.zip baixado tem %d bytes e o ' +
      'atualizacao.ini informa %d.', [TamanhoArquivo(Zip), Bytes]);
  if Sha <> EmptyStr then
  begin
    if not SameText(THashSHA2.GetHashStringFromFile(Zip), Sha) then
      raise Exception.Create('O SHA256 do fbclient.zip baixado difere do ' +
        'informado no atualizacao.ini.');
    Tecnico('SHA256 do fbclient.zip conferido.', clGray);
  end
  else
    Tecnico('atualizacao.ini sem FbClientSHA256: conferindo apenas ' +
      'arquitetura e versao da DLL.', clGray);
end;

procedure TFbClientDownload.Instalar(const Zip, PastaDestino: string);
var
  Extraido, Dll, PastaDll, Arquivo: string;
  Encontrados, Dependencias: TStringDynArray;
  Versao: Integer;
begin
  Extraido := TPath.Combine(DiretorioCache, 'extraido');
  if DirectoryExists(Extraido) then
    TDirectory.Delete(Extraido, True);
  ForceDirectories(Extraido);

  AtualizarStatus('Extraindo o cliente Firebird...');
  TZipFile.ExtractZipFile(Zip, Extraido);

  Encontrados := TDirectory.GetFiles(Extraido, FB_CLIENT,
    TSearchOption.soAllDirectories);
  if Length(Encontrados) = 0 then
    raise Exception.Create('O fbclient.zip nao contem o fbclient.dll.');
  Dll := Encontrados[0];

  if MaquinaDoPE(Dll) <> MAQUINA_X86 then
    raise Exception.Create('O fbclient.dll do fbclient.zip nao e x86 (32 bits); ' +
      'o MigraFacil e 32 bits.');
  Versao := VersaoPrincipalArquivo(Dll);
  if Versao < TFbClientAutomatico.VERSAO_MINIMA then
    raise Exception.CreateFmt('O fbclient.dll do fbclient.zip e da versao %d.x; ' +
      'e exigido o 4.x ou superior.', [Versao]);

  if not ForceDirectories(PastaDestino) then
    raise Exception.Create('Nao foi possivel criar a pasta ' + PastaDestino + ': ' +
      SysErrorMessage(GetLastError));

  // dependencias primeiro: fbclient.dll so entra com o runtime ja no lugar
  PastaDll := ExtractFilePath(Dll);
  Dependencias := TDirectory.GetFiles(PastaDll, '*.dll',
    TSearchOption.soTopDirectoryOnly);
  for Arquivo in Dependencias do
    if not SameText(ExtractFileName(Arquivo), FB_CLIENT) then
      CopiarArquivo(Arquivo, IncludeTrailingPathDelimiter(PastaDestino) +
        ExtractFileName(Arquivo), False);
  CopiarArquivo(Dll, IncludeTrailingPathDelimiter(PastaDestino) + FB_CLIENT,
    False);

  Info('Cliente Firebird ' + IntToStr(Versao) + '.x (32 bits) do MigraFacil ' +
    'instalado em ' + PastaDestino, clLime);
end;

procedure TFbClientDownload.Executar(const PastaExe, PastaDestino: string);
var
  ZipLocal, ZipCache, ZipNome, Sha: string;
  Bytes: Int64;
begin
  ForceDirectories(DiretorioCache);

  ZipLocal := IncludeTrailingPathDelimiter(PastaExe) + FB_CLIENT_ZIP;
  if FileExists(ZipLocal) then
  begin
    Info('Usando o fbclient.zip ao lado do MigraFacil (alternativa offline).',
      clAqua);
    Instalar(ZipLocal, PastaDestino);
    Exit;
  end;

  LerPublicacao(ZipNome, Bytes, Sha);
  ZipCache := TPath.Combine(DiretorioCache, ZipNome);
  Tecnico('URL do cliente Firebird: ' + SITE_GESTAO2026 + ZipNome, clGray);
  Tecnico('Destino do ZIP: ' + ZipCache, clGray);
  Baixar(SITE_GESTAO2026 + ZipNome, ZipCache);
  try
    ConferirZip(ZipCache, Bytes, Sha);
  except
    System.SysUtils.DeleteFile(ZipCache);
    raise;
  end;
  Instalar(ZipCache, PastaDestino);
end;

{ TFbClientAutomatico }

class function TFbClientAutomatico.CaminhoCliente(const PastaExe: string): string;
var
  ClienteBin: string;
begin
  ClienteBin := IncludeTrailingPathDelimiter(PastaExe) + FB_CLIENT;
  if FileExists(ClienteBin) and (VersaoPrincipalArquivo(ClienteBin) >= VERSAO_MINIMA) then
    Exit(ClienteBin);
  Result := IncludeTrailingPathDelimiter(PastaExe) + PASTA_CLIENTE_PROPRIO + '\' +
    FB_CLIENT;
end;

class function TFbClientAutomatico.Garantir(const PastaExe: string;
  const Log, LogTecnico: TLogMigracaoEvent;
  const Status: TStatusMigracaoEvent): string;
var
  ClienteBin: string;
  Download: TFbClientDownload;
begin
  Result := CaminhoCliente(PastaExe);
  if FileExists(Result) then
    Exit;

  ClienteBin := IncludeTrailingPathDelimiter(PastaExe) + FB_CLIENT;
  if Assigned(Log) then
  begin
    if FileExists(ClienteBin) then
      Log('O fbclient.dll desta pasta e da versao ' +
        IntToStr(VersaoPrincipalArquivo(ClienteBin)) + '.x e nao conecta no ' +
        'Firebird 5. O MigraFacil vai usar o proprio cliente 4.x (o fbclient.dll ' +
        'da pasta nao e alterado).', clYellow)
    else
      Log('fbclient.dll nao encontrado ao lado do MigraFacil; obtendo o cliente ' +
        'Firebird 4.x...', clYellow);
  end;

  Download := TFbClientDownload.Create(Log, LogTecnico, Status);
  try
    try
      Download.Executar(PastaExe, ExtractFilePath(Result));
    except
      on E: Exception do
        raise Exception.Create('Nao foi possivel obter o cliente Firebird 4.x do ' +
          'MigraFacil: ' + E.Message + sLineBreak + sLineBreak +
          'Coloque o fbclient.zip ao lado do MigraFacil (ou o fbclient.dll 4.x, ' +
          '32 bits, com msvcp140.dll e vcruntime140.dll em ' + ExtractFilePath(Result) +
          ') e tente de novo.');
    end;
  finally
    Download.Free;
  end;
end;

end.
