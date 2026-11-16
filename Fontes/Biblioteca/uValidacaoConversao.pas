unit uValidacaoConversao;

{ Validacao, manifesto e rollback da conversao Firebird 2.5 -> 5.0.
  Plano: Infra-IA\Gestao\07-infra\plano-migracao-fb5-consolidado.md (Onda 1:
  O1-1 .fbk exato da execucao, O1-2 validacao antes de ativar, O1-3 rollback
  guiado, O1-4 marcador da conversao).

  Retrato: contagem de registros por tabela, valor de cada generator e
  contagem de objetos de usuario, tirado pelo isql da versao que atende o
  banco. O do 2.5 e tirado com o banco em shutdown single imediatamente antes
  do gbak; o do 5.0 sobre o banco restaurado, ANTES de ativa-lo. Em 02/10/2026,
  no banco Genio (318 tabelas, 7,4 milhoes de registros, 212 generators), o
  restore do gbak 5.0.4 reproduziu contagens, generators e objetos identicos.

  Manifesto: ultima_conversao.ini na pasta de backup, com o .fbk exato desta
  conversao, o retrato de origem e a copia do banco original. Sobrevive a um
  fechamento do MigraFacil entre o backup e o restore.

  Cabecalho do .FDB: ODS (offset 18, sem o bit 0x8000) e estado de shutdown
  (hdr_flags no offset 42, mascara 0x1080: 0x1000 full, 0x1080 single, 0x0080
  multi), lidos direto do arquivo, sem servidor. Conferido no FB 2.5.1. }

interface

uses
  System.SysUtils, System.Classes;

type
  TInfoCabecalhoFdb = record
    Valido: Boolean;
    ODS: Integer;          // 11 = Firebird 2.5; 13 = Firebird 4/5
    EmShutdown: Boolean;
  end;

  TValidacaoConversao = class
  public
    // Gera o retrato do banco no arquivo (linhas ##T/##G/##O/##X).
    class procedure GerarRetrato(const Isql, Database, ArquivoSaida: string); static;
    // Compara origem (2.5) e destino (5.0). Relatorio recebe o resumo e cada
    // divergencia. True = identicos, sem indice inativo e ODS 13 no destino.
    class function Comparar(const ArquivoOrigem, ArquivoDestino: string;
      Relatorio: TStrings): Boolean; static;
    class function LerCabecalho(const ArquivoFdb: string): TInfoCabecalhoFdb; static;
    class procedure IniciarManifesto(const PastaBackup: string); static;
    class procedure GravarManifesto(const PastaBackup, Chave, Valor: string); static;
    class function LerManifesto(const PastaBackup, Chave: string): string; static;
    // Marcador [ATUALIZADOR] do Config.ini ao fim da conversao (lido pelo GestaoUpdate).
    class procedure GravarMarcadorConversao(const ConfigIni, Fbk: string); static;
    // Rollback para o 2.5: o GestaoUpdate volta a tratar o cliente como transitorio.
    class procedure GravarMarcadorRetorno25(const ConfigIni: string); static;
  end;

implementation

uses
  System.IniFiles, System.IOUtils, System.Generics.Collections, uProcessoWindows,
  uMarcadorAtualizador;

const
  C_FB_USUARIO = 'sysdba';
  C_FB_SENHA = 'masterkey';
  C_MANIFESTO = 'ultima_conversao.ini';
  C_SECAO_MANIFESTO = 'Conversao';

function Aspas(const Valor: string): string;
begin
  Result := '"' + Valor + '"';
end;

function ScriptRetrato: string;
begin
  Result :=
    'SET HEADING OFF;' + sLineBreak +
    'SET TERM ^ ;' + sLineBreak +
    'EXECUTE BLOCK RETURNS (L VARCHAR(200)) AS' + sLineBreak +
    'DECLARE N VARCHAR(63); DECLARE V BIGINT;' + sLineBreak +
    'BEGIN' + sLineBreak +
    '  FOR SELECT TRIM(RDB$RELATION_NAME) FROM RDB$RELATIONS' + sLineBreak +
    '      WHERE COALESCE(RDB$SYSTEM_FLAG,0)=0 AND RDB$VIEW_BLR IS NULL' + sLineBreak +
    '        AND COALESCE(RDB$RELATION_TYPE,0)=0 ORDER BY 1 INTO :N DO' + sLineBreak +
    '  BEGIN' + sLineBreak +
    '    EXECUTE STATEMENT ''SELECT COUNT(*) FROM "'' || N || ''"'' INTO :V;' + sLineBreak +
    '    L = ''##T;'' || N || '';'' || V; SUSPEND;' + sLineBreak +
    '  END' + sLineBreak +
    '  FOR SELECT TRIM(RDB$GENERATOR_NAME) FROM RDB$GENERATORS' + sLineBreak +
    '      WHERE COALESCE(RDB$SYSTEM_FLAG,0)=0 ORDER BY 1 INTO :N DO' + sLineBreak +
    '  BEGIN' + sLineBreak +
    '    EXECUTE STATEMENT ''SELECT GEN_ID("'' || N || ''", 0) FROM RDB$DATABASE'' INTO :V;' + sLineBreak +
    '    L = ''##G;'' || N || '';'' || V; SUSPEND;' + sLineBreak +
    '  END' + sLineBreak +
    'END^' + sLineBreak +
    'SET TERM ; ^' + sLineBreak +
    'SELECT ''##O;INDICES;'' || COUNT(*) FROM RDB$INDICES WHERE COALESCE(RDB$SYSTEM_FLAG,0)=0;' + sLineBreak +
    'SELECT ''##O;INDICES_INATIVOS;'' || COUNT(*) FROM RDB$INDICES' +
    ' WHERE COALESCE(RDB$SYSTEM_FLAG,0)=0 AND RDB$INDEX_INACTIVE=1;' + sLineBreak +
    'SELECT ''##O;CONSTRAINTS_'' || TRIM(c.RDB$CONSTRAINT_TYPE) || '';'' || COUNT(*)' +
    ' FROM RDB$RELATION_CONSTRAINTS c JOIN RDB$RELATIONS r ON r.RDB$RELATION_NAME=c.RDB$RELATION_NAME' +
    ' WHERE COALESCE(r.RDB$SYSTEM_FLAG,0)=0 GROUP BY c.RDB$CONSTRAINT_TYPE;' + sLineBreak +
    'SELECT ''##O;TRIGGERS;'' || COUNT(*) FROM RDB$TRIGGERS WHERE COALESCE(RDB$SYSTEM_FLAG,0)=0;' + sLineBreak +
    'SELECT ''##O;PROCEDURES;'' || COUNT(*) FROM RDB$PROCEDURES WHERE COALESCE(RDB$SYSTEM_FLAG,0)=0;' + sLineBreak +
    'SELECT ''##O;VIEWS;'' || COUNT(*) FROM RDB$RELATIONS' +
    ' WHERE COALESCE(RDB$SYSTEM_FLAG,0)=0 AND RDB$VIEW_BLR IS NOT NULL;' + sLineBreak +
    'SELECT ''##X;ODS;'' || MON$ODS_MAJOR FROM MON$DATABASE;' + sLineBreak +
    'SELECT ''##FIM'' FROM RDB$DATABASE;' + sLineBreak;
end;

class procedure TValidacaoConversao.GerarRetrato(const Isql, Database, ArquivoSaida: string);
var
  Script, Saida, Cmd: string;
  Linhas, Retrato: TStringList;
  I: Integer;
  L: string;
begin
  if (Isql = EmptyStr) or (not FileExists(Isql)) then
    raise Exception.Create('isql.exe nao encontrado: ' + Isql);
  Script := TPath.Combine(TPath.GetTempPath, 'migrafacil_retrato.sql');
  Saida := TPath.Combine(TPath.GetTempPath, 'migrafacil_retrato.txt');
  TFile.WriteAllText(Script, ScriptRetrato, TEncoding.ANSI);
  Linhas := TStringList.Create;
  Retrato := TStringList.Create;
  try
    Cmd := '/C "' + Aspas(Isql) + ' -q -user ' + C_FB_USUARIO + ' -password ' + C_FB_SENHA +
      ' -i ' + Aspas(Script) + ' ' + Aspas(Database) + ' > ' + Aspas(Saida) + ' 2>&1"';
    TProcessoWindows.ExecutarElevadoEAguardar(TProcessoWindows.ProcessadorComandos, Cmd, nil);
    if FileExists(Saida) then
      Linhas.Text := TFile.ReadAllText(Saida, TEncoding.ANSI);
    for I := 0 to Linhas.Count - 1 do
    begin
      L := Trim(Linhas[I]);
      if Copy(L, 1, 2) = '##' then
        Retrato.Add(L);
    end;
    if Retrato.IndexOf('##FIM') < 0 then
      raise Exception.Create('Nao foi possivel tirar o retrato do banco ' + Database + ': ' +
        Trim(Linhas.Text));
    ForceDirectories(ExtractFilePath(ArquivoSaida));
    Retrato.SaveToFile(ArquivoSaida, TEncoding.ANSI);
  finally
    Retrato.Free;
    Linhas.Free;
    System.SysUtils.DeleteFile(Script);
    System.SysUtils.DeleteFile(Saida);
  end;
end;

// Le um retrato em Dicionario[tipo;nome] = valor (sem o '##' inicial e sem ##FIM)
function CarregarRetrato(const Arquivo: string): TDictionary<string, string>;
var
  Linhas: TStringList;
  I, P: Integer;
  L: string;
begin
  if not FileExists(Arquivo) then
    raise Exception.Create('Retrato do banco nao encontrado: ' + Arquivo);
  Result := TDictionary<string, string>.Create;
  Linhas := TStringList.Create;
  try
    Linhas.LoadFromFile(Arquivo, TEncoding.ANSI);
    for I := 0 to Linhas.Count - 1 do
    begin
      L := Trim(Linhas[I]);
      if (Copy(L, 1, 2) <> '##') or (L = '##FIM') then
        Continue;
      L := Copy(L, 3, MaxInt);
      P := LastDelimiter(';', L);
      if P > 0 then
        Result.AddOrSetValue(Copy(L, 1, P - 1), Copy(L, P + 1, MaxInt));
    end;
  finally
    Linhas.Free;
  end;
end;

class function TValidacaoConversao.Comparar(const ArquivoOrigem, ArquivoDestino: string;
  Relatorio: TStrings): Boolean;
var
  Origem, Destino: TDictionary<string, string>;
  Chave, VDest: string;
  Tabelas, Generators, Divergencias: Integer;
  Registros: Int64;
begin
  Origem := CarregarRetrato(ArquivoOrigem);
  Destino := CarregarRetrato(ArquivoDestino);
  try
    Tabelas := 0;
    Generators := 0;
    Divergencias := 0;
    Registros := 0;
    for Chave in Origem.Keys do
    begin
      if Copy(Chave, 1, 2) = 'X;' then
        Continue;
      if not Destino.TryGetValue(Chave, VDest) then
      begin
        Inc(Divergencias);
        Relatorio.Add('Ausente no banco convertido: ' + Chave + ' (origem ' + Origem[Chave] + ')');
        Continue;
      end;
      if VDest <> Origem[Chave] then
      begin
        Inc(Divergencias);
        Relatorio.Add('Diferente: ' + Chave + ' origem ' + Origem[Chave] + ' / convertido ' + VDest);
        Continue;
      end;
      if Copy(Chave, 1, 2) = 'T;' then
      begin
        Inc(Tabelas);
        Registros := Registros + StrToInt64Def(VDest, 0);
      end
      else if Copy(Chave, 1, 2) = 'G;' then
        Inc(Generators);
    end;
    for Chave in Destino.Keys do
      if (Copy(Chave, 1, 2) <> 'X;') and (not Origem.ContainsKey(Chave)) then
      begin
        Inc(Divergencias);
        Relatorio.Add('Sobrando no banco convertido: ' + Chave + ' (' + Destino[Chave] + ')');
      end;
    if Destino.TryGetValue('O;INDICES_INATIVOS', VDest) and (VDest <> '0') then
    begin
      Inc(Divergencias);
      Relatorio.Add('Indices inativos no banco convertido: ' + VDest);
    end;
    if (not Destino.TryGetValue('X;ODS', VDest)) or (StrToIntDef(VDest, 0) < 13) then
    begin
      Inc(Divergencias);
      Relatorio.Add('ODS do banco convertido nao e de Firebird 4/5: ' + VDest);
    end;
    Relatorio.Insert(0, Format('Conferencia: %d tabelas (%d registros), %d generators, objetos de usuario; ' +
      '%d divergencia(s).', [Tabelas, Registros, Generators, Divergencias]));
    Result := Divergencias = 0;
  finally
    Origem.Free;
    Destino.Free;
  end;
end;

class function TValidacaoConversao.LerCabecalho(const ArquivoFdb: string): TInfoCabecalhoFdb;
var
  Fluxo: TFileStream;
  Buffer: array[0..127] of Byte;
begin
  Result.Valido := False;
  Result.ODS := 0;
  Result.EmShutdown := False;
  if (ArquivoFdb = EmptyStr) or (not FileExists(ArquivoFdb)) then
    Exit;
  try
    Fluxo := TFileStream.Create(ArquivoFdb, fmOpenRead or fmShareDenyNone);
    try
      if Fluxo.Size < SizeOf(Buffer) then
        Exit;
      Fluxo.ReadBuffer(Buffer, SizeOf(Buffer));
    finally
      Fluxo.Free;
    end;
  except
    Exit;
  end;
  if Buffer[0] <> 1 then // pag_type 1 = header page
    Exit;
  Result.ODS := PWord(@Buffer[18])^ and $7FFF;
  Result.EmShutdown := (PWord(@Buffer[42])^ and $1080) <> 0;
  Result.Valido := (Result.ODS >= 8) and (Result.ODS <= 20);
end;

function ArquivoManifesto(const PastaBackup: string): string;
begin
  Result := IncludeTrailingPathDelimiter(PastaBackup) + C_MANIFESTO;
end;

class procedure TValidacaoConversao.IniciarManifesto(const PastaBackup: string);
var
  Ini: TIniFile;
begin
  ForceDirectories(PastaBackup);
  Ini := TIniFile.Create(ArquivoManifesto(PastaBackup));
  try
    Ini.EraseSection(C_SECAO_MANIFESTO);
    Ini.WriteString(C_SECAO_MANIFESTO, 'Inicio', FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

class procedure TValidacaoConversao.GravarManifesto(const PastaBackup, Chave, Valor: string);
var
  Ini: TIniFile;
begin
  ForceDirectories(PastaBackup);
  Ini := TIniFile.Create(ArquivoManifesto(PastaBackup));
  try
    Ini.WriteString(C_SECAO_MANIFESTO, Chave, Valor);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

class function TValidacaoConversao.LerManifesto(const PastaBackup, Chave: string): string;
var
  Ini: TIniFile;
begin
  Result := EmptyStr;
  if not FileExists(ArquivoManifesto(PastaBackup)) then
    Exit;
  Ini := TIniFile.Create(ArquivoManifesto(PastaBackup));
  try
    Result := Trim(Ini.ReadString(C_SECAO_MANIFESTO, Chave, ''));
  finally
    Ini.Free;
  end;
end;

class procedure TValidacaoConversao.GravarMarcadorConversao(const ConfigIni, Fbk: string);
var
  Marcador: TMarcadorLocal;
  Ini: TIniFile;
begin
  // Onda 2 (O2-3): mesmo contrato de gravacao do GestaoUpdate (uMarcadorAtualizador)
  Marcador := Fc_LerMarcadorAtualizador(ConfigIni);
  Marcador.Firebird := '5.0';
  Marcador.Transitorio := False;
  Pc_GravarMarcadorAtualizador(ConfigIni, Marcador);
  // Registro da conversao (o GestaoUpdate preserva chaves que nao conhece)
  Ini := TIniFile.Create(ConfigIni);
  try
    Ini.WriteString(C_SECAO_ATUALIZADOR, 'ConversaoFB5', FormatDateTime('dd/mm/yyyy hh:nn', Now));
    Ini.WriteString(C_SECAO_ATUALIZADOR, 'ConversaoFbk', Fbk);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

class procedure TValidacaoConversao.GravarMarcadorRetorno25(const ConfigIni: string);
var
  Marcador: TMarcadorLocal;
  Ini: TIniFile;
begin
  Marcador := Fc_LerMarcadorAtualizador(ConfigIni);
  Marcador.Firebird := '2.5';
  // transitorio (Gestao 2026 sobre o 2.5) so existe na linha 2026; na 2016 nao se aplica
  Marcador.Transitorio := Marcador.Linha = C_MARCADOR_LINHA_2026;
  Pc_GravarMarcadorAtualizador(ConfigIni, Marcador);
  Ini := TIniFile.Create(ConfigIni);
  try
    Ini.WriteString(C_SECAO_ATUALIZADOR, 'RetornoFB25', FormatDateTime('dd/mm/yyyy hh:nn', Now));
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

end.
