unit uFirebirdInstalacoes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, uMigracaoContratos;

type
  TRegistroWindowsRaiz = (rwrLocalMachine,rwrCurrentUser);
  TRegistroWindowsVisao = (rwv32Bits,rwv64Bits);

  TFirebirdInstalacao = class
  private
    FNome: string;
    FVersao: string;
    FArquitetura: string;
    FDiretorio: string;
    FComandoDesinstalacao: string;
    FDesinstalador: string;
    FParametrosDesinstalacao: string;
    FChaveRegistro: string;
    FRaizRegistro: TRegistroWindowsRaiz;
    FVisaoRegistro: TRegistroWindowsVisao;
    FPossuiRegistro: Boolean;
  public
    function Identificacao: string;
    function DesinstaladorExiste: Boolean;
    function PossuiArquivosAtivos: Boolean;

    property Nome: string read FNome write FNome;
    property Versao: string read FVersao write FVersao;
    property Arquitetura: string read FArquitetura write FArquitetura;
    property Diretorio: string read FDiretorio write FDiretorio;
    property ComandoDesinstalacao: string read FComandoDesinstalacao
      write FComandoDesinstalacao;
    property Desinstalador: string read FDesinstalador write FDesinstalador;
    property ParametrosDesinstalacao: string read FParametrosDesinstalacao
      write FParametrosDesinstalacao;
    property ChaveRegistro: string read FChaveRegistro write FChaveRegistro;
    property RaizRegistro: TRegistroWindowsRaiz read FRaizRegistro
      write FRaizRegistro;
    property VisaoRegistro: TRegistroWindowsVisao read FVisaoRegistro
      write FVisaoRegistro;
    property PossuiRegistro: Boolean read FPossuiRegistro
      write FPossuiRegistro;
  end;

  TFirebirdInstalacaoLista = TObjectList<TFirebirdInstalacao>;

  // 15/10/2026: resultado de TFirebirdInstalacoes.IsolarSobra.
  // riIsolada = executaveis renomeados agora; riAgendadaNoBoot = algum arquivo em
  // uso so troca de nome no proximo boot; riFalhou = nada garantido (ver Erro).
  TResultadoIsolamento = (riIsolada, riAgendadaNoBoot, riFalhou);

  TFirebirdInstalacoes = class
  private
    class function EhFamilia25(const Nome,Versao: string): Boolean; static;
    class procedure SepararComando(const Comando: string;
      out Executavel,Parametros: string); static;
  public
    class function DetectarFamilia25: TFirebirdInstalacaoLista; static;
    class function ExisteFamilia25: Boolean; static;
    class function ExecutarDesinstalacao(
      const Instalacao: TFirebirdInstalacao;
      const OnStatus: TStatusMigracaoEvent): Boolean; static;
    class function RemoverEntradaOrfa(
      const Instalacao: TFirebirdInstalacao;
      const OnStatus: TStatusMigracaoEvent;
      out ArquivoBackupRegistro: string): Boolean; static;
    // 09/10/2026: o unins000.exe do Inno devolve o controle antes de terminar; a
    // remocao e feita por uma copia %TEMP%\_iu*.tmp. True enquanto houver processo
    // com nome "_iu*.tmp" (sem diferenciar maiusculas).
    class function DesinstaladorInnoEmExecucao: Boolean; static;
    // 09/10/2026: o Windows tem remocao/troca de arquivo agendada para o proximo
    // boot (PendingFileRenameOperations) dentro do diretorio informado. Arquivo em
    // uso durante o desinstalador vira remocao agendada.
    class function RemocaoAgendadaNoBoot(const Diretorio: string): Boolean; static;
    // 15/10/2026 (log real de 15/10: o 2.5 "desinstalado" deixou os executaveis).
    // O instalador do 2.5 marca os binarios como "sharedfile": o contador fica em
    // HKLM\...\SharedDLLs, cada instalacao soma 1 (2 quando o arquivo ja existia) e
    // o desinstalador so apaga o arquivo quando o contador chega a zero (sem o
    // valor, tambem nao apaga). Lista "visao|arquivo|contador" de cada valor dentro
    // do diretorio, nas visoes de 32 e 64 bits.
    class procedure ListarContadoresCompartilhados(const Diretorio: string;
      const Lista: TStrings); static;
    // Contadores > 1 dentro do diretorio voltam para 1, no mesmo tipo de valor,
    // para o desinstalador apagar os binarios. Antes de alterar uma visao exporta a
    // chave SharedDLLs (reg export) para PastaBackup; sem o backup aquela visao nao
    // e alterada. Registro recebe o backup e cada ajuste. Devolve quantos valores
    // foram ajustados; Erro <> '' = alguma visao/valor ficou sem ajuste.
    class function NormalizarContadoresCompartilhados(const Diretorio,
      PastaBackup: string; const OnStatus: TStatusMigracaoEvent;
      const Registro: TStrings; out Erro: string): Integer; static;
    // Primeiro processo em execucao cujo executavel esta dentro do diretorio
    // ('' = nenhum; processo sem acesso de consulta nao entra).
    class function ProcessoEmExecucaoNoDiretorio(
      const Diretorio: string): string; static;
    // Sobra de desinstalacao (sem desinstalador, executaveis no disco): renomeia
    // <dir>\bin para bin_removido_<Carimbo> (reversivel; firebird.conf e
    // security2.fdb ficam no lugar para uma reinstalacao do 2.5) e, o que ainda
    // restar, os executaveis do servidor para <nome>.removido_<Carimbo>. Arquivo em
    // uso: troca de nome agendada para o proximo boot. Nunca renomeia pasta que
    // contenha um caminho de CaminhosProtegidos nem mexe em servidor que nao seja 2.x.
    class function IsolarSobra(const Instalacao: TFirebirdInstalacao;
      const CaminhosProtegidos: array of string; const Carimbo: string;
      const Registro: TStrings; out Erro: string): TResultadoIsolamento; static;
  end;

implementation

uses
  Winapi.Windows, System.StrUtils, System.Win.Registry,
  Winapi.TlHelp32,
  uFirebirdAmbiente,uProcessoWindows;

const
  CHAVE_DESINSTALACAO =
    'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall';
  // 15/10/2026: contadores de arquivo compartilhado (sharedfile do Inno Setup)
  CHAVE_SHARED_DLLS =
    'SOFTWARE\Microsoft\Windows\CurrentVersion\SharedDLLs';
  // executaveis do servidor procurados numa pasta (tambem usados por IsolarSobra)
  ARQUIVOS_SERVIDOR: array[0..5] of string = (
    'bin\fbserver.exe','bin\fb_inet_server.exe',
    'bin\firebird.exe',
    'fbserver.exe',
    'fb_inet_server.exe','firebird.exe'
  );

function ExpandirVariaveisAmbiente(const Valor: string): string;
var
  Tamanho: DWORD;
begin
  Result := Valor;
  if Valor = EmptyStr then
    Exit;

  Tamanho := ExpandEnvironmentStrings(PChar(Valor),nil, 0);
  if Tamanho = 0 then
    Exit;

  SetLength(Result, Tamanho);
  if Tamanho > 1 then
    ExpandEnvironmentStrings(PChar(Valor), PChar(Result), Tamanho);
  SetLength(Result,Tamanho - 1);
end;

function CaminhoNormalizado(const Caminho: string): string;
begin
  Result := ExcludeTrailingPathDelimiter(ExpandirVariaveisAmbiente(
    Trim(Caminho)));
end;

function ArquivoServidorNoDiretorio(const Diretorio: string): string;
var
  I: Integer;
  Base: string;
begin
  Result := EmptyStr;
  Base := CaminhoNormalizado(Diretorio);
  if Base = EmptyStr then
    Exit;
  Base := IncludeTrailingPathDelimiter(Base);

  for I := Low(ARQUIVOS_SERVIDOR) to High(ARQUIVOS_SERVIDOR) do
    if FileExists(Base + ARQUIVOS_SERVIDOR[I]) then
    begin
      Result := Base + ARQUIVOS_SERVIDOR[I];
      Exit;
    end;
end;

function MesmoCaminho(const Primeiro,Segundo: string): Boolean;
begin
  Result := (Primeiro <> EmptyStr) and (Segundo <> EmptyStr) and
    SameText(CaminhoNormalizado(Primeiro),CaminhoNormalizado(Segundo));
end;

function InstalacaoJaAdicionada(const Lista: TFirebirdInstalacaoLista;
  const Instalacao: TFirebirdInstalacao): Boolean;
var
  Item: TFirebirdInstalacao;
begin
  Result := False;
  for Item in Lista do
    if MesmoCaminho(Item.Desinstalador,Instalacao.Desinstalador) or
       MesmoCaminho(Item.Diretorio,Instalacao.Diretorio) then
    begin
      Result := True;
      Exit;
    end;
end;

function ValorRegistro(const Registro: TRegistry;
  const Nome: string): string;
begin
  Result := EmptyStr;
  if Registro.ValueExists(Nome) then
    try
      Result := Registro.ReadString(Nome);
    except
      Result := EmptyStr;
    end;
end;

procedure EnumerarRegistro(const Lista: TFirebirdInstalacaoLista;
  const Raiz: TRegistroWindowsRaiz;
  const Visao: TRegistroWindowsVisao);
var
  Registro: TRegistry;
  Chaves: TStringList;
  I: Integer;
  Acesso: LongWord;
  Nome: string;
  Versao: string;
  Comando: string;
  Instalacao: TFirebirdInstalacao;
begin
  Acesso := KEY_READ;
  if Visao = rwv64Bits then
    Acesso := Acesso or KEY_WOW64_64KEY
  else
    Acesso := Acesso or KEY_WOW64_32KEY;

  Registro := TRegistry.Create(Acesso);
  Chaves := TStringList.Create;
  try
    if Raiz = rwrLocalMachine then
      Registro.RootKey := HKEY_LOCAL_MACHINE
    else
      Registro.RootKey := HKEY_CURRENT_USER;

    if not Registro.OpenKey(CHAVE_DESINSTALACAO,False) then
      Exit;
    Registro.GetKeyNames(Chaves);
    Registro.CloseKey;

    for I := 0 to Chaves.Count - 1 do
    begin
      if not Registro.OpenKey(
        CHAVE_DESINSTALACAO + '\' + Chaves[I],False) then
        Continue;
      try
        Nome := ValorRegistro(Registro, 'DisplayName');
        Versao := ValorRegistro(Registro,'DisplayVersion');
        if not TFirebirdInstalacoes.EhFamilia25(Nome, Versao) then
          Continue;

        Comando := ValorRegistro(Registro,'QuietUninstallString');
        if Comando = EmptyStr then
          Comando := ValorRegistro(Registro,'UninstallString');

        Instalacao := TFirebirdInstalacao.Create;
        Instalacao.Nome := Nome;
        Instalacao.Versao := Versao;
        Instalacao.Diretorio := CaminhoNormalizado(
          ValorRegistro(Registro,'InstallLocation'));
        Instalacao.ComandoDesinstalacao := Comando;
        TFirebirdInstalacoes.SepararComando(Comando,
          Instalacao.FDesinstalador,Instalacao.FParametrosDesinstalacao);
        Instalacao.Desinstalador := ExpandirVariaveisAmbiente(
          Instalacao.Desinstalador);

        if Instalacao.Diretorio = EmptyStr then
          Instalacao.Diretorio := CaminhoNormalizado(
            ExtractFilePath(Instalacao.Desinstalador));

        if ContainsText(Nome,'x64') or (Visao = rwv64Bits) then
          Instalacao.Arquitetura := 'x64'
        else
          Instalacao.Arquitetura := 'x86';

        Instalacao.ChaveRegistro :=
          CHAVE_DESINSTALACAO + '\' + Chaves[I];
        Instalacao.RaizRegistro := Raiz;
        Instalacao.VisaoRegistro := Visao;
        Instalacao.PossuiRegistro := True;

        Lista.Add(Instalacao);
      finally
        Registro.CloseKey;
      end;
    end;
  finally
    Chaves.Free;
    Registro.Free;
  end;
end;

procedure AdicionarCaminhosLegados(const Lista: TFirebirdInstalacaoLista);
const
  DIRETORIOS: array[0..4] of string = (
    'C:\Program Files\Firebird\Firebird_2_5','C:\Program Files (x86)\Firebird\Firebird_2_5',
    'C:\Firebird\Firebird_2_5',
    'C:\Program Files\Firebird_2_5','C:\Program Files (x86)\Firebird_2_5'
  );
var
  I: Integer;
  Servidor: string;
  Desinstalador: string;
  Instalacao: TFirebirdInstalacao;
  DiretorioDetectado: string;
begin
  for I := Low(DIRETORIOS) to High(DIRETORIOS) do
  begin
    Servidor := ArquivoServidorNoDiretorio(DIRETORIOS[I]);
    Desinstalador := IncludeTrailingPathDelimiter(
      DIRETORIOS[I]) + 'unins000.exe';

    if (Servidor = EmptyStr) and (not FileExists(Desinstalador)) then
      Continue;

    Instalacao := TFirebirdInstalacao.Create;
    Instalacao.Nome := 'Firebird 2.5';
    Instalacao.Versao := TFirebirdAmbiente.VersaoArquivo(Servidor);
    Instalacao.Diretorio := DIRETORIOS[I];
    Instalacao.Desinstalador := Desinstalador;
    Instalacao.ParametrosDesinstalacao := EmptyStr;
    Instalacao.PossuiRegistro := False;

    if (Servidor <> EmptyStr) and
       TFirebirdAmbiente.ArquivoEh32Bits(Servidor) then
      Instalacao.Arquitetura := 'x86'
    else
      Instalacao.Arquitetura := 'x64';

    if InstalacaoJaAdicionada(Lista,Instalacao) then
      Instalacao.Free
    else
      Lista.Add(Instalacao);
  end;
  Servidor := TFirebirdAmbiente.Executavel25;
  if Servidor = EmptyStr then
    Exit;

  DiretorioDetectado := TFirebirdAmbiente.Diretorio25;
  if DiretorioDetectado = EmptyStr then
    Exit;

  Desinstalador := IncludeTrailingPathDelimiter(
    DiretorioDetectado) + 'unins000.exe';

  Instalacao := TFirebirdInstalacao.Create;
  Instalacao.Nome := 'Firebird 2.5';
  Instalacao.Versao := TFirebirdAmbiente.VersaoArquivo(Servidor);
  Instalacao.Diretorio := DiretorioDetectado;
  Instalacao.Desinstalador := Desinstalador;
  Instalacao.ParametrosDesinstalacao := EmptyStr;
  Instalacao.PossuiRegistro := False;

  if TFirebirdAmbiente.ArquivoEh32Bits(Servidor) then
    Instalacao.Arquitetura := 'x86'
  else
    Instalacao.Arquitetura := 'x64';

  if InstalacaoJaAdicionada(Lista,Instalacao) then
    Instalacao.Free
  else
    Lista.Add(Instalacao);end;

function TFirebirdInstalacao.Identificacao: string;
begin
  Result := 'Firebird';
  if Versao <> EmptyStr then
    Result := Result + ' ' + Versao
  else if Nome <> EmptyStr then
    Result := Nome;

  if Arquitetura <> EmptyStr then
    Result := Result + ' (' + Arquitetura + ')';
end;

function TFirebirdInstalacao.DesinstaladorExiste: Boolean;
begin
  Result := (Desinstalador <> EmptyStr) and FileExists(Desinstalador);
end;

function TFirebirdInstalacao.PossuiArquivosAtivos: Boolean;
var
  BaseDesinstalador: string;
begin
  Result := DesinstaladorExiste or
    (ArquivoServidorNoDiretorio(Diretorio) <> EmptyStr);
  if Result then
    Exit;

  BaseDesinstalador := ExtractFilePath(Desinstalador);
  Result := ArquivoServidorNoDiretorio(BaseDesinstalador) <> EmptyStr;
end;

class function TFirebirdInstalacoes.EhFamilia25(
  const Nome,Versao: string): Boolean;
var
  NomeMinusculo: string;
  VersaoLimpa: string;
begin
  NomeMinusculo := LowerCase(Trim(Nome));
  VersaoLimpa := Trim(Versao);

  Result := ContainsText(NomeMinusculo,'firebird') and
    ((Copy(VersaoLimpa, 1, 3) = '2.5') or
     ContainsText(NomeMinusculo, 'firebird 2.5') or
     ContainsText(NomeMinusculo,'firebird v2.5'));
end;

class procedure TFirebirdInstalacoes.SepararComando(
  const Comando: string; out Executavel,Parametros: string);
var
  Texto: string;
  Posicao: Integer;
begin
  Executavel := EmptyStr;
  Parametros := EmptyStr;
  Texto := Trim(Comando);
  if Texto = EmptyStr then
    Exit;

  if Texto[1] = '"' then
  begin
    Posicao := PosEx('"',Texto, 2);
    if Posicao > 1 then
    begin
      Executavel := Copy(Texto, 2, Posicao - 2);
      Parametros := Trim(Copy(Texto, Posicao + 1,MaxInt));
      Exit;
    end;
  end;

  Posicao := Pos('.exe', LowerCase(Texto));
  if Posicao > 0 then
  begin
    Executavel := Copy(Texto, 1, Posicao + 3);
    Parametros := Trim(Copy(Texto,Posicao + 4,MaxInt));
  end
  else
    Executavel := Texto;
end;

class function TFirebirdInstalacoes.DetectarFamilia25:
  TFirebirdInstalacaoLista;
begin
  Result := TFirebirdInstalacaoLista.Create(True);

  if TFirebirdAmbiente.WindowsEh64Bits then
    EnumerarRegistro(Result,rwrLocalMachine, rwv64Bits);
  EnumerarRegistro(Result, rwrLocalMachine, rwv32Bits);
  if TFirebirdAmbiente.WindowsEh64Bits then
    EnumerarRegistro(Result, rwrCurrentUser,rwv64Bits);
  EnumerarRegistro(Result, rwrCurrentUser,rwv32Bits);
  AdicionarCaminhosLegados(Result);
end;

class function TFirebirdInstalacoes.ExisteFamilia25: Boolean;
var
  Instalacoes: TFirebirdInstalacaoLista;
begin
  Instalacoes := DetectarFamilia25;
  try
    Result := Instalacoes.Count > 0;
  finally
    Instalacoes.Free;
  end;
end;

class function TFirebirdInstalacoes.ExecutarDesinstalacao(
  const Instalacao: TFirebirdInstalacao;
  const OnStatus: TStatusMigracaoEvent): Boolean;
var
  Parametros: string;
begin
  if not Instalacao.DesinstaladorExiste then
  begin
    Result := False;
    Exit;
  end;

  Parametros := Trim(Instalacao.ParametrosDesinstalacao);
  if Parametros = EmptyStr then
    Parametros := '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'
  else
  begin
    if not ContainsText(Parametros,'/silent') and
       not ContainsText(Parametros, '/verysilent') then
      Parametros := Parametros + ' /VERYSILENT /SUPPRESSMSGBOXES';
    if not ContainsText(Parametros,'/norestart') then
      Parametros := Parametros + ' /NORESTART';
  end;

  Result := TProcessoWindows.ExecutarElevadoEAguardar(
    Instalacao.Desinstalador, Trim(Parametros),OnStatus);
end;

class function TFirebirdInstalacoes.RemoverEntradaOrfa(
  const Instalacao: TFirebirdInstalacao;
  const OnStatus: TStatusMigracaoEvent;
  out ArquivoBackupRegistro: string): Boolean;
var
  RegExe: string;
  NomeRaiz: string;
  Visao: string;
  ChaveCompleta: string;
  DiretorioBackup: string;
  NomeVersao: string;
  Parametros: string;
begin
  Result := False;
  ArquivoBackupRegistro := EmptyStr;
  if not Instalacao.PossuiRegistro then
    Exit;

  RegExe := IncludeTrailingPathDelimiter(
    GetEnvironmentVariable('WINDIR')) + 'System32\reg.exe';
  if not FileExists(RegExe) then
    RegExe := 'reg.exe';

  if Instalacao.RaizRegistro = rwrLocalMachine then
    NomeRaiz := 'HKLM'
  else
    NomeRaiz := 'HKCU';

  if Instalacao.VisaoRegistro = rwv64Bits then
    Visao := '64'
  else
    Visao := '32';

  ChaveCompleta := NomeRaiz + '\' + Instalacao.ChaveRegistro;
  DiretorioBackup := IncludeTrailingPathDelimiter(
    GetEnvironmentVariable('TEMP')) +
    'MigraFacil\Registro';
  ForceDirectories(DiretorioBackup);

  NomeVersao := Instalacao.Versao;
  if NomeVersao = EmptyStr then
    NomeVersao := '2.5';
  NomeVersao := StringReplace(NomeVersao,'.', '_',[rfReplaceAll]);

  ArquivoBackupRegistro := IncludeTrailingPathDelimiter(DiretorioBackup) +
    'Firebird_' + NomeVersao + '_' + Instalacao.Arquitetura + '_' +
    FormatDateTime('yyyymmdd_hhnnsszzz',Now) + '.reg';

  Parametros := 'export "' + ChaveCompleta + '" "' +
    ArquivoBackupRegistro + '" /y /reg:' + Visao;
  if not TProcessoWindows.ExecutarElevadoEAguardar(
    RegExe, Parametros,OnStatus) then
    Exit;

  Parametros := 'delete "' + ChaveCompleta + '" /f /reg:' + Visao;
  Result := TProcessoWindows.ExecutarElevadoEAguardar(
    RegExe, Parametros, OnStatus);
end;

class function TFirebirdInstalacoes.DesinstaladorInnoEmExecucao: Boolean;
var
  Snapshot: THandle;
  Entrada: TProcessEntry32;
  Nome: string;
begin
  Result := False;
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot = INVALID_HANDLE_VALUE then
    Exit;
  try
    Entrada.dwSize := SizeOf(Entrada);
    if Process32First(Snapshot, Entrada) then
      repeat
        Nome := LowerCase(string(Entrada.szExeFile));
        if StartsText('_iu', Nome) and EndsText('.tmp', Nome) then
        begin
          Result := True;
          Exit;
        end;
      until not Process32Next(Snapshot, Entrada);
  finally
    CloseHandle(Snapshot);
  end;
end;

// REG_MULTI_SZ lido cru (TRegistry.ReadString nao devolve multi-string): uma
// entrada por item da lista, sem as vazias.
function LerMultiString(const Chave: HKEY; const Valor: string;
  const Lista: TStrings): Boolean;
var
  Tipo: DWORD;
  Tamanho: DWORD;
  Buffer: TBytes;
  Texto: string;
  P: Integer;
  Inicio: Integer;
begin
  Result := False;
  Tipo := 0;
  Tamanho := 0;
  if RegQueryValueEx(Chave, PChar(Valor), nil, @Tipo, nil,
    @Tamanho) <> ERROR_SUCCESS then
    Exit;
  if (Tipo <> REG_MULTI_SZ) or (Tamanho = 0) then
    Exit;
  SetLength(Buffer, Tamanho + 2 * SizeOf(Char));
  FillChar(Buffer[0], Length(Buffer), 0);
  if RegQueryValueEx(Chave, PChar(Valor), nil, @Tipo, @Buffer[0],
    @Tamanho) <> ERROR_SUCCESS then
    Exit;
  SetString(Texto, PChar(@Buffer[0]), Tamanho div SizeOf(Char));
  Inicio := 1;
  for P := 1 to Length(Texto) do
    if Texto[P] = #0 then
    begin
      if P > Inicio then
        Lista.Add(Copy(Texto, Inicio, P - Inicio));
      Inicio := P + 1;
    end;
  if Inicio <= Length(Texto) then
    Lista.Add(Copy(Texto, Inicio, MaxInt));
  Result := True;
end;

class function TFirebirdInstalacoes.RemocaoAgendadaNoBoot(
  const Diretorio: string): Boolean;
const
  CHAVE_SESSION_MANAGER =
    'SYSTEM\CurrentControlSet\Control\Session Manager';
  VALORES: array[0..1] of string = (
    'PendingFileRenameOperations','PendingFileRenameOperations2');
var
  Chave: HKEY;
  Entradas: TStringList;
  Base: string;
  Entrada: string;
  I: Integer;
  J: Integer;
begin
  Result := False;
  Base := CaminhoNormalizado(Diretorio);
  if Base = EmptyStr then
    Exit;

  if RegOpenKeyEx(HKEY_LOCAL_MACHINE, CHAVE_SESSION_MANAGER, 0,
    KEY_QUERY_VALUE, Chave) <> ERROR_SUCCESS then
    Exit;
  Entradas := TStringList.Create;
  try
    for J := Low(VALORES) to High(VALORES) do
      LerMultiString(Chave, VALORES[J], Entradas);

    // pares origem/destino; o destino vazio (remocao) ja foi descartado. O
    // Windows grava "\??\C:\..." e, na troca, "!\??\C:\..." no destino.
    for I := 0 to Entradas.Count - 1 do
    begin
      Entrada := Trim(Entradas[I]);
      if Copy(Entrada, 1, 1) = '!' then
        Delete(Entrada, 1, 1);
      if Copy(Entrada, 1, 4) = '\??\' then
        Delete(Entrada, 1, 4);
      if SameText(Entrada, Base) or
         SameText(Copy(Entrada, 1, Length(Base) + 1),
           IncludeTrailingPathDelimiter(Base)) then
      begin
        Result := True;
        Exit;
      end;
    end;
  finally
    Entradas.Free;
    RegCloseKey(Chave);
  end;
end;


{ 15/10/2026: contadores SharedDLLs e sobra de desinstalacao do Firebird 2.5 }

function AcessoVisaoRegistro(const Visao: TRegistroWindowsVisao): LongWord;
begin
  if Visao = rwv64Bits then
    Result := KEY_WOW64_64KEY
  else
    Result := KEY_WOW64_32KEY;
end;

function NomeVisaoRegistro(const Visao: TRegistroWindowsVisao): string;
begin
  if Visao = rwv64Bits then
    Result := '64'
  else
    Result := '32';
end;

function VisaoRegistroDisponivel(const Visao: TRegistroWindowsVisao): Boolean;
begin
  Result := (Visao = rwv32Bits) or TFirebirdAmbiente.WindowsEh64Bits;
end;

// Valores da chave SharedDLLs (na visao) cujo nome fica dentro do diretorio.
procedure ValoresCompartilhadosNoDiretorio(const Diretorio: string;
  const Visao: TRegistroWindowsVisao; const Nomes: TStrings);
var
  Registro: TRegistry;
  Todos: TStringList;
  Base: string;
  I: Integer;
begin
  Nomes.Clear;
  Base := CaminhoNormalizado(Diretorio);
  if Base = EmptyStr then
    Exit;
  Base := IncludeTrailingPathDelimiter(Base);

  Registro := TRegistry.Create(KEY_READ or AcessoVisaoRegistro(Visao));
  Todos := TStringList.Create;
  try
    Registro.RootKey := HKEY_LOCAL_MACHINE;
    if not Registro.OpenKey(CHAVE_SHARED_DLLS, False) then
      Exit;
    try
      Registro.GetValueNames(Todos);
    finally
      Registro.CloseKey;
    end;

    for I := 0 to Todos.Count - 1 do
      if StartsText(Base, Todos[I]) then
        Nomes.Add(Todos[I]);
  finally
    Todos.Free;
    Registro.Free;
  end;
end;

// Le o contador nos formatos que o Inno Setup grava e le: REG_DWORD, REG_BINARY
// de 1 a 4 bytes ou REG_SZ.
function LerContadorCompartilhado(const Chave: HKEY; const Nome: string;
  out Tipo: DWORD; out Contador: Integer): Boolean;
var
  Tamanho: DWORD;
  Texto: string;
begin
  Result := False;
  Tipo := 0;
  Contador := 0;
  Tamanho := 0;
  if RegQueryValueEx(Chave, PChar(Nome), nil, @Tipo, nil,
    @Tamanho) <> ERROR_SUCCESS then
    Exit;

  case Tipo of
    REG_DWORD:
      begin
        Tamanho := SizeOf(Contador);
        Result := RegQueryValueEx(Chave, PChar(Nome), nil, nil, @Contador,
          @Tamanho) = ERROR_SUCCESS;
      end;
    REG_BINARY:
      if (Tamanho >= 1) and (Tamanho <= 4) then
        Result := RegQueryValueEx(Chave, PChar(Nome), nil, nil, @Contador,
          @Tamanho) = ERROR_SUCCESS;
    REG_SZ:
      begin
        Texto := StringOfChar(#0, Tamanho div SizeOf(Char) + 1);
        if RegQueryValueEx(Chave, PChar(Nome), nil, nil, PByte(PChar(Texto)),
          @Tamanho) = ERROR_SUCCESS then
        begin
          Contador := StrToIntDef(Trim(string(PChar(Texto))), -1);
          Result := Contador >= 0;
        end;
      end;
  end;
end;

// Grava o contador no mesmo tipo de valor que o Inno Setup usou.
function GravarContadorCompartilhado(const Chave: HKEY; const Nome: string;
  const Tipo: DWORD; const Contador: Integer): Boolean;
var
  Valor: Integer;
  Texto: string;
begin
  Valor := Contador;
  if Tipo = REG_SZ then
  begin
    Texto := IntToStr(Valor);
    Result := RegSetValueEx(Chave, PChar(Nome), 0, REG_SZ, PChar(Texto),
      (Length(Texto) + 1) * SizeOf(Char)) = ERROR_SUCCESS;
  end
  else
    Result := RegSetValueEx(Chave, PChar(Nome), 0, Tipo, @Valor,
      SizeOf(Valor)) = ERROR_SUCCESS;
end;

class procedure TFirebirdInstalacoes.ListarContadoresCompartilhados(
  const Diretorio: string; const Lista: TStrings);
var
  Visao: TRegistroWindowsVisao;
  Nomes: TStringList;
  Chave: HKEY;
  Tipo: DWORD;
  Contador: Integer;
  I: Integer;
begin
  Lista.Clear;
  Nomes := TStringList.Create;
  try
    for Visao := Low(TRegistroWindowsVisao) to High(TRegistroWindowsVisao) do
    begin
      if not VisaoRegistroDisponivel(Visao) then
        Continue;
      ValoresCompartilhadosNoDiretorio(Diretorio, Visao, Nomes);
      if Nomes.Count = 0 then
        Continue;
      if RegOpenKeyEx(HKEY_LOCAL_MACHINE, CHAVE_SHARED_DLLS, 0,
        KEY_QUERY_VALUE or AcessoVisaoRegistro(Visao), Chave) <> ERROR_SUCCESS then
        Continue;
      try
        for I := 0 to Nomes.Count - 1 do
          if LerContadorCompartilhado(Chave, Nomes[I], Tipo, Contador) then
            Lista.Add(NomeVisaoRegistro(Visao) + '|' + Nomes[I] + '|' +
              IntToStr(Contador))
          else
            Lista.Add(NomeVisaoRegistro(Visao) + '|' + Nomes[I] + '|?');
      finally
        RegCloseKey(Chave);
      end;
    end;
  finally
    Nomes.Free;
  end;
end;

class function TFirebirdInstalacoes.NormalizarContadoresCompartilhados(
  const Diretorio, PastaBackup: string; const OnStatus: TStatusMigracaoEvent;
  const Registro: TStrings; out Erro: string): Integer;
var
  Visao: TRegistroWindowsVisao;
  Nomes: TStringList;
  Ajustar: TStringList;
  Chave: HKEY;
  Tipo: DWORD;
  Contador: Integer;
  I: Integer;
  RegExe: string;
  ArquivoBackup: string;
  Parametros: string;
  Falhas: string;

  procedure AcrescentarFalha(const Texto: string);
  begin
    if Falhas <> EmptyStr then
      Falhas := Falhas + '; ';
    Falhas := Falhas + Texto;
  end;

begin
  Result := 0;
  Falhas := EmptyStr;
  RegExe := IncludeTrailingPathDelimiter(
    GetEnvironmentVariable('WINDIR')) + 'System32\reg.exe';
  if not FileExists(RegExe) then
    RegExe := 'reg.exe';

  Nomes := TStringList.Create;
  Ajustar := TStringList.Create;
  try
    for Visao := Low(TRegistroWindowsVisao) to High(TRegistroWindowsVisao) do
    begin
      if not VisaoRegistroDisponivel(Visao) then
        Continue;
      ValoresCompartilhadosNoDiretorio(Diretorio, Visao, Nomes);
      if Nomes.Count = 0 then
        Continue;

      // so os contadores > 1 (com 1 o desinstalador ja zera e apaga o arquivo)
      Ajustar.Clear;
      if RegOpenKeyEx(HKEY_LOCAL_MACHINE, CHAVE_SHARED_DLLS, 0,
        KEY_QUERY_VALUE or AcessoVisaoRegistro(Visao), Chave) <> ERROR_SUCCESS then
      begin
        AcrescentarFalha('SharedDLLs ' + NomeVisaoRegistro(Visao) +
          ' bits nao abriu para leitura');
        Continue;
      end;
      try
        for I := 0 to Nomes.Count - 1 do
          if LerContadorCompartilhado(Chave, Nomes[I], Tipo, Contador) and
             (Contador > 1) then
            Ajustar.Add(Nomes[I]);
      finally
        RegCloseKey(Chave);
      end;
      if Ajustar.Count = 0 then
        Continue;

      // backup da chave inteira desta visao antes de qualquer alteracao
      ForceDirectories(PastaBackup);
      ArquivoBackup := IncludeTrailingPathDelimiter(PastaBackup) + 'SharedDLLs_' +
        NomeVisaoRegistro(Visao) + 'bits_' +
        FormatDateTime('yyyymmdd_hhnnsszzz', Now) + '.reg';
      Parametros := 'export "HKLM\' + CHAVE_SHARED_DLLS + '" "' + ArquivoBackup +
        '" /y /reg:' + NomeVisaoRegistro(Visao);
      if (not TProcessoWindows.ExecutarElevadoEAguardar(RegExe, Parametros,
        OnStatus)) or (not FileExists(ArquivoBackup)) then
      begin
        AcrescentarFalha('backup da chave SharedDLLs ' + NomeVisaoRegistro(Visao) +
          ' bits nao gerado (' + TProcessoWindows.UltimoErro + ')');
        Continue;
      end;
      Registro.Add('Backup da chave SharedDLLs ' + NomeVisaoRegistro(Visao) +
        ' bits: ' + ArquivoBackup);

      if RegOpenKeyEx(HKEY_LOCAL_MACHINE, CHAVE_SHARED_DLLS, 0,
        KEY_QUERY_VALUE or KEY_SET_VALUE or AcessoVisaoRegistro(Visao),
        Chave) <> ERROR_SUCCESS then
      begin
        AcrescentarFalha('SharedDLLs ' + NomeVisaoRegistro(Visao) +
          ' bits nao abriu para gravacao');
        Continue;
      end;
      try
        for I := 0 to Ajustar.Count - 1 do
        begin
          if (not LerContadorCompartilhado(Chave, Ajustar[I], Tipo, Contador)) or
             (Contador <= 1) then
            Continue;
          if GravarContadorCompartilhado(Chave, Ajustar[I], Tipo, 1) then
          begin
            Inc(Result);
            Registro.Add('Contador ' + IntToStr(Contador) + ' -> 1 (' +
              NomeVisaoRegistro(Visao) + ' bits): ' + Ajustar[I]);
          end
          else
            AcrescentarFalha('contador nao gravado: ' + Ajustar[I]);
        end;
      finally
        RegCloseKey(Chave);
      end;
    end;
  finally
    Ajustar.Free;
    Nomes.Free;
  end;
  Erro := Falhas;
end;

class function TFirebirdInstalacoes.ProcessoEmExecucaoNoDiretorio(
  const Diretorio: string): string;
type
  TQueryFullProcessImageName = function(hProcess: THandle; dwFlags: DWORD;
    lpExeName: PWideChar; var lpdwSize: DWORD): BOOL; stdcall;
const
  PROCESS_QUERY_LIMITED_INFORMATION = $1000;
var
  Consultar: TQueryFullProcessImageName;
  Snapshot: THandle;
  Entrada: TProcessEntry32;
  Processo: THandle;
  Buffer: array[0..1023] of Char;
  Tamanho: DWORD;
  Caminho: string;
  Base: string;
begin
  Result := EmptyStr;
  Base := CaminhoNormalizado(Diretorio);
  if Base = EmptyStr then
    Exit;
  Base := IncludeTrailingPathDelimiter(Base);

  @Consultar := GetProcAddress(GetModuleHandle(kernel32),
    'QueryFullProcessImageNameW');
  if not Assigned(Consultar) then
    Exit;

  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot = INVALID_HANDLE_VALUE then
    Exit;
  try
    Entrada.dwSize := SizeOf(Entrada);
    if Process32First(Snapshot, Entrada) then
      repeat
        if Entrada.th32ProcessID = 0 then
          Continue;
        Processo := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False,
          Entrada.th32ProcessID);
        if Processo = 0 then
          Continue;
        try
          Tamanho := Length(Buffer);
          if Consultar(Processo, 0, @Buffer[0], Tamanho) then
          begin
            SetString(Caminho, PChar(@Buffer[0]), Tamanho);
            if StartsText(Base, Caminho) then
            begin
              Result := Caminho;
              Exit;
            end;
          end;
        finally
          CloseHandle(Processo);
        end;
      until not Process32Next(Snapshot, Entrada);
  finally
    CloseHandle(Snapshot);
  end;
end;

function CaminhoProtegidoDentro(const Pasta: string;
  const CaminhosProtegidos: array of string): Boolean;
var
  Base: string;
  Caminho: string;
  I: Integer;
begin
  Result := False;
  Base := IncludeTrailingPathDelimiter(CaminhoNormalizado(Pasta));
  for I := Low(CaminhosProtegidos) to High(CaminhosProtegidos) do
  begin
    Caminho := CaminhoNormalizado(CaminhosProtegidos[I]);
    if Caminho = EmptyStr then
      Continue;
    if SameText(IncludeTrailingPathDelimiter(Caminho), Base) or
       StartsText(Base, Caminho) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

// Renomeia para <arquivo>.removido_<carimbo>; em uso, agenda para o proximo boot.
function RenomearArquivoSobra(const Arquivo, Carimbo: string;
  const Registro: TStrings; var Agendou: Boolean; var Erro: string): Boolean;
var
  Novo: string;
  Codigo: DWORD;
begin
  Novo := Arquivo + '.removido_' + Carimbo;
  Result := MoveFileEx(PChar(Arquivo), PChar(Novo), 0);
  if Result then
  begin
    Registro.Add('Renomeado: ' + Arquivo + ' -> ' + ExtractFileName(Novo));
    Exit;
  end;

  Codigo := GetLastError;
  Result := MoveFileEx(PChar(Arquivo), PChar(Novo), MOVEFILE_DELAY_UNTIL_REBOOT);
  if Result then
  begin
    Agendou := True;
    Registro.Add('Em uso (' + SysErrorMessage(Codigo) + '): ' + Arquivo +
      ' sera renomeado no proximo boot do Windows.');
  end
  else
    Erro := 'nao foi possivel renomear ' + Arquivo + ': ' + SysErrorMessage(Codigo);
end;

function IsolarDiretorioSobra(const Diretorio: string;
  const CaminhosProtegidos: array of string; const Carimbo: string;
  const Registro: TStrings; var Agendou: Boolean; var Erro: string): Boolean;
var
  Base: string;
  Bin: string;
  NovoBin: string;
  Arquivo: string;
  Versao: string;
  Codigo: DWORD;
  I: Integer;
begin
  Result := True;
  Base := CaminhoNormalizado(Diretorio);
  Arquivo := ArquivoServidorNoDiretorio(Base);
  if Arquivo = EmptyStr then
    Exit;

  if Length(Base) <= 3 then
  begin
    Erro := 'pasta invalida para isolar: ' + Base;
    Result := False;
    Exit;
  end;

  // so a familia 2.x: nunca mexer na pasta de outro Firebird
  Versao := TFirebirdAmbiente.VersaoArquivo(Arquivo);
  if (Versao <> EmptyStr) and (not StartsText('2.', Versao)) then
  begin
    Erro := Arquivo + ' e da versao ' + Versao + ', nao do Firebird 2.5';
    Result := False;
    Exit;
  end;

  Bin := IncludeTrailingPathDelimiter(Base) + 'bin';
  if (ArquivoServidorNoDiretorio(Bin) <> EmptyStr) and
     (not CaminhoProtegidoDentro(Bin, CaminhosProtegidos)) then
  begin
    NovoBin := Bin + '_removido_' + Carimbo;
    if MoveFileEx(PChar(Bin), PChar(NovoBin), 0) then
      Registro.Add('Renomeado: ' + Bin + ' -> ' + ExtractFileName(NovoBin))
    else
    begin
      Codigo := GetLastError;
      Registro.Add('Pasta ' + Bin + ' nao renomeada (' + SysErrorMessage(Codigo) +
        '): renomeando so os executaveis do servidor.');
    end;
  end;

  // o que ainda restar (bin nao renomeado ou servidor fora do bin)
  for I := Low(ARQUIVOS_SERVIDOR) to High(ARQUIVOS_SERVIDOR) do
  begin
    Arquivo := IncludeTrailingPathDelimiter(Base) + ARQUIVOS_SERVIDOR[I];
    if FileExists(Arquivo) and
       (not RenomearArquivoSobra(Arquivo, Carimbo, Registro, Agendou, Erro)) then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

class function TFirebirdInstalacoes.IsolarSobra(
  const Instalacao: TFirebirdInstalacao;
  const CaminhosProtegidos: array of string; const Carimbo: string;
  const Registro: TStrings; out Erro: string): TResultadoIsolamento;
var
  Diretorios: TStringList;
  Diretorio: string;
  Agendou: Boolean;
  I: Integer;
begin
  Erro := EmptyStr;
  Agendou := False;
  Result := riFalhou;
  if Instalacao.DesinstaladorExiste then
  begin
    Erro := 'o desinstalador ainda existe (' + Instalacao.Desinstalador +
      '): nao e sobra de desinstalacao';
    Exit;
  end;

  Diretorios := TStringList.Create;
  try
    Diretorios.CaseSensitive := False;
    Diretorio := CaminhoNormalizado(Instalacao.Diretorio);
    if Diretorio <> EmptyStr then
      Diretorios.Add(Diretorio);
    if Instalacao.Desinstalador <> EmptyStr then
    begin
      Diretorio := CaminhoNormalizado(ExtractFilePath(Instalacao.Desinstalador));
      if (Diretorio <> EmptyStr) and (Diretorios.IndexOf(Diretorio) < 0) then
        Diretorios.Add(Diretorio);
    end;

    for I := 0 to Diretorios.Count - 1 do
      if not IsolarDiretorioSobra(Diretorios[I], CaminhosProtegidos, Carimbo,
        Registro, Agendou, Erro) then
        Exit;
  finally
    Diretorios.Free;
  end;

  if Agendou then
    Result := riAgendadaNoBoot
  else
    Result := riIsolada;
end;

end.
