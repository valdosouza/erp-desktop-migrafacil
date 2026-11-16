unit uPreRequisitosConversao;

{ Pre-requisitos e acesso exclusivo da conversao Firebird 2.5 -> 5.0.
  Plano: Infra-IA\Gestao\07-infra\plano-migracao-fb5-consolidado.md (Onda 0,
  itens O0-6 e O0-7; decisoes D-01 e D-04 aprovadas em 02/10/2026).

  Fase do cliente: o MigraFacil converte SO o banco; exe e DLLs sao do GestaoUpdate.
  Decisao de 03/10/2026 (Valdo, Infra-IA\prompt\PromptMigraFacilGestaoUpdateIndependecia.md):
  MigraFacil e GestaoUpdate rodam de forma independente, em qualquer ordem. A fase
  ([ATUALIZADOR] do Config.ini) passou a ser so INFORMATIVA (DescreverFase); o que
  bloqueia a conversao e o servidor nao ser o Firebird 2.5 (uPrincipal,
  ValidarServidorEhFirebird25). Substitui o O0-6 (exigencia do estado B).

  Conexoes (O0-7): lista MON$ATTACHMENTS pelo isql do 2.5 e exige banco sem
  ninguem conectado. O Firebird 2.5 NAO expoe a versao do cliente
  (MON$CLIENT_VERSION so existe a partir do 3.0; conferido em 02/10/2026),
  entao a confirmacao de que todas as estacoes estao no estado B e do operador.

  Shutdown: gfix -shut single -force 0 antes do backup (so a conexao do gbak)
  e -shut full logo depois (nenhuma conexao, nem SYSDBA). O banco fica fechado
  para gravacao ate a troca, entao nada gravado depois do backup se perde.
  Enquanto o 2.5 estiver instalado, uma falha devolve o banco com
  gfix -online. }

interface

uses
  System.SysUtils, System.Classes;

type
  // Coluna NOT NULL que tem linhas com valor nulo no banco 2.5 (o Firebird 2.5
  // nao validava os dados existentes ao criar a coluna; o gbak do 3+ recusa a
  // linha no restore: "validation error for column ... value *** null ***").
  // Origem 'C' = NOT NULL declarado na coluna (ou em dominio automatico RDB$nnn
  // exclusivo dela): corrigivel tirando o NOT NULL. 'D' = NOT NULL vem de um
  // dominio nomeado compartilhado (ex.: "Codigo"): nao se mexe no dominio.
  TColunaNula = record
    Tabela: string;
    Coluna: string;
    Nulos: Integer;
    Origem: Char;
  end;
  TColunasNulas = array of TColunaNula;

  // Constraint que o banco 2.5 ja nao cumpre e que o restore no Firebird 5 recusa
  // ao ativar o indice ("cannot commit index"): FK com linhas orfas (Tipo 'F') ou
  // PK/UNIQUE com nulos nas colunas (Tipo 'P' = PRIMARY KEY, 'U' = UNIQUE).
  // Decisao do Valdo em 05/10/2026 (Bimax: INTEG_1345 em TB_GERAL.GRL_CODIGO com 80
  // nulos; FK_TB_CARTAO_1 com 349 orfas para TB_CARTAOELETRONICO vazia): a constraint
  // e removida sem perguntar; os dados nao mudam. PK/UNIQUE referenciada por FK nao e
  // removida automaticamente (Dependentes > 0): a migracao para e lista.
  TConstraintInvalida = record
    Nome: string;
    Tabela: string;
    Tipo: Char;
    Colunas: string;      // "A, B" na ordem da chave
    TabelaRef: string;    // so FK
    ColunasRef: string;   // so FK
    Dependentes: Integer; // so PK/UNIQUE: FKs que apontam para ela
    Linhas: Integer;      // orfas (FK) ou com nulo (PK/UNIQUE)
  end;
  TConstraintsInvalidas = array of TConstraintInvalida;

  // Coluna cujo dominio e de tipo com tamanho fixo (SMALLINT, INTEGER, BIGINT/NUMERIC,
  // FLOAT, DOUBLE, DATE, TIME, TIMESTAMP, BLOB) mas tem RDB$FIELD_LENGTH diferente do
  // tamanho do tipo. O gbak monta a mensagem da tabela pelo RDB$FIELD_LENGTH e o
  // servidor pelo tipo: o backup para em "message length error (encountered X,
  // expected Y)". Origem: tipo trocado por UPDATE direto em RDB$FIELDS sem acertar o
  // tamanho. Caso real (cliente, 28/10/2026): TB_BOLETO_ELETRONICO.BLE_VL_MULTA,
  // NUMERIC(10,2) com 100 no lugar de 8 (resto de um VARCHAR(100)).
  TCampoTamanhoInvalido = record
    Tabela: string;
    Coluna: string;
    Dominio: string;  // RDB$FIELDS.RDB$FIELD_NAME (automatico RDB$nnn ou nomeado)
    Tipo: Integer;    // RDB$FIELD_TYPE
    NomeTipo: string; // para o log (ex.: 'BIGINT/NUMERIC')
    Tamanho: Integer; // RDB$FIELD_LENGTH gravado
    Correto: Integer; // tamanho do tipo
  end;
  TCamposTamanhoInvalido = array of TCampoTamanhoInvalido;

  TPreRequisitosConversao = class
  public
    // FKs com linhas orfas e PKs/UNIQUEs com nulos, em tabelas de usuario (uma
    // contagem por constraint). TabelasSemLeitura recebe o nome das constraints cuja
    // contagem falhou.
    class function ListarConstraintsInvalidas(const Gbak25, Database: string;
      TabelasSemLeitura: TStrings): TConstraintsInvalidas; static;
    // ALTER TABLE ... DROP CONSTRAINT das constraints removiveis (FK sempre; PK/UNIQUE
    // so sem FK dependente). Devolve, uma por linha, a DDL basica para recriar cada
    // uma depois de acertar os dados (vai para o log tecnico).
    class function RemoverConstraints(const Gbak25, Database: string;
      const Lista: TConstraintsInvalidas): string; static;
    class function ConstraintRemovivel(const C: TConstraintInvalida): Boolean; static;
    // Colunas NOT NULL de tabelas de usuario com linhas em NULL (uma varredura por
    // tabela). TabelasSemLeitura recebe as tabelas cuja contagem falhou (o chamador
    // decide se avisa). Levanta excecao se nem a lista de metadados sair.
    class function ListarNotNullComNulos(const Gbak25, Database: string;
      TabelasSemLeitura: TStrings): TColunasNulas; static;
    // Tira o NOT NULL das colunas de origem 'C' (RDB$RELATION_FIELDS e, se o
    // dominio for automatico RDB$nnn, tambem RDB$FIELDS). Os dados nao mudam.
    // Firebird 2.5 aceita UPDATE direto nas tabelas de sistema como SYSDBA.
    class procedure TornarOpcionais(const Gbak25, Database: string;
      const Colunas: TColunasNulas); static;
    // Colunas de tabelas de usuario com RDB$FIELD_LENGTH diferente do tamanho fixo do
    // tipo (so metadados; os dados nao sao lidos). Levanta excecao se a consulta falhar.
    class function ListarTamanhosInvalidos(const Gbak25, Database: string): TCamposTamanhoInvalido; static;
    // Grava o tamanho do tipo em RDB$FIELD_LENGTH e limpa RDB$CHARACTER_LENGTH (so tem
    // sentido em CHAR/VARCHAR) nos dominios listados. Os dados nao mudam: o servidor
    // ja grava e le esses tipos pelo tamanho fixo. Firebird 2.5 aceita UPDATE direto
    // nas tabelas de sistema como SYSDBA.
    class procedure CorrigirTamanhos(const Gbak25, Database: string;
      const Campos: TCamposTamanhoInvalido); static;
    // Fase do cliente para o log (nunca bloqueia). Linha2026 = Config.ini ja liberado
    // para o Gestao 2026 pelo GestaoUpdate; False = Gestao 2016 (o operador e avisado
    // de que, depois da conversao, o Gestao so conecta apos o GestaoUpdate).
    class function DescreverFase(const ConfigIni: string; out Linha2026: Boolean): string; static;
    // Conexoes ativas no banco (exceto a do proprio isql), uma por linha:
    // "endereco | processo | desde". Levanta excecao se a consulta falhar.
    class function ListarConexoes(const Gbak25, Database: string): TStringList; static;
    // single: so uma conexao SYSDBA (a do gbak) durante o backup
    class procedure ColocarEmShutdown(const Gbak25, Database: string); static;
    // full: nenhuma conexao, nem SYSDBA, ate a troca do banco (o Gestao conecta
    // como SYSDBA e poderia ocupar a vaga do single depois do backup)
    class procedure FecharTotalmente(const Gbak25, Database: string); static;
    class procedure ColocarOnline(const Gbak25, Database: string); static;
    // Tenta devolver o banco (falha so e registrada pelo chamador via retorno).
    class function TentarOnline(const Gbak25, Database: string; out Erro: string): Boolean; static;
  end;

// Versao principal do produto (ProductVersion) de um .dll/.exe; 0 = nao conseguiu ler.
function VersaoPrincipalArquivo(const Arquivo: string): Integer;

implementation

uses
  Winapi.Windows, System.IOUtils, System.StrUtils, uProcessoWindows, uMarcadorAtualizador;

const
  C_FB_USUARIO = 'sysdba';
  C_FB_SENHA = 'masterkey';

function Aspas(const Valor: string): string;
begin
  Result := '"' + Valor + '"';
end;

function FerramentaFirebird25(const Gbak25, Nome: string): string;
begin
  Result := EmptyStr;
  if Gbak25 <> EmptyStr then
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(Gbak25)) + Nome;
  if (Result = EmptyStr) or (not FileExists(Result)) then
    raise Exception.Create(Nome + ' do Firebird 2.5 nao encontrado ao lado do gbak: ' + Gbak25);
end;

// Versao principal do produto pela ProductVersion em texto ('4.0.4.3010').
// O numero fixo de versao das DLLs do Firebird NAO e a versao do produto: o
// fbclient 4.0.4 traz 6.3.x (conferido em 02/10/2026).
function VersaoPrincipalArquivo(const Arquivo: string): Integer;
type
  TTraducao = packed record
    Idioma, Pagina: Word;
  end;
  PTraducao = ^TTraducao;
var
  Tamanho, Handle, TamInfo: DWORD;
  Buffer: TBytes;
  Traducao: PTraducao;
  Texto: PChar;
  Versao: string;
  P: Integer;
begin
  Result := 0;
  Tamanho := GetFileVersionInfoSize(PChar(Arquivo), Handle);
  if Tamanho = 0 then
    Exit;
  SetLength(Buffer, Tamanho);
  if not GetFileVersionInfo(PChar(Arquivo), 0, Tamanho, Pointer(Buffer)) then
    Exit;
  if not (VerQueryValue(Pointer(Buffer), '\VarFileInfo\Translation', Pointer(Traducao), TamInfo) and
          (TamInfo >= SizeOf(TTraducao))) then
    Exit;
  if not VerQueryValue(Pointer(Buffer), PChar(Format('\StringFileInfo\%.4x%.4x\ProductVersion',
           [Traducao^.Idioma, Traducao^.Pagina])), Pointer(Texto), TamInfo) then
    Exit;
  Versao := Trim(Texto);
  P := Pos('.', Versao);
  if P > 0 then
    Versao := Copy(Versao, 1, P - 1);
  Result := StrToIntDef(Versao, 0);
end;

// Executa a linha de comando pelo cmd, com saida (stdout+stderr) no arquivo.
function ExecutarComSaida(const Exe, Parametros, ArquivoSaida: string): Boolean;
var
  Cmd: string;
begin
  Cmd := '/C "' + Aspas(Exe) + ' ' + Parametros + ' > ' + Aspas(ArquivoSaida) + ' 2>&1"';
  Result := TProcessoWindows.ExecutarElevadoEAguardar(
    TProcessoWindows.ProcessadorComandos, Cmd, nil);
end;

function LerSaida(const Arquivo: string): string;
begin
  Result := EmptyStr;
  if FileExists(Arquivo) then
    Result := Trim(TFile.ReadAllText(Arquivo, TEncoding.ANSI));
end;

class function TPreRequisitosConversao.DescreverFase(const ConfigIni: string;
  out Linha2026: Boolean): string;
var
  Marcador: TMarcadorLocal;
begin
  Marcador := Fc_LerMarcadorAtualizador(ConfigIni);
  Linha2026 := Marcador.Existe and (Marcador.Linha = C_MARCADOR_LINHA_2026);
  if Linha2026 then
    Result := 'Fase do cliente: linha 2026' +
      IfThen(Marcador.Transitorio, ' em modo transitorio', '') + ', pacote de DLLs ' +
      IfThen(Marcador.PacoteDLLs <> '', Marcador.PacoteDLLs, 'nao informado') + '.'
  else
    Result := 'Fase do cliente: linha 2016 (Gestao 2016). A conversao segue; depois dela ' +
      'o Gestao so volta a conectar quando o GestaoUpdate liberar a linha 2026 ' +
      '(servidor e todas as estacoes).';
end;

// Uma leitura de MON$ATTACHMENTS (exceto a conexao do proprio isql).
function ConsultarConexoes(const Isql, Database: string): TStringList;
const
  C_MARCA = '##CON;';
  C_FIM = '##FIM';
var
  Script, Saida, Texto, L: string;
  Linhas: TStringList;
  I: Integer;
begin
  Script := TPath.Combine(TPath.GetTempPath, 'migrafacil_conexoes.sql');
  Saida := TPath.Combine(TPath.GetTempPath, 'migrafacil_conexoes.txt');
  // protocolo, PID e usuario identificam a conexao (log de 03/10/2026 so trazia
  // "local | ? | hora", sem como saber de quem era)
  TFile.WriteAllText(Script,
    'SET HEADING OFF;' + sLineBreak +
    'SELECT ''' + C_MARCA + ''' || COALESCE(TRIM(MON$REMOTE_ADDRESS), ''local'') || '' | '' || ' +
    'COALESCE(TRIM(MON$REMOTE_PROCESS), ''?'') || '' | '' || ' +
    'CAST(MON$TIMESTAMP AS VARCHAR(24)) || '' | id='' || ' +
    'CAST(MON$ATTACHMENT_ID AS VARCHAR(18)) || ' +
    ''' prot='' || COALESCE(TRIM(MON$REMOTE_PROTOCOL), ''?'') || ' +
    ''' pid='' || COALESCE(CAST(MON$REMOTE_PID AS VARCHAR(12)), ''?'') || ' +
    ''' srvpid='' || COALESCE(CAST(MON$SERVER_PID AS VARCHAR(12)), ''?'') || ' +
    ''' user='' || COALESCE(TRIM(MON$USER), ''?'') || ' +
    ''' state='' || COALESCE(CAST(MON$STATE AS VARCHAR(4)), ''?'') FROM MON$ATTACHMENTS ' +
    'WHERE MON$ATTACHMENT_ID <> CURRENT_CONNECTION;' + sLineBreak +
    'SELECT ''' + C_FIM + ''' FROM RDB$DATABASE;' + sLineBreak, TEncoding.ANSI);
  try
    ExecutarComSaida(Isql, '-q -user ' + C_FB_USUARIO + ' -password ' + C_FB_SENHA +
      ' -i ' + Aspas(Script) + ' ' + Aspas(Database), Saida);
    Texto := LerSaida(Saida);
    if Pos(C_FIM, Texto) = 0 then
      raise Exception.Create('Nao foi possivel listar as conexoes do banco: ' + Texto);
    Result := TStringList.Create;
    Linhas := TStringList.Create;
    try
      Linhas.Text := Texto;
      for I := 0 to Linhas.Count - 1 do
      begin
        L := Trim(Linhas[I]);
        if Copy(L, 1, Length(C_MARCA)) = C_MARCA then
          Result.Add(Copy(L, Length(C_MARCA) + 1, MaxInt));
      end;
    finally
      Linhas.Free;
    end;
  finally
    System.SysUtils.DeleteFile(Script);
    System.SysUtils.DeleteFile(Saida);
  end;
end;

class function TPreRequisitosConversao.ListarConexoes(const Gbak25, Database: string): TStringList;
const
  // o teste de conexao (processo filho /testeconexao) acabou de desconectar: a
  // conexao dele pode ainda aparecer na primeira leitura (log de 03/10/2026:
  // "local | ? |" com a hora exata do teste). So reprova se persistir.
  C_TENTATIVAS = 4;
  C_INTERVALO_MS = 1500;
var
  Isql: string;
  Tentativa: Integer;
begin
  Isql := FerramentaFirebird25(Gbak25, 'isql.exe');
  Result := ConsultarConexoes(Isql, Database);
  Tentativa := 1;
  while (Result.Count > 0) and (Tentativa < C_TENTATIVAS) do
  begin
    Sleep(C_INTERVALO_MS);
    Result.Free;
    Result := ConsultarConexoes(Isql, Database);
    Inc(Tentativa);
  end;
end;

class procedure TPreRequisitosConversao.ColocarEmShutdown(const Gbak25, Database: string);
var
  Gfix, Saida: string;
begin
  Gfix := FerramentaFirebird25(Gbak25, 'gfix.exe');
  Saida := TPath.Combine(TPath.GetTempPath, 'migrafacil_gfix.txt');
  try
    // single: so uma conexao SYSDBA (a do gbak); -force 0 derruba quem entrar no meio
    if not ExecutarComSaida(Gfix, '-shut single -force 0 -user ' + C_FB_USUARIO +
      ' -password ' + C_FB_SENHA + ' ' + Aspas(Database), Saida) then
      raise Exception.Create('Nao foi possivel fechar o banco para a conversao (gfix -shut): ' +
        LerSaida(Saida) + ' ' + TProcessoWindows.UltimoErro);
  finally
    System.SysUtils.DeleteFile(Saida);
  end;
end;

class procedure TPreRequisitosConversao.FecharTotalmente(const Gbak25, Database: string);
var
  Gfix, Saida: string;
begin
  Gfix := FerramentaFirebird25(Gbak25, 'gfix.exe');
  Saida := TPath.Combine(TPath.GetTempPath, 'migrafacil_gfix.txt');
  try
    if not ExecutarComSaida(Gfix, '-shut full -force 0 -user ' + C_FB_USUARIO +
      ' -password ' + C_FB_SENHA + ' ' + Aspas(Database), Saida) then
      raise Exception.Create('Nao foi possivel fechar totalmente o banco (gfix -shut full): ' +
        LerSaida(Saida) + ' ' + TProcessoWindows.UltimoErro);
  finally
    System.SysUtils.DeleteFile(Saida);
  end;
end;

class procedure TPreRequisitosConversao.ColocarOnline(const Gbak25, Database: string);
var
  Erro: string;
begin
  if not TentarOnline(Gbak25, Database, Erro) then
    raise Exception.Create(Erro);
end;

class function TPreRequisitosConversao.TentarOnline(const Gbak25, Database: string;
  out Erro: string): Boolean;
var
  Gfix, Saida: string;
begin
  Erro := EmptyStr;
  Saida := TPath.Combine(TPath.GetTempPath, 'migrafacil_gfix.txt');
  try
    try
      Gfix := FerramentaFirebird25(Gbak25, 'gfix.exe');
      Result := ExecutarComSaida(Gfix, '-online normal -user ' + C_FB_USUARIO +
        ' -password ' + C_FB_SENHA + ' ' + Aspas(Database), Saida);
      if not Result then
        Erro := 'Nao foi possivel reabrir o banco (gfix -online): ' + LerSaida(Saida) + ' ' +
          TProcessoWindows.UltimoErro;
    except
      on E: Exception do
      begin
        Result := False;
        Erro := E.Message;
      end;
    end;
  finally
    System.SysUtils.DeleteFile(Saida);
  end;
end;

// Identificador para o SQL: nome so com maiusculas/digitos/_/$ vai sem aspas;
// qualquer outro (minusculas, espaco) vai entre aspas duplas (dialeto 3).
function Identificador(const Nome: string): string;
var
  I: Integer;
  Simples: Boolean;
begin
  Simples := (Nome <> EmptyStr) and CharInSet(Nome[1], ['A'..'Z']);
  for I := 1 to Length(Nome) do
    if not CharInSet(Nome[I], ['A'..'Z', '0'..'9', '_', '$']) then
    begin
      Simples := False;
      Break;
    end;
  if Simples then
    Result := Nome
  else
    Result := '"' + StringReplace(Nome, '"', '""', [rfReplaceAll]) + '"';
end;

function LiteralSql(const Valor: string): string;
begin
  Result := '''' + StringReplace(Valor, '''', '''''', [rfReplaceAll]) + '''';
end;

// Roda um script no isql do 2.5 e devolve a saida; exige a marca de fim.
function ExecutarScriptIsql(const Isql, Database, Script, NomeBase: string): string;
const
  C_FIM = '##FIM';
var
  ArqScript, ArqSaida: string;
begin
  ArqScript := TPath.Combine(TPath.GetTempPath, NomeBase + '.sql');
  ArqSaida := TPath.Combine(TPath.GetTempPath, NomeBase + '.txt');
  TFile.WriteAllText(ArqScript, Script + 'SELECT ''' + C_FIM + ''' FROM RDB$DATABASE;' +
    sLineBreak, TEncoding.ANSI);
  try
    ExecutarComSaida(Isql, '-q -user ' + C_FB_USUARIO + ' -password ' + C_FB_SENHA +
      ' -i ' + Aspas(ArqScript) + ' ' + Aspas(Database), ArqSaida);
    Result := LerSaida(ArqSaida);
    if Pos(C_FIM, Result) = 0 then
      raise Exception.Create('O isql do Firebird 2.5 nao concluiu a consulta (' + NomeBase +
        '): ' + Copy(Result, 1, 600));
  finally
    System.SysUtils.DeleteFile(ArqScript);
    System.SysUtils.DeleteFile(ArqSaida);
  end;
end;

class function TPreRequisitosConversao.ListarNotNullComNulos(const Gbak25, Database: string;
  TabelasSemLeitura: TStrings): TColunasNulas;
const
  C_COL = '##COL;';
  C_NUL = '##NUL;';
type
  TColunaMeta = record
    Tabela, Coluna: string;
    Origem: Char;
  end;
var
  Isql, Texto, L, Tabela, Script, Expr, Par: string;
  Linhas, Partes, Tabelas: TStringList;
  Metas: array of TColunaMeta;
  I, J, N, P, Nulos: Integer;
  Lidas: TStringList;
begin
  SetLength(Result, 0);
  Isql := FerramentaFirebird25(Gbak25, 'isql.exe');

  // 1) metadados: colunas NOT NULL de tabelas de usuario (sem views, externas e
  //    campos calculados). Origem D = dominio nomeado com NOT NULL.
  Texto := ExecutarScriptIsql(Isql, Database,
    'SET HEADING OFF;' + sLineBreak +
    'SELECT ''' + C_COL + ''' || TRIM(rf.RDB$RELATION_NAME) || '';'' || TRIM(rf.RDB$FIELD_NAME) || '';'' || ' +
    'IIF(COALESCE(f.RDB$NULL_FLAG, 0) = 1 AND NOT (f.RDB$FIELD_NAME STARTING WITH ''RDB$''), ''D'', ''C'') ' +
    'FROM RDB$RELATION_FIELDS rf ' +
    'JOIN RDB$FIELDS f ON f.RDB$FIELD_NAME = rf.RDB$FIELD_SOURCE ' +
    'JOIN RDB$RELATIONS r ON r.RDB$RELATION_NAME = rf.RDB$RELATION_NAME ' +
    'WHERE COALESCE(r.RDB$SYSTEM_FLAG, 0) = 0 AND r.RDB$VIEW_BLR IS NULL ' +
    'AND r.RDB$EXTERNAL_FILE IS NULL AND f.RDB$COMPUTED_BLR IS NULL ' +
    'AND (rf.RDB$NULL_FLAG = 1 OR f.RDB$NULL_FLAG = 1) ' +
    'ORDER BY rf.RDB$RELATION_NAME, rf.RDB$FIELD_POSITION;' + sLineBreak,
    'migrafacil_notnull_meta');

  Linhas := TStringList.Create;
  Partes := TStringList.Create;
  Tabelas := TStringList.Create;
  Lidas := TStringList.Create;
  try
    Partes.StrictDelimiter := True;
    Partes.Delimiter := ';';
    Tabelas.Sorted := True;
    Tabelas.Duplicates := dupIgnore;
    Lidas.Sorted := True;
    Lidas.Duplicates := dupIgnore;

    Linhas.Text := Texto;
    N := 0;
    SetLength(Metas, Linhas.Count);
    for I := 0 to Linhas.Count - 1 do
    begin
      L := Trim(Linhas[I]);
      if Copy(L, 1, Length(C_COL)) <> C_COL then
        Continue;
      Partes.DelimitedText := Copy(L, Length(C_COL) + 1, MaxInt);
      if Partes.Count < 3 then
        Continue;
      Metas[N].Tabela := Partes[0];
      Metas[N].Coluna := Partes[1];
      Metas[N].Origem := Partes[2][1];
      Tabelas.Add(Partes[0]);
      Inc(N);
    end;
    SetLength(Metas, N);
    if N = 0 then
      Exit;

    // 2) uma varredura por tabela: nulos = COUNT(*) - COUNT(coluna)
    Script := 'SET HEADING OFF;' + sLineBreak;
    for I := 0 to Tabelas.Count - 1 do
    begin
      Tabela := Tabelas[I];
      Expr := EmptyStr;
      for J := 0 to N - 1 do
        if Metas[J].Tabela = Tabela then
          Expr := Expr + ' || ' + LiteralSql(';' + Metas[J].Coluna + '=') +
            ' || CAST(COUNT(*) - COUNT(' + Identificador(Metas[J].Coluna) + ') AS VARCHAR(12))';
      Script := Script + 'SELECT ' + LiteralSql(C_NUL + Tabela) + Expr + ' FROM ' +
        Identificador(Tabela) + ';' + sLineBreak;
    end;
    Texto := ExecutarScriptIsql(Isql, Database, Script, 'migrafacil_notnull_cont');

    // 3) le "##NUL;TABELA;COL=n;COL=n"
    Linhas.Text := Texto;
    for I := 0 to Linhas.Count - 1 do
    begin
      L := Trim(Linhas[I]);
      if Copy(L, 1, Length(C_NUL)) <> C_NUL then
        Continue;
      Partes.DelimitedText := Copy(L, Length(C_NUL) + 1, MaxInt);
      if Partes.Count < 2 then
        Continue;
      Tabela := Partes[0];
      Lidas.Add(Tabela);
      for J := 1 to Partes.Count - 1 do
      begin
        Par := Partes[J];
        P := Pos('=', Par);
        if P = 0 then
          Continue;
        Nulos := StrToIntDef(Trim(Copy(Par, P + 1, MaxInt)), 0);
        if Nulos <= 0 then
          Continue;
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)].Tabela := Tabela;
        Result[High(Result)].Coluna := Copy(Par, 1, P - 1);
        Result[High(Result)].Nulos := Nulos;
        Result[High(Result)].Origem := 'C';
        for P := 0 to N - 1 do
          if (Metas[P].Tabela = Tabela) and (Metas[P].Coluna = Result[High(Result)].Coluna) then
          begin
            Result[High(Result)].Origem := Metas[P].Origem;
            Break;
          end;
      end;
    end;

    if Assigned(TabelasSemLeitura) then
      for I := 0 to Tabelas.Count - 1 do
        if Lidas.IndexOf(Tabelas[I]) < 0 then
          TabelasSemLeitura.Add(Tabelas[I]);
  finally
    Lidas.Free;
    Tabelas.Free;
    Partes.Free;
    Linhas.Free;
  end;
end;

class procedure TPreRequisitosConversao.TornarOpcionais(const Gbak25, Database: string;
  const Colunas: TColunasNulas);
var
  Isql, Script, Texto, Cond: string;
  I: Integer;
begin
  Isql := FerramentaFirebird25(Gbak25, 'isql.exe');
  Script := EmptyStr;
  for I := Low(Colunas) to High(Colunas) do
  begin
    if Colunas[I].Origem <> 'C' then
      Continue;
    Cond := 'RDB$RELATION_NAME = ' + LiteralSql(Colunas[I].Tabela) +
      ' AND RDB$FIELD_NAME = ' + LiteralSql(Colunas[I].Coluna);
    // dominio automatico (RDB$nnn) e exclusivo da coluna: limpa a flag nele tambem
    Script := Script +
      'UPDATE RDB$FIELDS SET RDB$NULL_FLAG = NULL WHERE RDB$FIELD_NAME STARTING WITH ''RDB$'' ' +
      'AND RDB$FIELD_NAME = (SELECT RDB$FIELD_SOURCE FROM RDB$RELATION_FIELDS WHERE ' + Cond + ');' +
      sLineBreak +
      'UPDATE RDB$RELATION_FIELDS SET RDB$NULL_FLAG = NULL WHERE ' + Cond + ';' + sLineBreak;
  end;
  if Script = EmptyStr then
    Exit;
  Script := Script + 'COMMIT;' + sLineBreak;
  Texto := ExecutarScriptIsql(Isql, Database, Script, 'migrafacil_notnull_fix');
  if ContainsText(Texto, 'Statement failed') or ContainsText(Texto, 'SQLSTATE') then
    raise Exception.Create('Falha ao tirar o NOT NULL das colunas: ' + Copy(Texto, 1, 800));
end;

type
  TTipoFixo = record
    Tipo: Integer;
    Tamanho: Integer;
    Nome: string;
  end;

const
  // RDB$FIELD_TYPE de tamanho fixo e o RDB$FIELD_LENGTH que o Firebird grava para cada
  // um. CHAR/VARCHAR (14/37) dependem do charset e ficam de fora.
  C_TIPOS_FIXOS: array[0..8] of TTipoFixo = (
    (Tipo: 7; Tamanho: 2; Nome: 'SMALLINT'),
    (Tipo: 8; Tamanho: 4; Nome: 'INTEGER'),
    (Tipo: 10; Tamanho: 4; Nome: 'FLOAT'),
    (Tipo: 12; Tamanho: 4; Nome: 'DATE'),
    (Tipo: 13; Tamanho: 4; Nome: 'TIME'),
    (Tipo: 16; Tamanho: 8; Nome: 'BIGINT/NUMERIC'),
    (Tipo: 27; Tamanho: 8; Nome: 'DOUBLE PRECISION'),
    (Tipo: 35; Tamanho: 8; Nome: 'TIMESTAMP'),
    (Tipo: 261; Tamanho: 8; Nome: 'BLOB'));

// Indice do tipo em C_TIPOS_FIXOS; -1 = tamanho variavel ou tipo desconhecido.
function IndiceTipoFixo(Tipo: Integer): Integer;
var
  I: Integer;
begin
  for I := Low(C_TIPOS_FIXOS) to High(C_TIPOS_FIXOS) do
    if C_TIPOS_FIXOS[I].Tipo = Tipo then
      Exit(I);
  Result := -1;
end;

// "CASE f.RDB$FIELD_TYPE WHEN 7 THEN 2 ... END": NULL para os tipos fora da tabela,
// entao a comparacao com o tamanho gravado nunca os seleciona.
function ExpressaoTamanhoDoTipo: string;
var
  I: Integer;
begin
  Result := 'CASE f.RDB$FIELD_TYPE';
  for I := Low(C_TIPOS_FIXOS) to High(C_TIPOS_FIXOS) do
    Result := Result + ' WHEN ' + IntToStr(C_TIPOS_FIXOS[I].Tipo) + ' THEN ' +
      IntToStr(C_TIPOS_FIXOS[I].Tamanho);
  Result := Result + ' END';
end;

class function TPreRequisitosConversao.ListarTamanhosInvalidos(const Gbak25,
  Database: string): TCamposTamanhoInvalido;
const
  C_TAM = '##TAM;';
var
  Isql, Texto, L, Correto: string;
  Linhas, Partes: TStringList;
  I, T: Integer;
begin
  SetLength(Result, 0);
  Isql := FerramentaFirebird25(Gbak25, 'isql.exe');
  Correto := ExpressaoTamanhoDoTipo;

  // So tabelas de usuario: views e campos calculados nao entram na mensagem de dados
  // do gbak. Tamanho nulo tambem quebra a mensagem (COALESCE).
  Texto := ExecutarScriptIsql(Isql, Database,
    'SET HEADING OFF;' + sLineBreak +
    'SELECT ''' + C_TAM + ''' || TRIM(rf.RDB$RELATION_NAME) || '';'' || TRIM(rf.RDB$FIELD_NAME) || '';'' || ' +
    'TRIM(f.RDB$FIELD_NAME) || '';'' || CAST(f.RDB$FIELD_TYPE AS VARCHAR(6)) || '';'' || ' +
    'CAST(COALESCE(f.RDB$FIELD_LENGTH, 0) AS VARCHAR(6)) ' +
    'FROM RDB$RELATION_FIELDS rf ' +
    'JOIN RDB$FIELDS f ON f.RDB$FIELD_NAME = rf.RDB$FIELD_SOURCE ' +
    'JOIN RDB$RELATIONS r ON r.RDB$RELATION_NAME = rf.RDB$RELATION_NAME ' +
    'WHERE COALESCE(r.RDB$SYSTEM_FLAG, 0) = 0 AND r.RDB$VIEW_BLR IS NULL ' +
    'AND f.RDB$COMPUTED_BLR IS NULL ' +
    'AND COALESCE(f.RDB$FIELD_LENGTH, 0) <> ' + Correto + ' ' +
    'ORDER BY rf.RDB$RELATION_NAME, rf.RDB$FIELD_POSITION;' + sLineBreak,
    'migrafacil_tamanho_meta');
  // o isql segue para o proximo comando quando um falha: a marca de fim sozinha nao
  // garante que a consulta rodou
  if ContainsText(Texto, 'Statement failed') or ContainsText(Texto, 'SQLSTATE') then
    raise Exception.Create('Falha ao conferir o tamanho dos campos: ' + Copy(Texto, 1, 800));

  Linhas := TStringList.Create;
  Partes := TStringList.Create;
  try
    Partes.StrictDelimiter := True;
    Partes.Delimiter := ';';
    Linhas.Text := Texto;
    for I := 0 to Linhas.Count - 1 do
    begin
      L := Trim(Linhas[I]);
      if Copy(L, 1, Length(C_TAM)) <> C_TAM then
        Continue;
      Partes.DelimitedText := Copy(L, Length(C_TAM) + 1, MaxInt);
      if Partes.Count < 5 then
        Continue;
      T := IndiceTipoFixo(StrToIntDef(Partes[3], 0));
      if T < 0 then
        Continue;
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)].Tabela := Partes[0];
      Result[High(Result)].Coluna := Partes[1];
      Result[High(Result)].Dominio := Partes[2];
      Result[High(Result)].Tipo := C_TIPOS_FIXOS[T].Tipo;
      Result[High(Result)].NomeTipo := C_TIPOS_FIXOS[T].Nome;
      Result[High(Result)].Tamanho := StrToIntDef(Partes[4], 0);
      Result[High(Result)].Correto := C_TIPOS_FIXOS[T].Tamanho;
    end;
  finally
    Partes.Free;
    Linhas.Free;
  end;
end;

class procedure TPreRequisitosConversao.CorrigirTamanhos(const Gbak25, Database: string;
  const Campos: TCamposTamanhoInvalido);
var
  Isql, Script, Texto: string;
  Dominios: TStringList;
  I, T: Integer;
begin
  Isql := FerramentaFirebird25(Gbak25, 'isql.exe');
  Script := EmptyStr;
  Dominios := TStringList.Create;
  try
    Dominios.Sorted := True;
    for I := Low(Campos) to High(Campos) do
    begin
      // dominio nomeado pode servir a varias colunas: um UPDATE por dominio
      T := IndiceTipoFixo(Campos[I].Tipo);
      if (T < 0) or (Dominios.IndexOf(Campos[I].Dominio) >= 0) then
        Continue;
      Dominios.Add(Campos[I].Dominio);
      // o tamanho vem da tabela de tipos, e o tipo na condicao impede tocar em
      // dominio que nao seja de tamanho fixo
      Script := Script + 'UPDATE RDB$FIELDS SET RDB$FIELD_LENGTH = ' +
        IntToStr(C_TIPOS_FIXOS[T].Tamanho) + ', RDB$CHARACTER_LENGTH = NULL ' +
        'WHERE RDB$FIELD_NAME = ' + LiteralSql(Campos[I].Dominio) +
        ' AND RDB$FIELD_TYPE = ' + IntToStr(C_TIPOS_FIXOS[T].Tipo) + ';' + sLineBreak;
    end;
  finally
    Dominios.Free;
  end;
  if Script = EmptyStr then
    Exit;
  Script := Script + 'COMMIT;' + sLineBreak;
  Texto := ExecutarScriptIsql(Isql, Database, Script, 'migrafacil_tamanho_fix');
  if ContainsText(Texto, 'Statement failed') or ContainsText(Texto, 'SQLSTATE') then
    raise Exception.Create('Falha ao corrigir o tamanho dos campos: ' + Copy(Texto, 1, 800));
end;

// "A, B" -> "A, B" com cada nome passado por Identificador (para DDL/SQL)
function ListaIdentificadores(const Colunas: string): string;
var
  Partes: TStringList;
  I: Integer;
begin
  Result := EmptyStr;
  Partes := TStringList.Create;
  try
    Partes.StrictDelimiter := True;
    Partes.Delimiter := ',';
    Partes.DelimitedText := Colunas;
    for I := 0 to Partes.Count - 1 do
    begin
      if Result <> EmptyStr then
        Result := Result + ', ';
      Result := Result + Identificador(Trim(Partes[I]));
    end;
  finally
    Partes.Free;
  end;
end;

class function TPreRequisitosConversao.ConstraintRemovivel(const C: TConstraintInvalida): Boolean;
begin
  Result := (C.Tipo = 'F') or (C.Dependentes = 0);
end;

class function TPreRequisitosConversao.ListarConstraintsInvalidas(const Gbak25, Database: string;
  TabelasSemLeitura: TStrings): TConstraintsInvalidas;
const
  C_FKS = '##FKS;';
  C_PKS = '##PKS;';
  C_CNT = '##CNT;';
type
  TSegmento = record
    Nome, Tabela, Coluna, TabelaRef, ColunaRef: string;
    Tipo: Char;
    Dependentes: Integer;
  end;
var
  Isql, Texto, L, Script, Cond, Junc, Nulo, Nome: string;
  Linhas, Partes, Lidas: TStringList;
  Lista: TConstraintsInvalidas;
  Segs: array of TSegmento;
  I, J, N, P: Integer;

  function IndiceDe(const ANome: string): Integer;
  var
    K: Integer;
  begin
    for K := Low(Lista) to High(Lista) do
      if Lista[K].Nome = ANome then
        Exit(K);
    Result := -1;
  end;

  function NovoItem(const S: TSegmento): Integer;
  begin
    SetLength(Lista, Length(Lista) + 1);
    Lista[High(Lista)].Nome := S.Nome;
    Lista[High(Lista)].Tabela := S.Tabela;
    Lista[High(Lista)].Tipo := S.Tipo;
    Lista[High(Lista)].TabelaRef := S.TabelaRef;
    Lista[High(Lista)].Dependentes := S.Dependentes;
    Lista[High(Lista)].Linhas := 0;
    Result := High(Lista);
  end;

begin
  SetLength(Lista, 0);
  Isql := FerramentaFirebird25(Gbak25, 'isql.exe');

  // 1) metadados: um registro por segmento de chave, na ordem da posicao
  Texto := ExecutarScriptIsql(Isql, Database,
    'SET HEADING OFF;' + sLineBreak +
    'SELECT ''' + C_FKS + ''' || TRIM(rc.RDB$CONSTRAINT_NAME) || '';'' || TRIM(rc.RDB$RELATION_NAME) || '';'' || ' +
    'TRIM(s.RDB$FIELD_NAME) || '';'' || TRIM(rc2.RDB$RELATION_NAME) || '';'' || TRIM(s2.RDB$FIELD_NAME) ' +
    'FROM RDB$RELATION_CONSTRAINTS rc ' +
    'JOIN RDB$INDEX_SEGMENTS s ON s.RDB$INDEX_NAME = rc.RDB$INDEX_NAME ' +
    'JOIN RDB$REF_CONSTRAINTS r ON r.RDB$CONSTRAINT_NAME = rc.RDB$CONSTRAINT_NAME ' +
    'JOIN RDB$RELATION_CONSTRAINTS rc2 ON rc2.RDB$CONSTRAINT_NAME = r.RDB$CONST_NAME_UQ ' +
    'JOIN RDB$INDEX_SEGMENTS s2 ON s2.RDB$INDEX_NAME = rc2.RDB$INDEX_NAME ' +
    'AND s2.RDB$FIELD_POSITION = s.RDB$FIELD_POSITION ' +
    'JOIN RDB$RELATIONS rel ON rel.RDB$RELATION_NAME = rc.RDB$RELATION_NAME ' +
    'WHERE rc.RDB$CONSTRAINT_TYPE = ''FOREIGN KEY'' AND COALESCE(rel.RDB$SYSTEM_FLAG, 0) = 0 ' +
    'ORDER BY rc.RDB$CONSTRAINT_NAME, s.RDB$FIELD_POSITION;' + sLineBreak +
    'SELECT ''' + C_PKS + ''' || TRIM(rc.RDB$CONSTRAINT_NAME) || '';'' || TRIM(rc.RDB$RELATION_NAME) || '';'' || ' +
    'TRIM(s.RDB$FIELD_NAME) || '';'' || IIF(rc.RDB$CONSTRAINT_TYPE = ''PRIMARY KEY'', ''P'', ''U'') || '';'' || ' +
    'CAST((SELECT COUNT(*) FROM RDB$REF_CONSTRAINTS d WHERE d.RDB$CONST_NAME_UQ = rc.RDB$CONSTRAINT_NAME) AS VARCHAR(6)) ' +
    'FROM RDB$RELATION_CONSTRAINTS rc ' +
    'JOIN RDB$INDEX_SEGMENTS s ON s.RDB$INDEX_NAME = rc.RDB$INDEX_NAME ' +
    'JOIN RDB$RELATIONS rel ON rel.RDB$RELATION_NAME = rc.RDB$RELATION_NAME ' +
    'WHERE rc.RDB$CONSTRAINT_TYPE IN (''PRIMARY KEY'', ''UNIQUE'') AND COALESCE(rel.RDB$SYSTEM_FLAG, 0) = 0 ' +
    'ORDER BY rc.RDB$CONSTRAINT_NAME, s.RDB$FIELD_POSITION;' + sLineBreak,
    'migrafacil_constraints_meta');

  Linhas := TStringList.Create;
  Partes := TStringList.Create;
  Lidas := TStringList.Create;
  try
    Partes.StrictDelimiter := True;
    Partes.Delimiter := ';';
    Lidas.Sorted := True;
    Lidas.Duplicates := dupIgnore;

    Linhas.Text := Texto;
    SetLength(Segs, Linhas.Count);
    N := 0;
    for I := 0 to Linhas.Count - 1 do
    begin
      L := Trim(Linhas[I]);
      if Copy(L, 1, 6) = C_FKS then
      begin
        Partes.DelimitedText := Copy(L, 7, MaxInt);
        if Partes.Count < 5 then
          Continue;
        Segs[N].Tipo := 'F';
        Segs[N].Nome := Partes[0];
        Segs[N].Tabela := Partes[1];
        Segs[N].Coluna := Partes[2];
        Segs[N].TabelaRef := Partes[3];
        Segs[N].ColunaRef := Partes[4];
        Segs[N].Dependentes := 0;
        Inc(N);
      end
      else if Copy(L, 1, 6) = C_PKS then
      begin
        Partes.DelimitedText := Copy(L, 7, MaxInt);
        if Partes.Count < 5 then
          Continue;
        Segs[N].Tipo := Partes[3][1];
        Segs[N].Nome := Partes[0];
        Segs[N].Tabela := Partes[1];
        Segs[N].Coluna := Partes[2];
        Segs[N].TabelaRef := EmptyStr;
        Segs[N].ColunaRef := EmptyStr;
        Segs[N].Dependentes := StrToIntDef(Partes[4], 0);
        Inc(N);
      end;
    end;
    SetLength(Segs, N);
    if N = 0 then
      Exit;

    // 2) agrupa por constraint (as colunas vem na ordem da chave)
    for I := 0 to N - 1 do
    begin
      P := IndiceDe(Segs[I].Nome);
      if P < 0 then
        P := NovoItem(Segs[I]);
      if Lista[P].Colunas <> EmptyStr then
      begin
        Lista[P].Colunas := Lista[P].Colunas + ', ';
        Lista[P].ColunasRef := Lista[P].ColunasRef + ', ';
      end;
      Lista[P].Colunas := Lista[P].Colunas + Segs[I].Coluna;
      Lista[P].ColunasRef := Lista[P].ColunasRef + Segs[I].ColunaRef;
    end;

    // 3) uma contagem por constraint
    Script := 'SET HEADING OFF;' + sLineBreak;
    for I := Low(Lista) to High(Lista) do
    begin
      Cond := EmptyStr;
      Junc := EmptyStr;
      Nulo := EmptyStr;
      for J := 0 to N - 1 do
        if Segs[J].Nome = Lista[I].Nome then
        begin
          if Cond <> EmptyStr then
          begin
            Cond := Cond + ' AND ';
            Junc := Junc + ' AND ';
            Nulo := Nulo + ' OR ';
          end;
          Cond := Cond + 'c.' + Identificador(Segs[J].Coluna) + ' IS NOT NULL';
          Junc := Junc + 'p.' + Identificador(Segs[J].ColunaRef) + ' = c.' + Identificador(Segs[J].Coluna);
          Nulo := Nulo + Identificador(Segs[J].Coluna) + ' IS NULL';
        end;
      if Lista[I].Tipo = 'F' then
        Script := Script + 'SELECT ' + LiteralSql(C_CNT + Lista[I].Nome + ';') +
          ' || CAST(COUNT(*) AS VARCHAR(12)) FROM ' + Identificador(Lista[I].Tabela) + ' c WHERE ' +
          Cond + ' AND NOT EXISTS (SELECT 1 FROM ' + Identificador(Lista[I].TabelaRef) + ' p WHERE ' +
          Junc + ');' + sLineBreak
      else
        Script := Script + 'SELECT ' + LiteralSql(C_CNT + Lista[I].Nome + ';') +
          ' || CAST(COUNT(*) AS VARCHAR(12)) FROM ' + Identificador(Lista[I].Tabela) + ' WHERE ' +
          Nulo + ';' + sLineBreak;
    end;
    Texto := ExecutarScriptIsql(Isql, Database, Script, 'migrafacil_constraints_cont');

    // 4) le "##CNT;NOME;n" e fica so com as que tem linhas
    Linhas.Text := Texto;
    for I := 0 to Linhas.Count - 1 do
    begin
      L := Trim(Linhas[I]);
      if Copy(L, 1, 6) <> C_CNT then
        Continue;
      Partes.DelimitedText := Copy(L, 7, MaxInt);
      if Partes.Count < 2 then
        Continue;
      Nome := Partes[0];
      Lidas.Add(Nome);
      P := IndiceDe(Nome);
      if P >= 0 then
        Lista[P].Linhas := StrToIntDef(Trim(Partes[1]), 0);
    end;

    if Assigned(TabelasSemLeitura) then
      for I := Low(Lista) to High(Lista) do
        if Lidas.IndexOf(Lista[I].Nome) < 0 then
          TabelasSemLeitura.Add(Lista[I].Nome + ' (' + Lista[I].Tabela + ')');

    J := 0;
    for I := Low(Lista) to High(Lista) do
      if Lista[I].Linhas > 0 then
      begin
        Lista[J] := Lista[I];
        Inc(J);
      end;
    SetLength(Lista, J);
    Result := Lista;
  finally
    Lidas.Free;
    Partes.Free;
    Linhas.Free;
  end;
end;

class function TPreRequisitosConversao.RemoverConstraints(const Gbak25, Database: string;
  const Lista: TConstraintsInvalidas): string;
var
  Isql, Script, Texto: string;
  I: Integer;
begin
  Result := EmptyStr;
  Isql := FerramentaFirebird25(Gbak25, 'isql.exe');
  Script := EmptyStr;
  for I := Low(Lista) to High(Lista) do
  begin
    if not ConstraintRemovivel(Lista[I]) then
      Continue;
    Script := Script + 'ALTER TABLE ' + Identificador(Lista[I].Tabela) + ' DROP CONSTRAINT ' +
      Identificador(Lista[I].Nome) + ';' + sLineBreak;
    // DDL basica para recriar (sem ON UPDATE/ON DELETE), para o log tecnico
    case Lista[I].Tipo of
      'F':
        Result := Result + 'ALTER TABLE ' + Identificador(Lista[I].Tabela) + ' ADD CONSTRAINT ' +
          Identificador(Lista[I].Nome) + ' FOREIGN KEY (' + ListaIdentificadores(Lista[I].Colunas) +
          ') REFERENCES ' + Identificador(Lista[I].TabelaRef) + ' (' +
          ListaIdentificadores(Lista[I].ColunasRef) + ');' + sLineBreak;
      'P':
        Result := Result + 'ALTER TABLE ' + Identificador(Lista[I].Tabela) + ' ADD CONSTRAINT ' +
          Identificador(Lista[I].Nome) + ' PRIMARY KEY (' + ListaIdentificadores(Lista[I].Colunas) +
          ');' + sLineBreak;
    else
      Result := Result + 'ALTER TABLE ' + Identificador(Lista[I].Tabela) + ' ADD CONSTRAINT ' +
        Identificador(Lista[I].Nome) + ' UNIQUE (' + ListaIdentificadores(Lista[I].Colunas) +
        ');' + sLineBreak;
    end;
  end;
  if Script = EmptyStr then
    Exit;
  Script := Script + 'COMMIT;' + sLineBreak;
  Texto := ExecutarScriptIsql(Isql, Database, Script, 'migrafacil_constraints_fix');
  if ContainsText(Texto, 'Statement failed') or ContainsText(Texto, 'SQLSTATE') then
    raise Exception.Create('Falha ao remover constraints invalidas: ' + Copy(Texto, 1, 800));
end;

end.
