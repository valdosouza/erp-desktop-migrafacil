unit uPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.Mask, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  FireDAC.UI.Intf, FireDAC.Stan.Async, FireDAC.Comp.ScriptCommands,
  FireDAC.Stan.Util, FireDAC.Stan.Intf, FireDAC.Comp.Script,
  System.UITypes, System.ImageList, System.IOUtils,
  Vcl.ImgList, Vcl.Menus;

type
  // 09/10/2026: resultado de ReabrirBancoFirebird25; a mensagem final depende dele.
  // rbAberto = banco aberto no 2.5; rbPreservadoFechado = fechado de proposito (2.5
  // removido ou remocao agendada para o boot); rbFalhou = devia abrir e nao abriu.
  TResultadoReabertura = (rbAberto, rbPreservadoFechado, rbFalhou);

  TFormPrincipal = class(TForm)
    pgcPrincipal: TPageControl;
    gbxAcoes: TGroupBox;
    StatusBarProcesso: TStatusBar;
    gbxConfigIni: TGroupBox;
    edtDatabase: TLabeledEdit;
    tabLogTecnico: TTabSheet;
    tabFerramentas: TTabSheet;
    gbxDiagnostico: TGroupBox;
    gbxLogTecnico: TGroupBox;
    reLogTecnico: TRichEdit;
    pnlLog: TPanel;
    gbxLog: TGroupBox;
    reLog: TRichEdit;
    tabMigracao: TTabSheet;
    btnBackup: TButton;
    btnAtualizarFB2_5_E_Instalar_5: TButton;
    btnRestore: TButton;
    btnIniciarMigracao: TButton;
    gbxFerramentas: TGroupBox;
    btnTestarConexao: TButton;
    btn_DetectarVersaoFB: TButton;
    PopupMenuRemoverFB: TPopupMenu;
    popupRemoverFB5_E_Instalar_2_5Click: TMenuItem;
    popupRemoverFB2_5_E_Instalar_5Click: TMenuItem;
    menuSeparadorRemocao: TMenuItem;
    popupRemoverSomenteFB5: TMenuItem;
    popupRemoverSomenteFB25: TMenuItem;
    menuSeparadorInstalacao: TMenuItem;
    popupInstalarFB5: TMenuItem;
    popupInstalarFB25: TMenuItem;
    btnRestaurarFbkFB5: TButton;
    btnLimparLogs: TButton;
    btnProcurarBanco: TButton;
    btnSalvarBanco: TButton;
    gbxInstalarRemover: TGroupBox;
    btnRemoverFB5_E_Instalar_2_5Click: TButton;
    btnRemoverFB2_5_E_Instalar_5Click: TButton;
    btnRemoverSomenteFB5: TButton;
    btnRemoverSomenteFB25: TButton;
    btnInstalarFB5: TButton;
    btnInstalarFB25: TButton;
    procedure btnTestarConexaoClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnBackupClick(Sender: TObject);
    procedure btnAtualizarFB2_5_E_Instalar_5Click(Sender: TObject);
    procedure btnRestoreClick(Sender: TObject);
    procedure btnIniciarMigracaoClick(Sender: TObject);
    procedure btn_DetectarVersaoFBClick(Sender: TObject);
    procedure popupRemoverFB2_5_E_Instalar_5ClickClick(Sender: TObject);
    procedure popupRemoverFB5_E_Instalar_2_5ClickClick(Sender: TObject);
    procedure popupRemoverSomenteFB5Click(Sender: TObject);
    procedure popupRemoverSomenteFB25Click(Sender: TObject);
    procedure popupInstalarFB5Click(Sender: TObject);
    procedure popupInstalarFB25Click(Sender: TObject);
    procedure btnRestaurarFbkFB5Click(Sender: TObject);
    procedure btnLimparLogsClick(Sender: TObject);
    procedure btnProcurarBancoClick(Sender: TObject);
    procedure btnSalvarBancoClick(Sender: TObject);
  private
    { Private declarations }
    FUltimaEtapaExecutadaComSucesso: Boolean;
    FProcessoEmAndamento: Boolean;
    FBackupBancoOriginalAtual: string;
    FBancoOriginalCopiado: string;
    FLogProcessoFileName: string;
    FOtimizacaoFb5Pendente: Boolean;
    FVersaoServidor: string;
    FClienteLinha2026: Boolean;
    // 09/10/2026: log tecnico persistido (mesma pasta e carimbo do log do processo)
    FLogTecnicoFileName: string;
    // 09/10/2026: Guardian do 2.5 estava rodando antes do reinicio (volta junto)
    FGuardian25Rodando: Boolean;
    // 09/10/2026: banco em shutdown single desde o inicio da migracao
    FBancoEmModoExclusivo: Boolean;
    procedure CarregarDadosArquivoIni;
    procedure AtualizarEstadoBanco;
    procedure TestarConexaoBanco(const ExibirMensagem: Boolean;
      const DatabaseTeste: string = '');
    procedure ValidarFbClientDescarregado;
    procedure ValidarServidorEhFirebird25;
    procedure ValidarServicoFirebird25;
    procedure ValidarPreRequisitosSomenteLeitura;
    function ListarConexoesQueSeraoDerrubadas: Integer;
    procedure ReiniciarServicoFirebird25;
    procedure ColocarBancoEmModoExclusivo;
    procedure ValidarPreRequisitosEmModoExclusivo;
    procedure ReabrirBancoParaMigracaoNova;
    function PortaDoBanco: Word;
    function GarantirServidorFirebird25Rodando(out Motivo: string): Boolean;
    function RemocaoFirebird25AgendadaNoBoot: Boolean;
    function ServicoFirebird25NaPasta(const Pasta: string): Boolean;
    function Firebird25SoSobras: Boolean;
    procedure InformarInterrupcao(const MensagemEtapa: string);
    procedure AtualizarStatus(const Texto: string);
    procedure IniciarLogProcesso;
    procedure GravarLogProcesso(const Linha: string);
    procedure GravarLogTecnicoArquivo(const Linha: string);

    function RunAndWait(const Exe, Params: string): Boolean;
    function QuoteParam(const Value: string): string;
    function BackupDirectory: string;
    function BackupFileName: string;
    function LatestBackupFileName: string;
    function RestoreDatabaseName: string;
    function NormalizeGbakDatabaseName(const DatabaseName: string): string;
    function ConvertedDatabaseName: string;
    function OriginalDatabaseBackupFileName(const DatabaseFileName: string): string;
    function LocalDatabaseFileName(const DatabaseName: string): string;
    function FormatDuration(const Milliseconds: UInt64): string;
    function CommandProcessor: string;
    function GbakLogFileName(const Prefix: string): string;
    procedure LogTextFile(const FileName: string; const Titulo: string; Cor: TColor);
    procedure LogTecnico(const Texto: string; Cor: TColor);
    procedure LogFirebird(const Texto: string; Cor: TColor);
    procedure ExecutarInstalacaoFirebird(const Versao5: Boolean);
    procedure ExecutarEtapaBackup;
    procedure ExecutarEtapaAtualizacaoFirebird;
    procedure ExecutarEtapaInstalacaoFirebird25;
    procedure ExecutarEtapaRestoreFirebird5;
    procedure ExecutarBackupFirebird25;
    procedure ValidarBancoSemConexoes;
    procedure ValidarColunasNotNullComNulos;
    procedure ValidarConstraintsInvalidas;
    procedure ValidarTamanhoDosCampos;
    function ReabrirBancoFirebird25(out Orientacao: string): TResultadoReabertura;
    function FerramentaFirebird5(const Nome: string): string;
    function AplicarTuningFirebird5: Boolean;
    procedure AvisarConclusao(const TextoSucesso: string);
    procedure RetomarBancoOriginal25;
    function DetectarConversaoInterrompida: string;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CopiarBancoOrigemParaSeguranca(const DatabaseFileName: string);
    procedure MoverBancoOrigemParaLiberarRestore(const DatabaseFileName: string);
    procedure SubstituirBancoOriginalPeloConvertido(const DatabaseFileName,
      ConvertedFileName: string);
    procedure ExecutarRestoreFirebird5;
    procedure RemoverInstalacaoFirebird5;
    procedure LimparResiduosFirebird5(const Pasta: string);
    function ArquivoFaltandoFirebird5(const Pasta: string): string;
    procedure RemoverTodasInstalacoesFirebird25;
    procedure AtualizarFirebird2_5;
    function Firebird5Aceitavel(out Motivo: string): Boolean;
    procedure GarantirServidorFirebird5(const InstaladorObtido: string);
    procedure AtualizarFirebird5_Para_2_5;
  public
    { Public declarations }
  end;

var
  FormPrincipal: TFormPrincipal;

implementation

uses
  uConfigIni, uConst, uMensagens, uFuncoes, uProcessoWindows,
  uFirebirdAmbiente, uFirebirdServicos, uFirebirdInstalacoes,
  uFirebirdPacotes, uPreRequisitosConversao,
  uValidacaoConversao, uFirebirdTuning, uGbakPadrao, uFbClientAutomatico, uSegurancaFirebird5,
  System.StrUtils;

{$R *.dfm}

const
  // 09/10/2026: servicos da instancia padrao (2.5 antes da migracao)
  C_SERVICO_FB25 = 'FirebirdServerDefaultInstance';
  C_SERVICO_GUARDIAN_FB25 = 'FirebirdGuardianDefaultInstance';

procedure TFormPrincipal.FormShow(Sender: TObject);
begin
  // O3-2: nao fechar no meio de uma etapa (gbak, instalador, troca do banco)
  OnCloseQuery := FormCloseQuery;
  Caption := TAplicacaoInfo.Titulo;
  TConsole.FormatarEditor(reLog);
  TConsole.FormatarEditor(reLogTecnico);
  CarregarDadosArquivoIni;
  pgcPrincipal.ActivePage := tabMigracao;
  AtualizarEstadoBanco;

  if TAppConfig.Database = EmptyStr then
  begin
    // nao fecha: o operador informa o banco e grava no Config.ini (Salvar)
    LogFirebird(SMsgBancoDadosNaoEncontrado, clYellow);
    TMensagens.Aviso(SMsgBancoDadosNaoEncontrado + sLineBreak + sLineBreak +
      'Informe o caminho em "Caminho do Banco de Dados" (ou use Procurar...) e ' +
      'clique em "Salvar no Config.ini".');
  end;
end;

procedure TFormPrincipal.ValidarFbClientDescarregado;
var
  Modulo: HMODULE;
  BufferModulo: array[0..MAX_PATH] of Char;
  CaminhoModulo: string;
  ClienteLocal: string;
begin
  Modulo := GetModuleHandle(PChar(FB_CLIENT));
  if Modulo = 0 then
  begin
    Exit;
  end;

  FillChar(BufferModulo, SizeOf(BufferModulo), 0);
  if GetModuleFileName(Modulo, BufferModulo, Length(BufferModulo)) = 0 then
    raise Exception.Create('Nao foi possivel identificar a fbclient.dll carregada pelo MigraFacil.');

  CaminhoModulo := string(BufferModulo);
  LogFirebird('Verificacao: fbclient.dll carregada pelo MigraFacil: ' +
    CaminhoModulo, clYellow);
  ClienteLocal := TFbClientAutomatico.CaminhoCliente(ExtractFilePath(ParamStr(0)));
  if SameText(CaminhoModulo, ClienteLocal) then
    raise Exception.Create('A fbclient.dll da pasta do MigraFacil ainda esta carregada. ' +
      'A migracao foi interrompida antes da troca do Firebird.');
end;

function TFormPrincipal.DetectarConversaoInterrompida: string;
var
  Etapa: string;
  Fbk: string;
  Retrato: string;
  Cabecalho: TInfoCabecalhoFdb;
begin
  // O3-1: conversao iniciada e nao concluida (manifesto ultima_conversao.ini).
  // So retoma com o banco original ainda fechado (ODS 11 em shutdown) e com o
  // backup e o retrato desta conversao no disco.
  Result := EmptyStr;
  Etapa := TValidacaoConversao.LerManifesto(BackupDirectory, 'Etapa');
  if (Etapa <> 'backup') and (Etapa <> 'firebird5') then
    Exit;
  if TValidacaoConversao.LerManifesto(BackupDirectory, 'Concluida') <> EmptyStr then
    Exit;
  Fbk := TValidacaoConversao.LerManifesto(BackupDirectory, 'Fbk');
  Retrato := TValidacaoConversao.LerManifesto(BackupDirectory, 'RetratoOrigem');
  if (Fbk = EmptyStr) or (not FileExists(Fbk)) or
     (Retrato = EmptyStr) or (not FileExists(Retrato)) then
    Exit;
  Cabecalho := TValidacaoConversao.LerCabecalho(LocalDatabaseFileName(TAppConfig.Database));
  if Cabecalho.Valido and (Cabecalho.ODS = 11) and Cabecalho.EmShutdown then
    Result := Etapa;
end;

procedure TFormPrincipal.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // O3-2: fechar no meio de uma etapa deixaria gbak/instalador sem controle
  CanClose := not FProcessoEmAndamento;
  if not CanClose then
    TMensagens.Aviso(SMsgProcessoEmAndamento);
end;

procedure TFormPrincipal.TestarConexaoBanco(const ExibirMensagem: Boolean;
  const DatabaseTeste: string);
const
  C_TIMEOUT_TESTE_CONEXAO_MS = 120000;
var
  ArquivoErro: string;
  Comando: string;
  Inicio: TStartupInfo;
  Processo: TProcessInformation;
  ResultadoEspera: DWORD;
  CodigoSaida: DWORD;
  Detalhe: string;
  InicioEspera: UInt64;
begin
  // PC novo / MigraFacil fora do Bin: baixa o fbclient 4.x se nao estiver ao lado do .exe
  TFbClientAutomatico.Garantir(ExtractFilePath(ParamStr(0)), LogFirebird, LogTecnico,
    AtualizarStatus);

  // O FireDAC pode manter fbclient.dll carregada ate o fim do processo.
  // A validacao isolada permite trocar a DLL apos o restore.
  ArquivoErro := TPath.GetTempFileName;
  try
    Comando := QuoteParam(ParamStr(0)) + ' /testeconexao ' +
      QuoteParam(ArquivoErro);
    // O1-2: permite testar o banco convertido antes de ativa-lo
    if DatabaseTeste <> EmptyStr then
      Comando := Comando + ' ' + QuoteParam(DatabaseTeste);
    ZeroMemory(@Inicio, SizeOf(Inicio));
    Inicio.cb := SizeOf(Inicio);
    ZeroMemory(@Processo, SizeOf(Processo));

    if not CreateProcess(PChar(ParamStr(0)), PChar(Comando), nil, nil,
      False, CREATE_NO_WINDOW, nil, nil, Inicio, Processo) then
      raise Exception.Create('Nao foi possivel iniciar o teste de conexao: ' +
        SysErrorMessage(GetLastError));

    try
      // O3-2: espera com limite (servidor parado ou rede travada nao prendem o migrador)
      InicioEspera := GetTickCount64;
      repeat
        ResultadoEspera := WaitForSingleObject(Processo.hProcess, 250);
        Application.ProcessMessages;
      until (ResultadoEspera <> WAIT_TIMEOUT) or
            (GetTickCount64 - InicioEspera > C_TIMEOUT_TESTE_CONEXAO_MS);
      if ResultadoEspera = WAIT_TIMEOUT then
      begin
        TerminateProcess(Processo.hProcess, 1);
        raise Exception.Create('O teste de conexão não respondeu em ' +
          IntToStr(C_TIMEOUT_TESTE_CONEXAO_MS div 1000) +
          ' segundos (servidor Firebird parado ou rede travada?).');
      end;

      if ResultadoEspera <> WAIT_OBJECT_0 then
        raise Exception.Create('Falha ao aguardar o teste de conexao: ' +
          SysErrorMessage(GetLastError));

      if not GetExitCodeProcess(Processo.hProcess, CodigoSaida) then
        raise Exception.Create('Falha ao obter o resultado do teste de conexao: ' +
          SysErrorMessage(GetLastError));

      if CodigoSaida <> 0 then
      begin
        Detalhe := Trim(TFile.ReadAllText(ArquivoErro, TEncoding.UTF8));
        if Detalhe = EmptyStr then
          Detalhe := 'O processo de teste terminou com codigo ' +
            IntToStr(CodigoSaida) + '.';
        raise Exception.Create(Detalhe);
      end;

      // conectou: o processo filho grava ENGINE=<versao do motor> no arquivo
      FVersaoServidor := EmptyStr;
      Detalhe := Trim(TFile.ReadAllText(ArquivoErro, TEncoding.UTF8));
      if SameText(Copy(Detalhe, 1, 7), 'ENGINE=') then
        FVersaoServidor := Trim(Copy(Detalhe, 8, MaxInt));
    finally
      CloseHandle(Processo.hThread);
      CloseHandle(Processo.hProcess);
    end;

    ValidarFbClientDescarregado;

    if ExibirMensagem then
      TMensagens.Sucesso('Conexão com o banco de dados realizada com sucesso.');
  finally
    DeleteFile(ArquivoErro);
  end;
end;

procedure TFormPrincipal.ValidarPreRequisitosSomenteLeitura;
var
  Database: string;
  DatabaseFile: string;
  Fase: string;
begin
  // 09/10/2026: passo 1 do inicio da migracao. SOMENTE LEITURA: nada muda no banco
  // nem no servico. Confirma que quem responde e o 2.5 (ODS 11) ANTES de reiniciar
  // qualquer servico: nunca reiniciar um Firebird 5 de cliente ja migrado.
  Database := TAppConfig.Database;
  if Database = EmptyStr then
    raise Exception.Create('Caminho do banco não informado no Config.ini.');

  edtDatabase.Text := Database;
  DatabaseFile := LocalDatabaseFileName(Database);

  LogTecnico('Banco configurado para conexão: ' + Database, clGray);

  if (DatabaseFile = EmptyStr) or (not FileExists(DatabaseFile)) then
    raise Exception.Create('Arquivo do banco de dados não encontrado: ' +
      DatabaseFile);

  LogFirebird('Testando a conexão com o banco de dados...', clAqua);
  TestarConexaoBanco(False);
  LogFirebird('Conexão com o banco de dados validada com sucesso.', clLime);
  ValidarServidorEhFirebird25;
  ValidarServicoFirebird25;

  // 03/10/2026: MigraFacil independente do GestaoUpdate. A fase do Config.ini so
  // informa (e muda o aviso da confirmacao); quem bloqueia e o servidor nao ser o 2.5.
  Fase := TPreRequisitosConversao.DescreverFase(
    IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + CONFIG_INI, FClienteLinha2026);
  if FClienteLinha2026 then
    LogFirebird(Fase, clLime)
  else
    LogFirebird(Fase, clYellow);
end;

function TFormPrincipal.ListarConexoesQueSeraoDerrubadas: Integer;
var
  Conexoes: TStringList;
  I: Integer;
begin
  // 09/10/2026: passo 2, so informativo (nao bloqueia): quem estiver conectado cai
  // no reinicio do servico. -1 = listagem falhou.
  Result := -1;
  try
    LogFirebird('Verificando conexões ativas no banco de dados...', clAqua);
    Conexoes := TPreRequisitosConversao.ListarConexoes(TFirebirdAmbiente.Gbak25,
      NormalizeGbakDatabaseName(TAppConfig.Database));
    try
      Result := Conexoes.Count;
      if Result = 0 then
        LogFirebird('Nenhuma conexão ativa no banco de dados.', clLime)
      else
        for I := 0 to Conexoes.Count - 1 do
          LogFirebird('Conexão que será derrubada pelo reinício: ' + Conexoes[I], clYellow);
    finally
      Conexoes.Free;
    end;
  except
    on E: Exception do
      LogTecnico('Aviso: não foi possível listar as conexões ativas antes do reinício: ' +
        E.Message, clYellow);
  end;
end;

procedure TFormPrincipal.ColocarBancoEmModoExclusivo;
begin
  // 09/10/2026: passo 5, logo depois do reinicio do servico. gfix -shut single
  // -force 0: derruba quem tiver entrado no meio e deixa uma conexao SYSDBA por vez.
  LogFirebird('Colocando o banco de dados em modo exclusivo...', clYellow);
  TPreRequisitosConversao.ColocarEmShutdown(TFirebirdAmbiente.Gbak25,
    NormalizeGbakDatabaseName(TAppConfig.Database));
  FBancoEmModoExclusivo := True;
  LogFirebird('Banco de dados em modo exclusivo (somente o MigraFacil acessa).', clLime);
end;

procedure TFormPrincipal.ValidarPreRequisitosEmModoExclusivo;
begin
  // 09/10/2026: passo 6, ja em modo exclusivo. As conferencias usam o isql em
  // processos sequenciais (um por vez), o que o shutdown single aceita.
  // O0-7: sanidade - ninguem conectado alem do MigraFacil.
  ValidarBancoSemConexoes;
  ValidarColunasNotNullComNulos;
  ValidarConstraintsInvalidas;
  ValidarTamanhoDosCampos;
end;

procedure TFormPrincipal.ReabrirBancoParaMigracaoNova;
var
  Motivo: string;
  Erro: string;
  Etapa: string;
begin
  // 09/10/2026 (item e): banco ja fechado (shutdown) no inicio e o operador pediu uma
  // migracao nova. So com o Firebird 2.5 confirmado. O online e obrigatorio: o 2.5
  // recusa ir de shutdown full direto para single.
  // (as mensagens de erro nao repetem "continua fechado": quem chama ja informa)
  ValidarServicoFirebird25;
  if not GarantirServidorFirebird25Rodando(Motivo) then
    raise Exception.Create('Não foi possível reabrir o banco de dados: ' + Motivo + '.');
  if not TPreRequisitosConversao.TentarOnline(TFirebirdAmbiente.Gbak25,
       NormalizeGbakDatabaseName(TAppConfig.Database), Erro) then
    raise Exception.Create(Erro);

  // a tentativa velha nao pode mais ser oferecida como retomada (o backup dela nao
  // tem o que for gravado daqui em diante)
  Etapa := TValidacaoConversao.LerManifesto(BackupDirectory, 'Etapa');
  if ((Etapa = 'backup') or (Etapa = 'firebird5')) and
     (TValidacaoConversao.LerManifesto(BackupDirectory, 'Concluida') = EmptyStr) then
  begin
    TValidacaoConversao.GravarManifesto(BackupDirectory, 'Etapa', 'abandonada');
    LogTecnico('Manifesto da tentativa interrompida marcado como abandonado (etapa anterior: ' +
      Etapa + ').', clGray);
  end;
  LogFirebird('Banco de dados reaberto para iniciar uma migração nova.', clLime);
end;

procedure TFormPrincipal.ValidarServidorEhFirebird25;
var
  Cabecalho: TInfoCabecalhoFdb;
  Gbak25: string;
begin
  // Identifica o servidor que esta RESPONDENDO (ENGINE_VERSION da conexao que acabou de
  // dar certo) e o formato do arquivo (ODS). So converte quem ainda esta no 2.5: impede a
  // segunda execucao (servidor ja no Firebird 5) e servidor de outra familia.
  Cabecalho := TValidacaoConversao.LerCabecalho(LocalDatabaseFileName(TAppConfig.Database));
  if FVersaoServidor <> EmptyStr then
    LogFirebird('Servidor Firebird em execução: ' + FVersaoServidor + IfThen(Cabecalho.Valido,
      ' (ODS ' + IntToStr(Cabecalho.ODS) + ')', EmptyStr) + '.', clAqua)
  else
    LogFirebird('Servidor Firebird em execução: versão não informada pelo servidor' +
      IfThen(Cabecalho.Valido, ' (ODS ' + IntToStr(Cabecalho.ODS) + ')', EmptyStr) + '.', clYellow);

  if (FVersaoServidor <> EmptyStr) and (Copy(FVersaoServidor, 1, 2) <> '2.') then
    raise Exception.Create('O servidor Firebird que atende este banco é o ' + FVersaoServidor +
      ', e não o 2.5.' + sLineBreak + sLineBreak +
      'A migração só converte bancos que ainda estão no Firebird 2.5. Este banco jã foi ' +
      'migrado (ou nunca esteve no 2.5). Nada foi alterado.');
  if Cabecalho.Valido and (Cabecalho.ODS >= 12) then
    raise Exception.Create('O banco de dados jã estã no formato do Firebird 3 ou superior (ODS ' +
      IntToStr(Cabecalho.ODS) + '): a migração jã foi feita. Nada foi alterado.');
  if (FVersaoServidor = EmptyStr) and (not (Cabecalho.Valido and (Cabecalho.ODS = 11))) then
    raise Exception.Create('Não foi possível confirmar que o servidor é o Firebird 2.5 ' +
      '(versão não informada e o formato do banco não é o do 2.5). Nada foi alterado.');
  if (FVersaoServidor <> EmptyStr) and (not StartsText('2.5.', FVersaoServidor)) then
    raise Exception.Create('O servidor Firebird em execução é o ' + FVersaoServidor +
      '; a migração exige o Firebird 2.5. Nada foi alterado.');

  Gbak25 := TFirebirdAmbiente.Gbak25;
  if (Gbak25 = EmptyStr) or (not FileExists(Gbak25)) then
    raise Exception.Create('As ferramentas do Firebird 2.5 (gbak, gfix, isql) não foram ' +
      'encontradas neste PC. Execute o MigraFacil no servidor onde o Firebird 2.5 estã instalado.');
end;

procedure TFormPrincipal.ValidarColunasNotNullComNulos;
const
  C_MAX_LISTA = 20;

  function Descrever(const Colunas: TColunasNulas; ApenasOrigem: Char): string;
  var
    I, N: Integer;
  begin
    Result := EmptyStr;
    N := 0;
    for I := Low(Colunas) to High(Colunas) do
    begin
      if (ApenasOrigem <> #0) and (Colunas[I].Origem <> ApenasOrigem) then
        Continue;
      Inc(N);
      if N > C_MAX_LISTA then
        Continue;
      Result := Result + sLineBreak + '  ' + Colunas[I].Tabela + '.' + Colunas[I].Coluna + ': ' +
        IntToStr(Colunas[I].Nulos) + ' linha(s)';
    end;
    if N > C_MAX_LISTA then
      Result := Result + sLineBreak + '  ... e mais ' + IntToStr(N - C_MAX_LISTA) + ' coluna(s) (veja o log)';
  end;

  function Contar(const Colunas: TColunasNulas; Origem: Char): Integer;
  var
    I: Integer;
  begin
    Result := 0;
    for I := Low(Colunas) to High(Colunas) do
      if Colunas[I].Origem = Origem then
        Inc(Result);
  end;

var
  Database: string;
  Colunas, Restantes: TColunasNulas;
  SemLeitura: TStringList;
  I, Corrigiveis: Integer;
begin
  // 05/10/2026 (Bimax): TB_VEICULO.TB_UF_ID NOT NULL com 1.266 linhas em NULL derrubou o
  // restore no Firebird 5 ("validation error for column ... *** null ***"). O 2.5 nao
  // valida os dados ao criar a coluna; o gbak do 3+ valida. Conferir ANTES do backup e
  // corrigir tirando o NOT NULL (os dados nao mudam). Desde 09/10/2026 roda com o banco
  // ja em modo exclusivo (shutdown single, depois do reinicio do servico): o isql roda
  // em processos sequenciais, uma conexao SYSDBA por vez.
  LogFirebird('Conferindo colunas NOT NULL com valores nulos (o Firebird 5 recusa essas linhas)...', clAqua);
  Database := NormalizeGbakDatabaseName(TAppConfig.Database);
  SemLeitura := TStringList.Create;
  try
    Colunas := TPreRequisitosConversao.ListarNotNullComNulos(TFirebirdAmbiente.Gbak25,
      Database, SemLeitura);
    for I := 0 to SemLeitura.Count - 1 do
      LogTecnico('Tabela sem contagem de nulos (consulta falhou): ' + SemLeitura[I], clYellow);

    if Length(Colunas) = 0 then
    begin
      LogFirebird('Nenhuma coluna NOT NULL com valores nulos.', clLime);
      Exit;
    end;

    for I := Low(Colunas) to High(Colunas) do
      LogFirebird('Coluna NOT NULL com valores nulos: ' + Colunas[I].Tabela + '.' +
        Colunas[I].Coluna + ' (' + IntToStr(Colunas[I].Nulos) + ' linha(s), origem ' +
        Colunas[I].Origem + ')', clYellow);

    // Correcao sem perguntar (decisao do Valdo, 05/10/2026): sem ela a conversao
    // falharia no restore; nenhum dado muda, so o NOT NULL sai da coluna.
    Corrigiveis := Contar(Colunas, 'C');
    if Corrigiveis > 0 then
    begin
      LogFirebird('Tirando o NOT NULL de ' + IntToStr(Corrigiveis) + ' coluna(s) para a ' +
        'conversao nao falhar no restore (nenhum dado e alterado):' + Descrever(Colunas, 'C'), clYellow);
      TPreRequisitosConversao.TornarOpcionais(TFirebirdAmbiente.Gbak25, Database, Colunas);
      LogFirebird('Colunas tornadas opcionais. Conferindo de novo...', clAqua);
      SemLeitura.Clear;
      Restantes := TPreRequisitosConversao.ListarNotNullComNulos(TFirebirdAmbiente.Gbak25,
        Database, SemLeitura);
    end
    else
      Restantes := Colunas;

    if Length(Restantes) > 0 then
      raise Exception.Create(IntToStr(Length(Restantes)) + ' coluna(s) NOT NULL continuam com ' +
        'valores nulos' + IfThen(Contar(Restantes, 'D') > 0,
          ' (o NOT NULL vem de um dominio nomeado, compartilhado por outras colunas, e nao e ' +
          'alterado automaticamente)', '') + ':' + Descrever(Restantes, #0) + sLineBreak +
        'Preencha os valores nulos ou ajuste a coluna no IBExpert e tente de novo.');

    LogFirebird('Nenhuma coluna NOT NULL com valores nulos restante.', clLime);
  finally
    SemLeitura.Free;
  end;
end;

procedure TFormPrincipal.ValidarConstraintsInvalidas;

  function Descrever(const C: TConstraintInvalida): string;
  begin
    case C.Tipo of
      'F': Result := 'FK ' + C.Nome + ' (' + C.Tabela + '.' + C.Colunas + ' -> ' + C.TabelaRef + '.' +
             C.ColunasRef + '): ' + IntToStr(C.Linhas) + ' linha(s) sem registro pai';
      'P': Result := 'PK ' + C.Nome + ' (' + C.Tabela + '.' + C.Colunas + '): ' + IntToStr(C.Linhas) +
             ' linha(s) com nulo';
    else
      Result := 'UNIQUE ' + C.Nome + ' (' + C.Tabela + '.' + C.Colunas + '): ' + IntToStr(C.Linhas) +
        ' linha(s) com nulo';
    end;
  end;

var
  Database, Ddl, Bloqueadas: string;
  Lista, Restantes: TConstraintsInvalidas;
  SemLeitura: TStringList;
  I, Removiveis: Integer;
begin
  // 05/10/2026 (Bimax): PK INTEG_1345 em TB_GERAL.GRL_CODIGO com 80 nulos e
  // FK_TB_CARTAO_1 com 349 orfas derrubaram o restore no Firebird 5 ("cannot commit
  // index"). O 2.5 nao validava; o 5 valida ao ativar o indice. Decisao do Valdo:
  // remover a constraint sem perguntar (os dados nao mudam). PK/UNIQUE com FK
  // dependente nao e removida: a migracao para e lista.
  LogFirebird('Conferindo chaves estrangeiras sem registro pai e chaves primarias/unicas com nulos...', clAqua);
  Database := NormalizeGbakDatabaseName(TAppConfig.Database);
  SemLeitura := TStringList.Create;
  try
    Lista := TPreRequisitosConversao.ListarConstraintsInvalidas(TFirebirdAmbiente.Gbak25,
      Database, SemLeitura);
    for I := 0 to SemLeitura.Count - 1 do
      LogTecnico('Constraint sem contagem (consulta falhou): ' + SemLeitura[I], clYellow);

    if Length(Lista) = 0 then
    begin
      LogFirebird('Nenhuma chave estrangeira orfa nem chave primaria/unica com nulos.', clLime);
      Exit;
    end;

    Removiveis := 0;
    for I := Low(Lista) to High(Lista) do
    begin
      LogFirebird('Constraint que o banco nao cumpre: ' + Descrever(Lista[I]), clYellow);
      if TPreRequisitosConversao.ConstraintRemovivel(Lista[I]) then
        Inc(Removiveis);
    end;

    if Removiveis > 0 then
    begin
      LogFirebird('Removendo ' + IntToStr(Removiveis) + ' constraint(s) para a conversao nao ' +
        'falhar no restore (nenhum dado e alterado)...', clYellow);
      Ddl := TPreRequisitosConversao.RemoverConstraints(TFirebirdAmbiente.Gbak25, Database, Lista);
      LogTecnico('DDL para recriar as constraints removidas, depois de acertar os dados:' +
        sLineBreak + Ddl, clGray);
      LogFirebird('Constraint(s) removida(s). Conferindo de novo...', clAqua);
      SemLeitura.Clear;
      Restantes := TPreRequisitosConversao.ListarConstraintsInvalidas(TFirebirdAmbiente.Gbak25,
        Database, SemLeitura);
    end
    else
      Restantes := Lista;

    if Length(Restantes) > 0 then
    begin
      Bloqueadas := EmptyStr;
      for I := Low(Restantes) to High(Restantes) do
        Bloqueadas := Bloqueadas + sLineBreak + '  ' + Descrever(Restantes[I]) +
          IfThen(Restantes[I].Dependentes > 0, ' [' + IntToStr(Restantes[I].Dependentes) +
            ' FK(s) dependem desta chave]', '');
      raise Exception.Create(IntToStr(Length(Restantes)) + ' constraint(s) continuam invalidas e ' +
        'nao podem ser removidas automaticamente (chave referenciada por FK):' + Bloqueadas +
        sLineBreak + 'Preencha as colunas nulas ou remova as FKs dependentes no IBExpert e tente de novo.');
    end;

    LogFirebird('Nenhuma constraint invalida restante.', clLime);
  finally
    SemLeitura.Free;
  end;
end;

procedure TFormPrincipal.ValidarTamanhoDosCampos;

  function Descrever(const C: TCampoTamanhoInvalido): string;
  begin
    Result := C.Tabela + '.' + C.Coluna + ' (' + C.NomeTipo + ', dominio ' + C.Dominio +
      '): tamanho ' + IntToStr(C.Tamanho) + ' em vez de ' + IntToStr(C.Correto);
  end;

var
  Database, Lista: string;
  Campos, Restantes: TCamposTamanhoInvalido;
  I: Integer;
begin
  // 28/10/2026 (cliente): o backup parou em TB_BOLETO_ELETRONICO com "message length
  // error (encountered 730, expected 638)". BLE_VL_MULTA era NUMERIC(10,2) com
  // RDB$FIELD_LENGTH 100 no lugar de 8 (tipo trocado direto em RDB$FIELDS): o gbak
  // monta a mensagem pelo tamanho gravado e o servidor pelo tipo. Correcao sem
  // perguntar, como NOT NULL e constraints: o tamanho certo e o do tipo e nenhum dado
  // muda (o servidor ja le esses tipos pelo tamanho fixo).
  LogFirebird('Conferindo campos numericos, de data e blob com tamanho errado nos metadados ' +
    '(o backup falharia)...', clAqua);
  Database := NormalizeGbakDatabaseName(TAppConfig.Database);
  Campos := TPreRequisitosConversao.ListarTamanhosInvalidos(TFirebirdAmbiente.Gbak25, Database);
  if Length(Campos) = 0 then
  begin
    LogFirebird('Nenhum campo com tamanho incompativel com o tipo.', clLime);
    Exit;
  end;

  for I := Low(Campos) to High(Campos) do
    LogFirebird('Campo com tamanho incompativel com o tipo: ' + Descrever(Campos[I]), clYellow);

  LogFirebird('Corrigindo o tamanho de ' + IntToStr(Length(Campos)) + ' campo(s) para o backup ' +
    'nao falhar (nenhum dado e alterado)...', clYellow);
  TPreRequisitosConversao.CorrigirTamanhos(TFirebirdAmbiente.Gbak25, Database, Campos);
  LogFirebird('Tamanhos corrigidos. Conferindo de novo...', clAqua);
  Restantes := TPreRequisitosConversao.ListarTamanhosInvalidos(TFirebirdAmbiente.Gbak25, Database);
  if Length(Restantes) > 0 then
  begin
    Lista := EmptyStr;
    for I := Low(Restantes) to High(Restantes) do
      Lista := Lista + sLineBreak + '  ' + Descrever(Restantes[I]);
    raise Exception.Create(IntToStr(Length(Restantes)) + ' campo(s) continuam com tamanho ' +
      'incompativel com o tipo:' + Lista + sLineBreak +
      'Ajuste o campo no IBExpert e tente de novo.');
  end;

  LogFirebird('Nenhum campo com tamanho incompativel restante.', clLime);
end;

procedure TFormPrincipal.ValidarBancoSemConexoes;
var
  Conexoes: TStringList;
  I: Integer;
begin
  LogFirebird('Verificando conexões ativas no banco de dados...', clAqua);
  Conexoes := TPreRequisitosConversao.ListarConexoes(TFirebirdAmbiente.Gbak25,
    NormalizeGbakDatabaseName(TAppConfig.Database));
  try
    if Conexoes.Count = 0 then
    begin
      LogFirebird('Nenhuma conexão ativa no banco de dados.', clLime);
      Exit;
    end;
    for I := 0 to Conexoes.Count - 1 do
      LogFirebird('Conexão ativa: ' + Conexoes[I], clYellow);
    raise Exception.Create(IntToStr(Conexoes.Count) + ' conexão(ões) ativa(s) no banco de dados ' +
      '(veja o log). Feche o Gestão e os demais programas em TODAS as estações e tente novamente.');
  finally
    Conexoes.Free;
  end;
end;

function TFormPrincipal.ReabrirBancoFirebird25(out Orientacao: string): TResultadoReabertura;
var
  Erro: string;
  Motivo: string;
  Cabecalho: TInfoCabecalhoFdb;
begin
  // Enquanto o Firebird 2.5 existir, devolve o banco fechado pelo backup (gfix -online).
  // Depois da remocao do 2.5 o banco original fica preservado e fechado para o rollback.
  // gfix -online em banco que nao esta em shutdown termina com erro: confere o cabecalho.
  // 09/10/2026: religa o servidor 2.5 antes do gfix (log real: o servico tinha sido
  // parado para remover o 2.5 e o gfix -online via 127.0.0.1 falhou com "Unable to
  // complete network request"), nao reabre com remocao do 2.5 agendada para o boot e
  // devolve o resultado para a mensagem final.
  Cabecalho := TValidacaoConversao.LerCabecalho(LocalDatabaseFileName(TAppConfig.Database));
  if Cabecalho.Valido and (not Cabecalho.EmShutdown) then
  begin
    if Cabecalho.ODS >= 12 then
      // falha depois da troca pelo convertido: nao e mais o banco do 2.5
      Orientacao := 'O banco de dados no caminho oficial já é o convertido (formato do ' +
        'Firebird 5, ODS ' + IntToStr(Cabecalho.ODS) + ') e não está fechado. Confira o log ' +
        'antes de liberar o Gestão nas estações.'
    else
      Orientacao := 'O banco de dados está aberto e o Gestão continua funcionando no Firebird 2.5.';
    Result := rbAberto;
    Exit;
  end;

  if not TFirebirdInstalacoes.ExisteFamilia25 then
  begin
    LogFirebird('O banco original (Firebird 2.5) continua fechado (shutdown) e preservado, ' +
      'no caminho original ou em ' + BackupDirectory + '. Para voltar ao Firebird 2.5, ' +
      'use a opção de remover o Firebird 5 e reinstalar o 2.5: o banco original é ' +
      'reaberto automaticamente.', clYellow);
    Orientacao := 'O banco de dados ficou FECHADO de propósito: o Firebird 2.5 já foi removido ' +
      'deste servidor e o banco original fica preservado (no caminho original ou em ' +
      BackupDirectory + '). O Gestão não conecta até a migração terminar ou até voltar ao 2.5.' +
      sLineBreak + sLineBreak +
      'Próximo passo: execute o MigraFacil de novo para retomar a migração de onde parou; ' +
      'ou use a opção "Remover Firebird 5 e reinstalar Firebird 2.5", que reabre o banco original.';
    Result := rbPreservadoFechado;
    Exit;
  end;

  // Arquivo do 2.5 preso virou remocao agendada para o boot: reabrir agora deixaria o
  // Gestao em uso com um servidor que some no proximo reinicio do Windows.
  if RemocaoFirebird25AgendadaNoBoot then
  begin
    LogFirebird('O Windows agendou a remoção de arquivos do Firebird 2.5 para a próxima ' +
      'reinicialização: o banco original continua fechado (shutdown) e preservado.', clYellow);
    Orientacao := 'O banco de dados ficou FECHADO de propósito: o Windows agendou a remoção de ' +
      'arquivos do Firebird 2.5 para a próxima reinicialização, e reabrir o banco agora deixaria ' +
      'o Gestão sem servidor depois do reinício. O Gestão não conecta até lá.' +
      sLineBreak + sLineBreak +
      'Próximo passo: reinicie o Windows do servidor e execute o MigraFacil de novo ' +
      '(a migração é retomada de onde parou).';
    Result := rbPreservadoFechado;
    Exit;
  end;

  if not GarantirServidorFirebird25Rodando(Motivo) then
  begin
    LogFirebird('O servidor Firebird 2.5 está incompleto ou parado (' + Motivo + '): o banco ' +
      'de dados continua FECHADO e o Gestão NÃO conecta.', clRed);
    Orientacao := 'Servidor Firebird 2.5: ' + Motivo + '.';
    Result := rbFalhou;
    Exit;
  end;

  if TPreRequisitosConversao.TentarOnline(TFirebirdAmbiente.Gbak25,
       NormalizeGbakDatabaseName(TAppConfig.Database), Erro) then
  begin
    LogFirebird('Banco de dados reaberto para uso (Firebird 2.5).', clLime);
    Orientacao := SMsgBancoReaberto25;
    Result := rbAberto;
  end
  else
  begin
    LogFirebird('Atenção: ' + Erro, clRed);
    Orientacao := Erro;
    Result := rbFalhou;
  end;
end;

procedure TFormPrincipal.InformarInterrupcao(const MensagemEtapa: string);
var
  Orientacao: string;
begin
  // 09/10/2026 (item d): a mensagem final diz em que estado o banco ficou
  case ReabrirBancoFirebird25(Orientacao) of
    rbAberto:
      begin
        LogFirebird(Orientacao, clLime);
        TMensagens.Aviso(MensagemEtapa + sLineBreak + sLineBreak + Orientacao);
      end;
    rbPreservadoFechado:
      begin
        LogFirebird('O banco de dados ficou fechado de propósito (veja a orientação na mensagem).',
          clYellow);
        TMensagens.Aviso(MensagemEtapa + sLineBreak + sLineBreak + Orientacao);
      end;
  else
    LogFirebird('O banco de dados CONTINUA FECHADO: o Gestão NÃO conecta em nenhuma estação. ' +
      'Reinicie o Windows do servidor e execute o MigraFacil de novo, ou use a opção ' +
      '"Remover Firebird 5 e reinstalar Firebird 2.5".', clRed);
    TMensagens.Erro(MensagemEtapa + sLineBreak + sLineBreak + SMsgBancoContinuaFechado +
      IfThen(Orientacao <> EmptyStr, sLineBreak + sLineBreak + 'Detalhe: ' + Orientacao, ''));
  end;
end;

function TFormPrincipal.FerramentaFirebird5(const Nome: string): string;
begin
  // Sempre a ferramenta da instalacao do servidor 5.0, nunca uma copia antiga
  // ao lado do migrador.
  Result := EmptyStr;
  if TFirebirdAmbiente.Executavel5 <> EmptyStr then
    Result := IncludeTrailingPathDelimiter(
      ExtractFilePath(TFirebirdAmbiente.Executavel5)) + Nome;
  if (Result = EmptyStr) or (not FileExists(Result)) then
    raise Exception.Create(Nome + ' do Firebird 5 não encontrado na instalação do servidor: ' +
      TFirebirdAmbiente.Executavel5);
end;

function TFormPrincipal.AplicarTuningFirebird5: Boolean;
var
  Diagnostico: TDiagnosticoTuning;
  PastaBackupConf: string;
  Erro: string;
begin
  // O1-5: mesma otimizacao que o GestaoUpdate aplica ao instalar o servidor
  // (arquitetura, cache e DummyPacketInterval = 60). Servidor ainda sem o banco
  // do cliente. Falha aqui so e avisada: nao impede a conversao. Result = False
  // quando a otimizacao era devida e nao foi aplicada (o resumo final avisa).
  Result := True;
  if TFirebirdAmbiente.Executavel5 = EmptyStr then
    Exit;
  Diagnostico := TFirebirdTuning.Diagnosticar('5.0',
    ExtractFilePath(TFirebirdAmbiente.Executavel5), EmptyStr);
  if Diagnostico.Erro <> EmptyStr then
  begin
    LogFirebird('Otimização do Firebird 5 não aplicada: ' + Diagnostico.Erro, clYellow);
    Result := False;
    Exit;
  end;
  LogTecnico(TFirebirdTuning.DescreverDiagnostico(Diagnostico), clGray);
  if TFirebirdTuning.Executar(Diagnostico, EmptyStr, EmptyStr, EmptyStr, 'SYSDBA', 'masterkey',
       False, LogFirebird, LogTecnico, AtualizarStatus, PastaBackupConf, Erro) in [rtOk, rtNadaAFazer] then
    LogFirebird('Servidor Firebird 5 otimizado.', clLime)
  else
  begin
    Result := False;
    LogFirebird('Otimização do Firebird 5 não concluída: ' + Erro, clYellow);
  end;
end;

procedure TFormPrincipal.AvisarConclusao(const TextoSucesso: string);
begin
  // Sucesso pleno ou, se a otimizacao do Firebird 5 ficou pendente, aviso.
  if FOtimizacaoFb5Pendente then
    TMensagens.Aviso(TextoSucesso + sLineBreak + sLineBreak +
      'Atenção: a otimização do servidor Firebird 5 não foi aplicada (veja o aviso no log). ' +
      'O sistema funciona com a configuração padrão do instalador. Para aplicar, ' +
      'execute o MigraFacil como administrador ou use a otimização do GestaoUpdate.')
  else
    TMensagens.Sucesso(TextoSucesso);
end;
procedure TFormPrincipal.RetomarBancoOriginal25;
var
  BancoLocal: string;
  Copia: string;
  Convertido: string;
  Erro: string;
  Motivo: string;
  Cabecalho: TInfoCabecalhoFdb;
begin
  // O1-3: depois de reinstalar o Firebird 2.5, devolve o banco original.
  BancoLocal := LocalDatabaseFileName(TAppConfig.Database);
  Cabecalho := TValidacaoConversao.LerCabecalho(BancoLocal);
  if not Cabecalho.Valido then
  begin
    LogFirebird('Banco de dados não encontrado ou ilegível em ' + BancoLocal +
      '. Confira o Config.ini e a pasta ' + BackupDirectory + '.', clYellow);
    Exit;
  end;

  if Cabecalho.ODS >= 12 then
  begin
    // O caminho oficial ja tem o banco convertido: volta a copia do original
    Copia := TValidacaoConversao.LerManifesto(BackupDirectory, 'CopiaOriginal');
    if (Copia = EmptyStr) or (not FileExists(Copia)) then
    begin
      LogFirebird('O banco em ' + BancoLocal + ' já é do Firebird 5 e a cópia do original ' +
        'não consta no manifesto da conversão. Restaure o original manualmente a partir de ' +
        BackupDirectory + '.', clRed);
      Exit;
    end;
    if not TMensagens.ConfirmarContinuacaoAtencao(
      'O banco em uso já foi convertido para o Firebird 5. Voltar a cópia do banco ' +
      'original (Firebird 2.5)?' + sLineBreak + sLineBreak +
      'O que foi gravado depois da conversão será perdido. O banco convertido fica ' +
      'guardado em ' + BackupDirectory + '.') then
      Exit;
    Convertido := IncludeTrailingPathDelimiter(BackupDirectory) +
      ChangeFileExt(ExtractFileName(BancoLocal), EmptyStr) + '_FB5_REVERTIDO_' +
      FormatDateTime('yyyymmdd_hhnnss', Now) + ExtractFileExt(BancoLocal);
    if not MoveFileEx(PChar(BancoLocal), PChar(Convertido),
      MOVEFILE_COPY_ALLOWED or MOVEFILE_WRITE_THROUGH) then
      raise Exception.Create('Não foi possível guardar o banco convertido em ' + Convertido +
        ': ' + SysErrorMessage(GetLastError));
    if not CopyFile(PChar(Copia), PChar(BancoLocal), True) then
      raise Exception.Create('Não foi possível restaurar a cópia do banco original em ' +
        BancoLocal + ': ' + SysErrorMessage(GetLastError) + '. O banco convertido está em ' +
        Convertido + '.');
    LogFirebird('Cópia do banco original restaurada em ' + BancoLocal +
      '. Banco convertido guardado em ' + Convertido + '.', clLime);
    TValidacaoConversao.GravarMarcadorRetorno25(
      IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + CONFIG_INI);
    TValidacaoConversao.GravarManifesto(BackupDirectory, 'Etapa', 'revertida');
    Cabecalho := TValidacaoConversao.LerCabecalho(BancoLocal);
  end;

  if Cabecalho.Valido and Cabecalho.EmShutdown then
  begin
    // 09/10/2026: o gfix -online precisa do servidor 2.5 rodando
    if not GarantirServidorFirebird25Rodando(Motivo) then
    begin
      LogFirebird('Atenção: o servidor Firebird 2.5 não está pronto (' + Motivo + '). O banco ' +
        'original continua FECHADO e o Gestão NÃO conecta até o servidor 2.5 funcionar.', clRed);
      Exit;
    end;
    if TPreRequisitosConversao.TentarOnline(TFirebirdAmbiente.Gbak25,
         NormalizeGbakDatabaseName(TAppConfig.Database), Erro) then
    begin
      LogFirebird('Banco original reaberto para uso no Firebird 2.5.', clLime);
      TValidacaoConversao.GravarManifesto(BackupDirectory, 'Etapa', 'revertida');
    end
    else
      LogFirebird('Atenção: ' + Erro, clRed);
  end;
end;

procedure TFormPrincipal.btnTestarConexaoClick(Sender: TObject);
begin
  if FProcessoEmAndamento then
  begin
    TMensagens.Aviso(SMsgProcessoEmAndamento);
    Exit;
  end;

  try
    TestarConexaoBanco(True);
  except
    on E: Exception do
      TMensagens.Erro('Não foi possível conectar ao banco de dados.' +
        sLineBreak + sLineBreak + E.Message);
  end;
end;

procedure TFormPrincipal.btn_DetectarVersaoFBClick(Sender: TObject);
var
  Fb25Exe: string;
  Fb5Exe: string;
  Fb25Version: string;
  Fb5Version: string;
  Fb25Uninstaller: string;
  Fb5Uninstaller: string;
  Resumo: string;
begin
  if FProcessoEmAndamento then
  begin
    TMensagens.Aviso(SMsgProcessoEmAndamento);
    Exit;
  end;

  Fb25Exe := TFirebirdAmbiente.Executavel25;
  Fb5Exe := TFirebirdAmbiente.Executavel5;
  Fb25Version := TFirebirdAmbiente.VersaoArquivo(Fb25Exe);
  Fb5Version := TFirebirdAmbiente.VersaoArquivo(Fb5Exe);
  Fb25Uninstaller := TFirebirdAmbiente.Desinstalador25;
  Fb5Uninstaller := TFirebirdAmbiente.Desinstalador5;

  Resumo := 'Detecção do Firebird no Windows' + sLineBreak + sLineBreak +
    'Windows: ' + TFirebirdAmbiente.ArquiteturaWindows + sLineBreak;

  if Fb25Exe <> EmptyStr then
  begin
    Resumo := Resumo + sLineBreak + 'Firebird 2.5: encontrado';
    if Fb25Version <> EmptyStr then
      Resumo := Resumo + ' - versão ' + Fb25Version;
    Resumo := Resumo + sLineBreak + Fb25Exe + sLineBreak;
  end
  else
  begin
    Resumo := Resumo + sLineBreak + 'Firebird 2.5: não encontrado' + sLineBreak;
  end;

  if Fb5Exe <> EmptyStr then
  begin
    Resumo := Resumo + sLineBreak + 'Firebird 5: encontrado';
    if Fb5Version <> EmptyStr then
      Resumo := Resumo + ' - versão ' + Fb5Version;
    Resumo := Resumo + sLineBreak + Fb5Exe + sLineBreak;
  end
  else
  begin
    Resumo := Resumo + sLineBreak + 'Firebird 5: não encontrado' + sLineBreak;
  end;

  if TFirebirdServicos.Existe('FirebirdServerDefaultInstance') then
    Resumo := Resumo + sLineBreak + 'Serviço: FirebirdServerDefaultInstance encontrado'
  else
    Resumo := Resumo + sLineBreak + 'Serviço: FirebirdServerDefaultInstance não encontrado';

  TMensagens.Informacao(Resumo);
end;

procedure TFormPrincipal.btnLimparLogsClick(Sender: TObject);
begin
  reLog.Lines.Clear;
  reLogTecnico.Lines.Clear;
end;

procedure TFormPrincipal.btnIniciarMigracaoClick(Sender: TObject);
var
  EtapaRetomada: string;
  ReabrirParaNova: Boolean;
  QtdeConexoes: Integer;
  Cabecalho: TInfoCabecalhoFdb;
begin
  if FProcessoEmAndamento then
  begin
    TMensagens.Aviso(SMsgProcessoEmAndamento);
    Exit;
  end;

  FProcessoEmAndamento := True;
  FBancoEmModoExclusivo := False;
  try
    IniciarLogProcesso;

    if not TSegurancaFirebird5.Administrador then
    begin
      LogFirebird('Migração não iniciada: é necessário executar o MigraFacil como administrador.', clRed);
      TMensagens.Erro('Abra o MigraFacil como administrador e inicie ou retome a migração.' +
        sLineBreak + 'Nenhuma etapa da migração foi executada.');
      Exit;
    end;

    // O3-1: conversao interrompida (manifesto) retoma da proxima etapa, com o
    // backup e o retrato ja feitos; o banco original continua fechado. Nunca reabrir
    // aqui sem o operador pedir (o que fosse gravado depois do .fbk se perderia).
    ReabrirParaNova := False;
    EtapaRetomada := DetectarConversaoInterrompida;
    if EtapaRetomada <> EmptyStr then
    begin
      if TMensagens.ConfirmarContinuacaoAtencao(
        'Há uma conversão interrompida neste servidor (etapa concluída: ' + EtapaRetomada +
        ', backup ' + TValidacaoConversao.LerManifesto(BackupDirectory, 'Fbk') + ').' +
        sLineBreak + sLineBreak +
        'Retomar a partir da próxima etapa, usando o backup e o retrato já feitos? ' +
        'O banco original continua fechado e preservado.') then
        LogFirebird('Retomando a conversão interrompida (etapa concluída: ' + EtapaRetomada + ').', clAqua)
      else
      begin
        // 09/10/2026 (item e.2): recusou a retomada - oferece uma migracao nova
        if not TMensagens.ConfirmarAtencao(
          'Começar uma migração NOVA?' + sLineBreak + sLineBreak +
          'O banco original será reaberto e um backup novo será feito; o backup da tentativa ' +
          'interrompida fica guardado em ' + BackupDirectory + '.') then
        begin
          StatusBarProcesso.SimpleText := 'Retomada recusada.';
          LogFirebird('Retomada recusada. O banco original continua fechado; para voltar ao ' +
            'Firebird 2.5 use a opção de remover o Firebird 5 e reinstalar o 2.5.', clYellow);
          Exit;
        end;
        LogFirebird('Retomada recusada: o operador escolheu começar uma migração nova.', clYellow);
        EtapaRetomada := EmptyStr;
        ReabrirParaNova := True;
      end;
    end
    else
    begin
      // 09/10/2026 (item e.3): banco ja fechado (sobra de tentativa antiga, gfix manual)
      // sem conversao interrompida valida. ODS >= 12: a validacao barra mais adiante.
      Cabecalho := TValidacaoConversao.LerCabecalho(LocalDatabaseFileName(TAppConfig.Database));
      if Cabecalho.Valido and Cabecalho.EmShutdown and (Cabecalho.ODS < 12) then
      begin
        LogFirebird('O banco de dados está fechado (shutdown).', clYellow);
        if not TMensagens.ConfirmarAtencao(
          'O banco de dados está fechado (shutdown), provavelmente por uma tentativa anterior ' +
          'de migração.' + sLineBreak + sLineBreak +
          'Reabrir o banco e começar uma migração nova, com backup novo?') then
        begin
          StatusBarProcesso.SimpleText := 'Migração não iniciada.';
          LogFirebird('Migração não iniciada: o banco de dados continua fechado (shutdown).', clYellow);
          Exit;
        end;
        ReabrirParaNova := True;
      end;
    end;

    if EtapaRetomada = EmptyStr then
    begin
      StatusBarProcesso.SimpleText := 'Verificando banco de dados...';

      // 09/10/2026 (item e.4): reabertura pedida pelo operador, so com o 2.5 confirmado
      if ReabrirParaNova then
      try
        ReabrirBancoParaMigracaoNova;
      except
        on E: Exception do
        begin
          StatusBarProcesso.SimpleText := 'Falha ao reabrir o banco de dados.';
          LogFirebird('Migração não iniciada: o banco de dados continua fechado (shutdown). ' +
            E.Message, clRed);
          TMensagens.Erro('A migração não foi iniciada e o banco de dados continua fechado ' +
            '(shutdown): o Gestão não conecta.' + sLineBreak + sLineBreak + E.Message);
          Exit;
        end;
      end;

      LogFirebird('Verificando pré-requisitos da migração...', clAqua);

      // 09/10/2026 (pedido do Valdo): reiniciar o Firebird 2.5 antes de qualquer
      // alteracao (ninguem fica conectado) e ja colocar o banco em modo exclusivo.
      // 1) checagens SOMENTE LEITURA: nada muda no banco nem no servico
      try
        ValidarPreRequisitosSomenteLeitura;
      except
        on E: Exception do
        begin
          StatusBarProcesso.SimpleText := 'Falha na verificação do banco de dados.';
          LogFirebird('Migração não iniciada: ' + E.Message, clRed);
          TMensagens.Erro('A migração não foi iniciada.' + sLineBreak + sLineBreak +
            E.Message);
          Exit;
        end;
      end;

      // 2) informativo: quem cai no reinicio
      QtdeConexoes := ListarConexoesQueSeraoDerrubadas;

      // 3) confirmacao ANTES do reinicio (cancelar aqui nao muda nada)
      if not TMensagens.ConfirmarInicio(
        'A migração vai REINICIAR o serviço do Firebird 2.5 deste servidor: TODAS as estações ' +
        'conectadas serão desconectadas, e o que não tiver sido gravado nelas será perdido.' +
        IfThen(QtdeConexoes > 0, sLineBreak + 'Conexões ativas encontradas agora: ' +
          IntToStr(QtdeConexoes) + ' (veja o log).', '') + sLineBreak + sLineBreak +
        'Depois do reinício, a migração fechará o banco de dados para uso até o fim (nenhuma ' +
        'estação poderá entrar), fará o backup de segurança, atualizará o Firebird e converterá ' +
        'o banco de dados.' + sLineBreak + sLineBreak +
        IfThen(FClienteLinha2026,
          'Confirme que o Gestão está fechado em TODAS as estações.',
          'ATENçÃO: este cliente ainda está na linha 2016. Depois da conversão o Gestão 2016 ' +
          'NÃO conecta no Firebird 5: o sistema só volta a funcionar depois de rodar o GestaoUpdate ' +
          'e liberar a linha 2026 no servidor e em TODAS as estações.' + sLineBreak + sLineBreak +
          'Confirme que o Gestão está fechado em TODAS as estações.')) then
      begin
        StatusBarProcesso.SimpleText := 'Migração cancelada pelo usuário.';
        LogFirebird('Migração cancelada pelo usuário.', clYellow);
        Exit;
      end;

      LogFirebird('Migração assistida iniciada.', clAqua);

      // 4) reinicio do servico: derruba todas as conexoes
      try
        ReiniciarServicoFirebird25;
      except
        on E: Exception do
        begin
          StatusBarProcesso.SimpleText := 'Falha ao reiniciar o Firebird 2.5.';
          LogFirebird('Migração não iniciada: ' + E.Message, clRed);
          TMensagens.Erro('A migração não foi iniciada.' + sLineBreak + sLineBreak +
            E.Message);
          Exit;
        end;
      end;

      // 5) modo exclusivo e 6) conferencias que alteram metadados, ja sem ninguem
      try
        ColocarBancoEmModoExclusivo;
        ValidarPreRequisitosEmModoExclusivo;
      except
        on E: Exception do
        begin
          StatusBarProcesso.SimpleText := 'Falha na verificação do banco de dados.';
          LogFirebird('Migração não iniciada: ' + E.Message, clRed);
          InformarInterrupcao('A migração não foi iniciada.' + sLineBreak + sLineBreak +
            E.Message);
          Exit;
        end;
      end;

      ExecutarEtapaBackup;
      if not FUltimaEtapaExecutadaComSucesso then
      begin
        InformarInterrupcao(SMsgMigracaoInterrompidaBackup);
        Exit;
      end;
      TValidacaoConversao.GravarManifesto(BackupDirectory, 'Etapa', 'backup');
    end;

    if EtapaRetomada <> 'firebird5' then
    begin
      ExecutarEtapaAtualizacaoFirebird;
      if not FUltimaEtapaExecutadaComSucesso then
      begin
        InformarInterrupcao(SMsgMigracaoInterrompidaAtualizacao);
        Exit;
      end;
      TValidacaoConversao.GravarManifesto(BackupDirectory, 'Etapa', 'firebird5');
    end;

    ExecutarEtapaRestoreFirebird5;
    if not FUltimaEtapaExecutadaComSucesso then
    begin
      InformarInterrupcao(SMsgMigracaoInterrompidaConversao);
      Exit;
    end;

    TValidacaoConversao.GravarManifesto(BackupDirectory, 'Etapa', 'concluida');
    if FOtimizacaoFb5Pendente then
    begin
      LogFirebird('Migração assistida concluída com ressalvas: a otimização do ' +
        'servidor Firebird 5 não foi aplicada.', clYellow);
      StatusBarProcesso.SimpleText := 'Migração concluída com ressalvas.';
    end
    else
    begin
      LogFirebird('Migração assistida concluída com sucesso.', clLime);
      StatusBarProcesso.SimpleText := 'Migração concluída com sucesso.';
    end;
    AvisarConclusao(SMsgMigracaoConcluida);
  finally
    if FLogProcessoFileName <> EmptyStr then
      LogFirebird('Log do processo gravado em: ' + FLogProcessoFileName +
        IfThen(FLogTecnicoFileName <> EmptyStr,
          ' (log técnico: ' + FLogTecnicoFileName + ')', ''), clAqua)
    else if FLogTecnicoFileName <> EmptyStr then
      LogFirebird('Log técnico do processo gravado em: ' + FLogTecnicoFileName, clAqua);
    FLogProcessoFileName := EmptyStr;
    FLogTecnicoFileName := EmptyStr;
    FBancoEmModoExclusivo := False;
    AtualizarEstadoBanco;
    FProcessoEmAndamento := False;
  end;
end;

procedure TFormPrincipal.btnBackupClick(Sender: TObject);
var
  Orientacao: string;
  Resultado: TResultadoReabertura;
  Mensagem: string;
begin
  if FProcessoEmAndamento then
  begin
    TMensagens.Aviso(SMsgProcessoEmAndamento);
    Exit;
  end;

  FProcessoEmAndamento := True;
  try
    ExecutarEtapaBackup;
    // backup avulso: o banco volta a ficar disponivel (o shutdown e so da migracao)
    Resultado := ReabrirBancoFirebird25(Orientacao);
    if FUltimaEtapaExecutadaComSucesso then
      Mensagem := SMsgBackupConcluido
    else
      Mensagem := 'O backup não foi concluído. Consulte o log.';
    // 09/10/2026: a mensagem diz em que estado o banco ficou
    case Resultado of
      rbAberto:
        if FUltimaEtapaExecutadaComSucesso then
          TMensagens.Sucesso(Mensagem)
        else
          TMensagens.Aviso(Mensagem + sLineBreak + sLineBreak + Orientacao);
      rbPreservadoFechado:
        TMensagens.Aviso(Mensagem + sLineBreak + sLineBreak + Orientacao);
    else
      TMensagens.Erro(Mensagem + sLineBreak + sLineBreak + SMsgBancoContinuaFechado +
        IfThen(Orientacao <> EmptyStr, sLineBreak + sLineBreak + 'Detalhe: ' + Orientacao, ''));
    end;
  finally
    FProcessoEmAndamento := False;
  end;
end;

procedure TFormPrincipal.btnAtualizarFB2_5_E_Instalar_5Click(Sender: TObject);
begin
  if FProcessoEmAndamento then
  begin
    TMensagens.Aviso(SMsgProcessoEmAndamento);
    Exit;
  end;

  if LatestBackupFileName = EmptyStr then
  begin
    TMensagens.Aviso(SMsgBackupObrigatorio);
    Exit;
  end;

  if not TMensagens.ConfirmarContinuacao(
    'Esta etapa removerá o Firebird 2.5 e instalará o Firebird 5.') then
    Exit;

  FProcessoEmAndamento := True;
  try
    ExecutarEtapaAtualizacaoFirebird;
    if FUltimaEtapaExecutadaComSucesso then
      AvisarConclusao(SMsgFirebirdAtualizado);
  finally
    FProcessoEmAndamento := False;
  end;
end;

procedure TFormPrincipal.btnRestaurarFbkFB5Click(Sender: TObject);
var
  DialogoBackup: TOpenDialog;
  DialogoDestino: TSaveDialog;
  ArquivoBackup: string;
  ArquivoDestino: string;
  BancoConfigurado: string;
  Gbak: string;
  VersaoGbak: string;
  GbakLog: string;
  Params: string;
  Inicio: UInt64;
  CursorAnterior: TCursor;
  RestauracaoIniciada: Boolean;
  RestauracaoConcluida: Boolean;
begin
  if FProcessoEmAndamento then
  begin
    TMensagens.Aviso(SMsgProcessoEmAndamento);
    Exit;
  end;

  DialogoBackup := nil;
  DialogoDestino := nil;
  ArquivoDestino := EmptyStr;
  RestauracaoIniciada := False;
  RestauracaoConcluida := False;
  CursorAnterior := Screen.Cursor;
  FProcessoEmAndamento := True;
  try
    try
      if not TFirebirdAmbiente.Firebird5Instalado then
        raise Exception.Create('Firebird 5 não encontrado. Instale-o antes de restaurar o backup.');

      Gbak := IncludeTrailingPathDelimiter(
        ExtractFilePath(TFirebirdAmbiente.Executavel5)) + 'gbak.exe';
      if not FileExists(Gbak) then
        Gbak := IncludeTrailingPathDelimiter(
          ExtractFilePath(TFirebirdAmbiente.Executavel5)) + 'bin\gbak.exe';
      if not FileExists(Gbak) then
        Gbak := TFirebirdAmbiente.Gbak5;
      if (Gbak = EmptyStr) or (not FileExists(Gbak)) then
        raise Exception.Create('gbak.exe do Firebird 5 não encontrado.');

      VersaoGbak := TFirebirdAmbiente.VersaoArquivo(Gbak);
      if Copy(VersaoGbak, 1, 2) <> '5.' then
        raise Exception.Create('O gbak selecionado não foi identificado como Firebird 5: ' +
          Gbak + '. Versão detectada: ' + VersaoGbak);

      DialogoBackup := TOpenDialog.Create(Self);
      DialogoBackup.Title := 'Selecionar backup do Firebird 2.5';
      DialogoBackup.Filter := 'Backup Firebird (*.fbk)|*.fbk';
      DialogoBackup.DefaultExt := 'fbk';
      DialogoBackup.Options := [ofFileMustExist, ofPathMustExist,
        ofNoChangeDir, ofEnableSizing];
      if not DialogoBackup.Execute then
        Exit;

      ArquivoBackup := ExpandFileName(DialogoBackup.FileName);
      if (not SameText(ExtractFileExt(ArquivoBackup), '.fbk')) or
         (not FileExists(ArquivoBackup)) then
        raise Exception.Create('Selecione um arquivo de backup .fbk existente.');

      DialogoDestino := TSaveDialog.Create(Self);
      DialogoDestino.Title := 'Salvar novo banco restaurado no Firebird 5';
      DialogoDestino.Filter := 'Banco Firebird (*.fdb)|*.fdb';
      DialogoDestino.DefaultExt := 'fdb';
      DialogoDestino.InitialDir := ExtractFilePath(ArquivoBackup);
      DialogoDestino.FileName := ChangeFileExt(
        ExtractFileName(ArquivoBackup), EmptyStr) + '_5_restaurado.fdb';
      DialogoDestino.Options := [ofPathMustExist, ofNoChangeDir,
        ofEnableSizing];
      if not DialogoDestino.Execute then
        Exit;

      ArquivoDestino := ExpandFileName(DialogoDestino.FileName);
      if not SameText(ExtractFileExt(ArquivoDestino), '.fdb') then
        raise Exception.Create('O novo banco deve ter a extensão .fdb.');
      if Copy(ArquivoDestino, 1, 2) = '\\' then
        raise Exception.Create('Escolha uma pasta local para salvar o novo banco.');
      if not DirectoryExists(ExtractFilePath(ArquivoDestino)) then
        raise Exception.Create('A pasta de destino não existe.');

      BancoConfigurado := LocalDatabaseFileName(TAppConfig.Database);
      if BancoConfigurado <> EmptyStr then
        if SameText(ArquivoDestino, ExpandFileName(BancoConfigurado)) then
          raise Exception.Create('Escolha outro destino. O banco configurado no sistema deve ser preservado.');

      if FileExists(ArquivoDestino) or DirectoryExists(ArquivoDestino) then
        raise Exception.Create('O destino já existe. Escolha outro nome para o banco: ' +
          ArquivoDestino);

      if not TMensagens.ConfirmarContinuacao(
        'Restaurar este backup no Firebird 5?' + sLineBreak +
        'Backup: ' + ArquivoBackup + sLineBreak +
        'Novo banco: ' + ArquivoDestino) then
        Exit;

      Screen.Cursor := crHourGlass;
      Inicio := GetTickCount64;
      GbakLog := IncludeTrailingPathDelimiter(ExtractFilePath(ArquivoDestino)) +
        'restore_manual_gbak_' + FormatDateTime('yyyymmdd_hhnnss_zzz', Now) +
        '_' + TGUID.NewGuid.ToString + '.log';

      LogFirebird('Restauração de backup no Firebird 5 iniciada...', clAqua);
      LogFirebird('Backup selecionado: ' + ArquivoBackup, clWhite);
      LogFirebird('Novo banco: ' + ArquivoDestino, clWhite);
      LogFirebird('Log técnico da restauração: ' + GbakLog, clGray);
      LogTecnico('GBAK Firebird 5: ' + Gbak, clGray);

      // -c cria um banco novo; -y grava a saída sem usar cmd.exe.
      // Parametros padrao (uGbakPadrao), com o log do gbak em arquivo proprio
      Params := Fc_ParametrosRestoreGbak('sysdba', 'masterkey', ArquivoBackup,
        '127.0.0.1:' + ArquivoDestino, '', '-y ' + QuoteParam(GbakLog));
      RestauracaoIniciada := True;
      if not RunAndWait(Gbak, Params) then
      begin
        LogTextFile(GbakLog, 'Saída do gbak restore manual', clRed);
        raise Exception.Create('Falha ao restaurar o backup no Firebird 5. ' +
          TProcessoWindows.UltimoErro + ' Consulte o log técnico.');
      end;

      LogTextFile(GbakLog, 'Saída do gbak restore manual', clGray);
      if not FileExists(ArquivoDestino) then
        raise Exception.Create('O gbak terminou, mas o novo banco não foi encontrado: ' +
          ArquivoDestino);

      RestauracaoConcluida := True;
      LogFirebird('Banco restaurado em: ' + ArquivoDestino, clLime);
      LogFirebird('Restauração concluída em ' +
        FormatDuration(GetTickCount64 - Inicio) + '.', clLime);
      TMensagens.Sucesso('Banco restaurado no Firebird 5:' + sLineBreak +
        ArquivoDestino);
    except
      on E: Exception do
      begin
        LogFirebird('Erro na restauração do backup: ' + E.Message, clRed);
        if RestauracaoIniciada and (not RestauracaoConcluida) and
           FileExists(ArquivoDestino) then
          LogFirebird('O arquivo de destino pode estar incompleto: ' +
            ArquivoDestino + '. Escolha outro nome ao tentar novamente.', clYellow);
        AtualizarStatus('Falha na restauração do backup.');
        TMensagens.Excecao('Não foi possível restaurar o backup no Firebird 5.', E);
      end;
    end;
  finally
    DialogoDestino.Free;
    DialogoBackup.Free;
    Screen.Cursor := CursorAnterior;
    FProcessoEmAndamento := False;
  end;
end;

procedure TFormPrincipal.btnRestoreClick(Sender: TObject);
begin
  if FProcessoEmAndamento then
  begin
    TMensagens.Aviso(SMsgProcessoEmAndamento);
    Exit;
  end;

  if not TMensagens.ConfirmarContinuacaoAtencao(
    'Esta etapa converterá o backup e substituirá o banco de dados original.') then
    Exit;

  FProcessoEmAndamento := True;
  try
    ExecutarEtapaRestoreFirebird5;
    if FUltimaEtapaExecutadaComSucesso then
      TMensagens.Sucesso(SMsgRestoreConcluido);
  finally
    FProcessoEmAndamento := False;
  end;
end;

procedure TFormPrincipal.ExecutarEtapaBackup;
var
  StartTick: UInt64;
begin
  StartTick := GetTickCount64;
  FUltimaEtapaExecutadaComSucesso := False;

  Screen.Cursor := crHourGlass;
  StatusBarProcesso.SimpleText := 'Backup em andamento...';

  try
    try
      LogFirebird('Backup de segurança iniciado...', clAqua);

      ExecutarBackupFirebird25;

      LogFirebird('Backup concluído com sucesso em ' +
        FormatDuration(GetTickCount64 - StartTick) + '.', clLime);
      StatusBarProcesso.SimpleText := 'Backup finalizado em ' + FormatDuration(GetTickCount64 - StartTick) + '.';
      FUltimaEtapaExecutadaComSucesso := True;
    except
      on E: Exception do
      begin
        StatusBarProcesso.SimpleText := 'Erro no backup.';
        LogFirebird('Erro ao executar backup: ' + E.Message, clRed);
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormPrincipal.ExecutarEtapaAtualizacaoFirebird;
var
  StartTick: UInt64;
begin
  StartTick := GetTickCount64;
  FUltimaEtapaExecutadaComSucesso := False;

  Screen.Cursor := crHourGlass;
  StatusBarProcesso.SimpleText := 'Atualização do Firebird em andamento...';

  try
    try
      LogFirebird('Atualização para Firebird 5 iniciada...', clAqua);
      AtualizarFirebird2_5;
      FOtimizacaoFb5Pendente := not AplicarTuningFirebird5;

      if FOtimizacaoFb5Pendente then
      begin
        LogFirebird('Atualização do Firebird concluída com ressalvas em ' +
          FormatDuration(GetTickCount64 - StartTick) + ': o Firebird 5 foi instalado, ' +
          'mas a otimização do servidor NÃO foi aplicada (veja o aviso acima).', clYellow);
        StatusBarProcesso.SimpleText := 'Firebird atualizado com ressalvas em ' +
          FormatDuration(GetTickCount64 - StartTick) + '.';
      end
      else
      begin
        LogFirebird('Atualização do Firebird concluída com sucesso em ' +
          FormatDuration(GetTickCount64 - StartTick) + '.', clLime);
        StatusBarProcesso.SimpleText := 'Firebird atualizado em ' + FormatDuration(GetTickCount64 - StartTick) + '.';
      end;
      FUltimaEtapaExecutadaComSucesso := True;
    except
      on E: Exception do
      begin
        StatusBarProcesso.SimpleText := 'Erro ao atualizar Firebird.';
        LogFirebird('Erro ao atualizar Firebird: ' + E.Message, clRed);
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormPrincipal.ExecutarEtapaInstalacaoFirebird25;
var
  StartTick: UInt64;
begin
  StartTick := GetTickCount64;
  FUltimaEtapaExecutadaComSucesso := False;

  Screen.Cursor := crHourGlass;
  StatusBarProcesso.SimpleText := 'Instalação do Firebird 2.5 em andamento...';

  try
    try
      LogFirebird('Retorno para Firebird 2.5 iniciado...', clAqua);
      AtualizarFirebird5_Para_2_5;
      RetomarBancoOriginal25;

      LogFirebird('Retorno para Firebird 2.5 concluído com sucesso em ' +
        FormatDuration(GetTickCount64 - StartTick) + '.', clLime);
      StatusBarProcesso.SimpleText := 'Firebird 2.5 instalado em ' + FormatDuration(GetTickCount64 - StartTick) + '.';
      FUltimaEtapaExecutadaComSucesso := True;
    except
      on E: Exception do
      begin
        StatusBarProcesso.SimpleText := 'Erro ao instalar Firebird 2.5.';
        LogFirebird('Erro ao instalar Firebird 2.5: ' + E.Message, clRed);
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormPrincipal.ExecutarEtapaRestoreFirebird5;
var
  StartTick: UInt64;
begin
  StartTick := GetTickCount64;
  FUltimaEtapaExecutadaComSucesso := False;

  Screen.Cursor := crHourGlass;
  StatusBarProcesso.SimpleText := 'Conversão e atualização em andamento...';

  try
    try
      LogFirebird('Conversão do banco e atualização do sistema iniciadas...', clAqua);

      // a retomada pula a etapa do Firebird: o servidor 5 e conferido aqui tambem
      GarantirServidorFirebird5(EmptyStr);
      ExecutarRestoreFirebird5;

      LogFirebird('Conversão e atualização do sistema concluídas em ' +
        FormatDuration(GetTickCount64 - StartTick) + '.', clLime);
      StatusBarProcesso.SimpleText := 'Conversão e atualização concluídas em ' + FormatDuration(GetTickCount64 - StartTick) + '.';
      FUltimaEtapaExecutadaComSucesso := True;
    except
      on E: Exception do
      begin
        StatusBarProcesso.SimpleText := 'Erro na conversão ou atualização do sistema.';
        LogFirebird('Erro na conversão ou atualização do sistema: ' + E.Message, clRed);
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFormPrincipal.CarregarDadosArquivoIni;
begin
  edtDatabase.Text := TAppConfig.Database;
end;

procedure TFormPrincipal.AtualizarEstadoBanco;
var
  Informado: Boolean;
  JaConvertido: Boolean;
  Cabecalho: TInfoCabecalhoFdb;
begin
  // Botoes sempre habilitados (decisao do Valdo, 05/10/2026): o bloqueio contra
  // reexecucao fica em ValidarPreRequisitosSomenteLeitura (ODS >= 12) e em FProcessoEmAndamento.
  Informado := TAppConfig.Database <> EmptyStr;
  // banco ja no formato do Firebird 3+ (ODS >= 12, lido do arquivo): migracao feita,
  // o botao Iniciar fica bloqueado para ninguem executar de novo
  JaConvertido := False;
  if Informado then
  begin
    Cabecalho := TValidacaoConversao.LerCabecalho(LocalDatabaseFileName(TAppConfig.Database));
    JaConvertido := Cabecalho.Valido and (Cabecalho.ODS >= 12);
  end;
  if JaConvertido then
    StatusBarProcesso.SimpleText := 'Banco jã convertido (ODS ' + IntToStr(Cabecalho.ODS) +
      '): a migração jã foi feita neste servidor.'
  else if Informado then
    StatusBarProcesso.SimpleText := 'Pronto para iniciar a migração.'
  else
    StatusBarProcesso.SimpleText := 'Banco de dados não informado: informe o caminho e clique em Salvar.';
end;

procedure TFormPrincipal.btnProcurarBancoClick(Sender: TObject);
var
  Dlg: TOpenDialog;
  Pasta: string;
begin
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Title := 'Selecionar o banco de dados do Gestão';
    Dlg.Filter := 'Banco Firebird (*.fdb)|*.fdb|Todos os arquivos (*.*)|*.*';
    Dlg.Options := Dlg.Options + [ofFileMustExist];
    Pasta := ExtractFilePath(LocalDatabaseFileName(edtDatabase.Text));
    if (Pasta <> EmptyStr) and DirectoryExists(Pasta) then
      Dlg.InitialDir := Pasta;
    if Dlg.Execute then
      edtDatabase.Text := Dlg.FileName;
  finally
    Dlg.Free;
  end;
end;

procedure TFormPrincipal.btnSalvarBancoClick(Sender: TObject);
var
  Valor: string;
begin
  if FProcessoEmAndamento then
  begin
    TMensagens.Aviso(SMsgProcessoEmAndamento);
    Exit;
  end;

  Valor := Trim(edtDatabase.Text);
  if Valor = EmptyStr then
  begin
    TMensagens.Aviso('Informe o caminho do banco de dados.');
    Exit;
  end;

  try
    TAppConfig.SalvarDatabase(Valor);
  except
    on E: Exception do
    begin
      TMensagens.Excecao('Não foi possível gravar o Config.ini', E);
      Exit;
    end;
  end;

  CarregarDadosArquivoIni;
  AtualizarEstadoBanco;
  LogFirebird('Caminho do banco gravado no Config.ini: ' + TAppConfig.Database, clAqua);
end;

function TFormPrincipal.RunAndWait(const Exe, Params: string): Boolean;
begin
  Result := TProcessoWindows.ExecutarElevadoEAguardar(
    Exe, Params, AtualizarStatus);

  if not Result then
  begin
    LogTecnico('Falha ao executar processo: ' + Exe, clRed);
    if TProcessoWindows.UltimoErro <> EmptyStr then
      LogTecnico('Detalhe do Windows: ' +
        TProcessoWindows.UltimoErro, clRed);
  end;
end;

procedure TFormPrincipal.AtualizarStatus(const Texto: string);
begin
  StatusBarProcesso.SimpleText := Texto;
end;

function TFormPrincipal.LatestBackupFileName: string;
var
  Search: TSearchRec;
  Candidate: string;
  LastTime: TDateTime;
begin
  Result := EmptyStr;
  LastTime := 0;

  if not DirectoryExists(BackupDirectory) then
    Exit;

  if FindFirst(IncludeTrailingPathDelimiter(BackupDirectory) + '*.fbk', faAnyFile, Search) = 0 then
  begin
    try
      repeat
        Candidate := IncludeTrailingPathDelimiter(BackupDirectory) + Search.Name;
        if (Search.Attr and faDirectory) = 0 then
        begin
          if (Result = EmptyStr) or (Search.TimeStamp > LastTime) then
          begin
            Result := Candidate;
            LastTime := Search.TimeStamp;
          end;
        end;
      until FindNext(Search) <> 0;
    finally
      FindClose(Search);
    end;
  end;
end;

function TFormPrincipal.LocalDatabaseFileName(const DatabaseName: string): string;
var
  P: Integer;
begin
  Result := Trim(DatabaseName);
  P := Pos(':\', Result);

  if P > 1 then
    Result := Copy(Result, P - 1, MaxInt);
end;

function TFormPrincipal.RestoreDatabaseName: string;
begin
  Result := Trim(TAppConfig.Database);
  if Result = EmptyStr then
    raise Exception.Create('Caminho do banco não informado no Config.ini.');
end;

function TFormPrincipal.NormalizeGbakDatabaseName(const DatabaseName: string): string;
begin
  Result := Trim(DatabaseName);

  if SameText(Copy(Result, 1, Length('localhost/')), 'localhost/') then
    Result := '127.0.0.1/' + Copy(Result, Length('localhost/') + 1, MaxInt)
  else if SameText(Copy(Result, 1, Length('localhost:')), 'localhost:') then
    Result := '127.0.0.1:' + Copy(Result, Length('localhost:') + 1, MaxInt);
end;

function TFormPrincipal.ConvertedDatabaseName: string;
var
  Database: string;
  Prefix: string;
  LocalFile: string;
  P: Integer;
begin
  Database := NormalizeGbakDatabaseName(RestoreDatabaseName);
  Prefix := EmptyStr;
  LocalFile := Database;
  P := Pos(':\', Database);

  if P > 1 then
  begin
    Prefix := Copy(Database, 1, P - 2);
    LocalFile := Copy(Database, P - 1, MaxInt);
  end;

  Result := Prefix + ExtractFilePath(LocalFile) +
    ChangeFileExt(ExtractFileName(LocalFile), EmptyStr) + '_FB5' + ExtractFileExt(LocalFile);
end;

function TFormPrincipal.OriginalDatabaseBackupFileName(const DatabaseFileName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(BackupDirectory) +
    ChangeFileExt(ExtractFileName(DatabaseFileName), EmptyStr) +
    '_ORIGINAL_FB25_' + FormatDateTime('yyyymmdd_hhnnss', Now) + ExtractFileExt(DatabaseFileName);
end;

function TFormPrincipal.FormatDuration(const Milliseconds: UInt64): string;
begin
  Result := TProcessoWindows.FormatarDuracao(Milliseconds);
end;

function TFormPrincipal.CommandProcessor: string;
begin
  Result := TProcessoWindows.ProcessadorComandos;
end;

function TFormPrincipal.GbakLogFileName(const Prefix: string): string;
begin
  Result := IncludeTrailingPathDelimiter(BackupDirectory) +
    Prefix + '_gbak_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.log';
end;

procedure TFormPrincipal.LogTextFile(const FileName: string; const Titulo: string; Cor: TColor);
var
  Linhas: TStringList;
  I: Integer;
begin
  if not FileExists(FileName) then
  begin
    LogFirebird(Titulo + ': arquivo de log não encontrado: ' + FileName, clYellow);
    Exit;
  end;

  LogTecnico(Titulo + ': ' + FileName, clAqua);

  Linhas := TStringList.Create;
  try
    Linhas.LoadFromFile(FileName);
    for I := 0 to Linhas.Count - 1 do
    begin
      if Trim(Linhas[I]) <> EmptyStr then
        LogTecnico(Linhas[I], Cor);
    end;
  finally
    Linhas.Free;
  end;
end;
function TFormPrincipal.QuoteParam(const Value: string): string;
begin
  Result := '"' + Value + '"';
end;

function TFormPrincipal.BackupDirectory: string;
var
  DatabaseFile: string;
begin
  DatabaseFile := LocalDatabaseFileName(TAppConfig.Database);

  if (DatabaseFile <> EmptyStr) and (ExtractFilePath(DatabaseFile) <> EmptyStr) then
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(DatabaseFile)) + 'BackupMigracao'
  else
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'BackupMigracao';
end;

procedure TFormPrincipal.IniciarLogProcesso;
var
  Carimbo: string;
begin
  if not DirectoryExists(BackupDirectory) then
    ForceDirectories(BackupDirectory);

  Carimbo := FormatDateTime('yyyymmdd_hhnnss', Now);
  FLogProcessoFileName := IncludeTrailingPathDelimiter(BackupDirectory) +
    'migracao_processo_' + Carimbo + '.log';
  // 09/10/2026: cronologia completa (LogFirebird + LogTecnico) num segundo arquivo;
  // o principal continua limpo. O glob de suporte migracao_processo_*.log pega os dois.
  FLogTecnicoFileName := IncludeTrailingPathDelimiter(BackupDirectory) +
    'migracao_processo_' + Carimbo + '_tecnico.log';
end;

procedure TFormPrincipal.GravarLogProcesso(const Linha: string);
var
  Writer: TStreamWriter;
begin
  if FLogProcessoFileName = EmptyStr then
    Exit;

  try
    Writer := TStreamWriter.Create(
      FLogProcessoFileName, True, TEncoding.UTF8);
    try
      Writer.WriteLine(Linha);
    finally
      Writer.Free;
    end;
  except
    on E: Exception do
    begin
      FLogProcessoFileName := EmptyStr;
      LogTecnico('Aviso: não foi possível gravar o log do processo. ' +
        'Detalhe: ' + E.Message, clYellow);
    end;
  end;
end;

procedure TFormPrincipal.GravarLogTecnicoArquivo(const Linha: string);
var
  Writer: TStreamWriter;
begin
  if FLogTecnicoFileName = EmptyStr then
    Exit;

  try
    Writer := TStreamWriter.Create(
      FLogTecnicoFileName, True, TEncoding.UTF8);
    try
      Writer.WriteLine(Linha);
    finally
      Writer.Free;
    end;
  except
    // sem LogTecnico aqui: ele grava neste mesmo arquivo (recursao)
    FLogTecnicoFileName := EmptyStr;
  end;
end;
function TFormPrincipal.BackupFileName: string;
begin
  Result := IncludeTrailingPathDelimiter(BackupDirectory) +
    'backup_firebird25_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.fbk';
end;

procedure TFormPrincipal.CopiarBancoOrigemParaSeguranca(const DatabaseFileName: string);
var
  BackupOriginal: string;
begin
  FBackupBancoOriginalAtual := EmptyStr;
  FBancoOriginalCopiado := EmptyStr;

  if DatabaseFileName = EmptyStr then
    Exit;

  if not FileExists(DatabaseFileName) then
  begin
    LogFirebird('Banco origem não encontrado no disco local para copiar: ' + DatabaseFileName, clYellow);
    Exit;
  end;

  if not DirectoryExists(BackupDirectory) then
    ForceDirectories(BackupDirectory);

  BackupOriginal := OriginalDatabaseBackupFileName(DatabaseFileName);

  LogFirebird('Copiando banco Firebird 2.5 original para segurança...', clYellow);
  LogTecnico('Destino da cópia do banco original: ' + BackupOriginal, clGray);

  if not CopyFile(PChar(DatabaseFileName), PChar(BackupOriginal), True) then
    raise Exception.Create('não foi possível copiar o banco original para a pasta de segurança: ' + DatabaseFileName);

  FBackupBancoOriginalAtual := BackupOriginal;
  FBancoOriginalCopiado := DatabaseFileName;

  LogFirebird('Banco original preservado em: ' + BackupOriginal, clLime);
end;

procedure TFormPrincipal.MoverBancoOrigemParaLiberarRestore(const DatabaseFileName: string);
var
  BackupOriginal: string;
begin
  if DatabaseFileName = EmptyStr then
    Exit;

  if not FileExists(DatabaseFileName) then
    Exit;

  if not DirectoryExists(BackupDirectory) then
    ForceDirectories(BackupDirectory);

  BackupOriginal := OriginalDatabaseBackupFileName(DatabaseFileName);

  LogFirebird('Movendo banco antigo para liberar o caminho do restore...', clYellow);
  LogFirebird('Banco antigo movido para: ' + BackupOriginal, clWhite);

  if not RenameFile(DatabaseFileName, BackupOriginal) then
    raise Exception.Create('não foi possível mover o banco antigo para liberar o restore: ' + DatabaseFileName);
end;

procedure TFormPrincipal.SubstituirBancoOriginalPeloConvertido(
  const DatabaseFileName, ConvertedFileName: string);
var
  BancoAnterior: string;
  ManterBackup: Boolean;
begin
  if not FileExists(DatabaseFileName) then
    raise Exception.Create('Banco original não encontrado para substituição: ' + DatabaseFileName);

  if not FileExists(ConvertedFileName) then
    raise Exception.Create('Banco convertido não encontrado para substituição: ' + ConvertedFileName);

  ManterBackup := (FBackupBancoOriginalAtual = EmptyStr) or
    (not SameText(FBancoOriginalCopiado, DatabaseFileName)) or
    (not FileExists(FBackupBancoOriginalAtual));

  if ManterBackup then
  begin
    BancoAnterior := OriginalDatabaseBackupFileName(DatabaseFileName);
    LogFirebird('Movendo banco antigo para a pasta de segurança...', clYellow);
    LogFirebird('Banco antigo preservado em: ' + BancoAnterior, clWhite);
  end
  else
  begin
    BancoAnterior := IncludeTrailingPathDelimiter(BackupDirectory) +
      ChangeFileExt(ExtractFileName(DatabaseFileName), EmptyStr) +
      '_TROCA_TEMP_' + FormatDateTime('yyyymmdd_hhnnss_zzz', Now) + '.tmp';
    LogTecnico('Preparando a substituição segura do banco original...', clGray);
  end;

  if not RenameFile(DatabaseFileName, BancoAnterior) then
    raise Exception.Create('Não foi possível liberar o caminho do banco original: ' + DatabaseFileName);

  try
    if not RenameFile(ConvertedFileName, DatabaseFileName) then
      raise Exception.Create('Restore concluído, mas não foi possível colocar o banco convertido no caminho original: ' + DatabaseFileName);
  except
    on E: Exception do
    begin
      if (not FileExists(DatabaseFileName)) and FileExists(BancoAnterior) then
      begin
        if RenameFile(BancoAnterior, DatabaseFileName) then
          LogFirebird('A substituição falhou e o banco original foi restaurado.', clYellow)
        else
          raise Exception.Create(
            'Falha crítica ao substituir o banco e restaurar o original. ' +
            'O banco anterior permanece em: ' + BancoAnterior +
            '. Erro original: ' + E.Message);
      end;
      raise;
    end;
  end;

  if not ManterBackup then
  begin
    if DeleteFile(BancoAnterior) then
      LogTecnico('Arquivo temporário da substituição removido.', clGray)
    else
      LogFirebird('Aviso: não foi possível remover o arquivo temporário: ' +
        BancoAnterior, clYellow);
  end;

  FBackupBancoOriginalAtual := EmptyStr;
  FBancoOriginalCopiado := EmptyStr;
end;

procedure TFormPrincipal.ExecutarRestoreFirebird5;
var
  Gbak: string;
  Isql5: string;
  BackupFile: string;
  RetratoOrigem: string;
  RetratoDestino: string;
  RestoreDatabase: string;
  RestoreLocalFile: string;
  ConvertedDatabase: string;
  ConvertedLocalFile: string;
  ServicoFB5: string;
  GbakLog: string;
  Params: string;
  CmdParams: string;
  Relatorio: TStringList;
  Aprovado: Boolean;
  I: Integer;
begin
  // O1-1: o .fbk EXATO desta conversao (manifesto), nunca "o mais recente da pasta"
  BackupFile := TValidacaoConversao.LerManifesto(BackupDirectory, 'Fbk');
  if (BackupFile = EmptyStr) or (not FileExists(BackupFile)) then
    raise Exception.Create('O backup desta conversão não foi encontrado (manifesto ' +
      'ultima_conversao.ini em ' + BackupDirectory + '). Refaça a migração a partir do ' +
      'backup ou use a restauração manual de FBK.');
  RetratoOrigem := TValidacaoConversao.LerManifesto(BackupDirectory, 'RetratoOrigem');
  if (RetratoOrigem = EmptyStr) or (not FileExists(RetratoOrigem)) then
    raise Exception.Create('O retrato do banco de origem desta conversão não foi encontrado; ' +
      'sem ele o banco convertido não pode ser validado. Refaça a migração a partir do backup.');

  Gbak := FerramentaFirebird5('gbak.exe');
  Isql5 := FerramentaFirebird5('isql.exe');

  RestoreDatabase := RestoreDatabaseName;
  RestoreLocalFile := LocalDatabaseFileName(RestoreDatabase);
  ConvertedDatabase := ConvertedDatabaseName;
  ConvertedLocalFile := LocalDatabaseFileName(ConvertedDatabase);

  if ConvertedLocalFile <> EmptyStr then
  begin
    if (ExtractFilePath(ConvertedLocalFile) <> EmptyStr) and
       (not DirectoryExists(ExtractFilePath(ConvertedLocalFile))) then
      ForceDirectories(ExtractFilePath(ConvertedLocalFile));

    if FileExists(ConvertedLocalFile) then
      MoverBancoOrigemParaLiberarRestore(ConvertedLocalFile);
  end;

  // Service Manager do mesmo servidor/porta da string de conexao
  ServicoFB5 := Fc_ServicoManagerDaConexao(ConvertedDatabase);

  GbakLog := GbakLogFileName('restore');

  LogFirebird('Backup usado na conversão: ' + BackupFile, clWhite);
  LogTecnico('Arquivo de backup: ' + BackupFile, clGray);
  LogTecnico('GBAK: ' + Gbak, clGray);
  LogTecnico('Service Manager: ' + ServicoFB5, clGray);
  LogTecnico('Banco convertido temporário: ' + ConvertedDatabase, clWhite);
  LogFirebird('Log técnico do restore: ' + GbakLog, clGray);

  // Parametros padrao (uGbakPadrao): -c -v -p 8192 -se, caminhos locais do servidor
  Params := Fc_ParametrosRestoreGbak('sysdba', 'masterkey', BackupFile, ConvertedLocalFile, ServicoFB5);
  CmdParams := '/C "' + QuoteParam(Gbak) + ' ' + Params + ' > ' + QuoteParam(GbakLog) + ' 2>&1"';

  if not RunAndWait(CommandProcessor, CmdParams) then
  begin
    LogTextFile(GbakLog, 'Saída do gbak restore', clRed);
    raise Exception.Create('Falha ao executar gbak do Firebird 5. ' +
      TProcessoWindows.UltimoErro +
      ' O banco original ainda não foi substituído. Consulte o log técnico.');
  end;

  LogTextFile(GbakLog, 'Saída do gbak restore', clGray);

  if (ConvertedLocalFile <> EmptyStr) and (not FileExists(ConvertedLocalFile)) then
    raise Exception.Create('O gbak terminou, mas o banco convertido não foi encontrado.');

  // O1-2: validacao ANTES de ativar; o banco original continua fechado e intacto
  RetratoDestino := IncludeTrailingPathDelimiter(BackupDirectory) + 'retrato_fb5_' +
    FormatDateTime('yyyymmdd_hhnnss', Now) + '.txt';
  LogFirebird('Conferindo o banco convertido contra o original...', clAqua);
  TValidacaoConversao.GerarRetrato(Isql5, ConvertedDatabase, RetratoDestino);
  LogTecnico('Retrato do banco convertido: ' + RetratoDestino, clGray);
  Relatorio := TStringList.Create;
  try
    Aprovado := TValidacaoConversao.Comparar(RetratoOrigem, RetratoDestino, Relatorio);
    for I := 0 to Relatorio.Count - 1 do
      if Aprovado then
        LogFirebird(Relatorio[I], clLime)
      else
        LogFirebird(Relatorio[I], clRed);
  finally
    Relatorio.Free;
  end;
  if not Aprovado then
    raise Exception.Create('O banco convertido não confere com o original (veja o log). ' +
      'O banco original não foi substituído e continua preservado.');

  // Conexao do sistema (fbclient.dll do Bin) com o banco convertido, ainda antes de ativar
  LogFirebird('Testando a conexão do sistema com o banco convertido...', clAqua);
  TestarConexaoBanco(False, ConvertedDatabase);
  LogFirebird('Conexão do sistema com o banco convertido validada.', clLime);

  // O0-5: o fbclient.dll do Bin (pacote do GestaoUpdate, 4.x) ja fala com o Firebird 5
  if RestoreLocalFile <> EmptyStr then
  begin
    LogFirebird('Substituindo banco original pelo banco convertido...', clYellow);
    LogTecnico('Destino oficial: ' + RestoreLocalFile, clWhite);
    SubstituirBancoOriginalPeloConvertido(RestoreLocalFile, ConvertedLocalFile);
  end;

  LogFirebird('Banco convertido ativado em: ' + RestoreDatabase, clLime);

  // Conferencia final no caminho oficial (O0-5: o Gestao.exe e atualizado pelo
  // GestaoUpdate, nao aqui)
  LogFirebird('Testando a conexão do sistema no caminho oficial do banco...', clAqua);
  TestarConexaoBanco(False);
  LogFirebird('Conexão do sistema com o Firebird 5 validada.', clLime);

  // O1-4: registra a conversao; o GestaoUpdate confirma o 5.x e encerra o transitorio
  TValidacaoConversao.GravarMarcadorConversao(
    IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + CONFIG_INI, BackupFile);
  TValidacaoConversao.GravarManifesto(BackupDirectory, 'Concluida',
    FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
  LogFirebird('Conversão registrada no Config.ini ([ATUALIZADOR] Firebird=5.0, Transitorio=N).', clLime);
end;

procedure TFormPrincipal.ExecutarBackupFirebird25;
var
  Gbak: string;
  Database: string;
  BackupFile: string;
  GbakLog: string;
  Params: string;
  CmdParams: string;
  RetratoOrigem: string;
begin
  Database := NormalizeGbakDatabaseName(TAppConfig.Database);
  if Database = EmptyStr then
    raise Exception.Create('Caminho do banco não informado no Config.ini.');

  // O0-5: Gestao.exe e DLLs ficam com o GestaoUpdate (nao prepara nem aplica o Gestao aqui)
  Gbak := TFirebirdAmbiente.Gbak25;
  if Gbak = EmptyStr then
  begin
    LogTecnico('Executável Firebird 2.5 detectado: ' +
      TFirebirdAmbiente.Executavel25, clRed);
    LogTecnico('Diretório Firebird 2.5 detectado: ' +
      TFirebirdAmbiente.Diretorio25, clRed);
    raise Exception.Create('gbak.exe do Firebird 2.5 não encontrado.');
  end;

  // O0-7: ninguem conectado e banco fechado para gravacao ate a troca; o que fosse
  // gravado depois do backup seria perdido na conversao.
  // 09/10/2026: na migracao assistida o banco ja entrou em modo exclusivo logo depois
  // do reinicio do servico; o backup avulso (sem o flag) continua fechando aqui.
  if FBancoEmModoExclusivo then
    LogFirebird('Banco de dados já está em modo exclusivo desde o início da migração.', clAqua)
  else
  begin
    ValidarBancoSemConexoes;
    LogFirebird('Fechando o banco de dados para a conversão (shutdown)...', clYellow);
    TPreRequisitosConversao.ColocarEmShutdown(Gbak, Database);
    LogFirebird('Banco de dados fechado para uso até o fim da conversão.', clLime);
  end;

  // O1-1/O1-2: manifesto desta conversao e retrato do banco de origem, tirado
  // com o banco ja fechado (single), imediatamente antes do gbak
  TValidacaoConversao.IniciarManifesto(BackupDirectory);
  TValidacaoConversao.GravarManifesto(BackupDirectory, 'Banco', LocalDatabaseFileName(Database));
  RetratoOrigem := IncludeTrailingPathDelimiter(BackupDirectory) + 'retrato_fb25_' +
    FormatDateTime('yyyymmdd_hhnnss', Now) + '.txt';
  LogFirebird('Conferindo o banco de origem (registros por tabela, generators e objetos)...', clAqua);
  TValidacaoConversao.GerarRetrato(IncludeTrailingPathDelimiter(ExtractFilePath(Gbak)) +
    'isql.exe', Database, RetratoOrigem);
  TValidacaoConversao.GravarManifesto(BackupDirectory, 'RetratoOrigem', RetratoOrigem);
  LogTecnico('Retrato do banco de origem: ' + RetratoOrigem, clGray);

  if not DirectoryExists(BackupDirectory) then
    ForceDirectories(BackupDirectory);

  BackupFile := BackupFileName;
  GbakLog := GbakLogFileName('backup');

  LogFirebird('Banco de origem: ' + Database, clWhite);
  LogTecnico('GBAK: ' + Gbak, clGray);
  LogTecnico('Arquivo de backup: ' + BackupFile, clGray);
  LogFirebird('Log técnico do backup: ' + GbakLog, clGray);

  // -g: sem coleta de lixo durante o backup (mais rapido; o restore recria tudo limpo)
  Params := Fc_ParametrosBackupGbak('sysdba', 'masterkey', Database, BackupFile);

  CmdParams := '/C "' + QuoteParam(Gbak) + ' ' + Params + ' > ' + QuoteParam(GbakLog) + ' 2>&1"';

  if not RunAndWait(CommandProcessor, CmdParams) then
  begin
    LogTextFile(GbakLog, 'Saída do gbak backup', clRed);
    raise Exception.Create('Falha ao executar gbak do Firebird 2.5. ' +
      TProcessoWindows.UltimoErro + ' Consulte o log técnico.');
  end;

  LogTextFile(GbakLog, 'Saída do gbak backup', clGray);

  if not FileExists(BackupFile) then
    raise Exception.Create('O gbak terminou, mas o arquivo de backup não foi encontrado.');

  LogFirebird('Backup gerado: ' + BackupFile, clLime);
  TValidacaoConversao.GravarManifesto(BackupDirectory, 'Fbk', BackupFile);

  // Backup pronto: fecha totalmente (nem SYSDBA entra; o Gestao conecta como SYSDBA)
  TPreRequisitosConversao.FecharTotalmente(Gbak, Database);
  LogFirebird('Banco de dados fechado totalmente até a troca pelo banco convertido.', clLime);

  // Copia fisica so depois do backup, com o banco fechado e sem conexoes (copia consistente)
  CopiarBancoOrigemParaSeguranca(LocalDatabaseFileName(Database));
  if FBackupBancoOriginalAtual <> EmptyStr then
    TValidacaoConversao.GravarManifesto(BackupDirectory, 'CopiaOriginal', FBackupBancoOriginalAtual);
end;

procedure TFormPrincipal.LimparResiduosFirebird5(const Pasta: string);
var
  Tentativa: Integer;
begin
  // O desinstalador Inno nao apaga arquivos em uso: com o firebird.exe ainda ativo
  // sobram firebird.exe, gbak, gfix e fbclient na pasta, e o Executavel5 passa a
  // enxergar uma instalacao fantasma (05/10/2026, Bimax). Apaga o residuo.
  if (Pasta = EmptyStr) or (not DirectoryExists(Pasta)) then
    Exit;
  if not ContainsText(Pasta, 'Firebird_5_0') then
  begin
    LogTecnico('Pasta do Firebird 5 fora do padrao, residuo nao apagado: ' + Pasta, clYellow);
    Exit;
  end;

  LogFirebird('Apagando o que sobrou da pasta do Firebird 5...', clYellow);
  LogTecnico('Pasta: ' + Pasta, clGray);
  for Tentativa := 1 to 10 do
  begin
    try
      TDirectory.Delete(ExcludeTrailingPathDelimiter(Pasta), True);
    except
      on E: Exception do
        LogTecnico('Tentativa ' + IntToStr(Tentativa) + ' de apagar a pasta: ' + E.Message, clGray);
    end;
    if not DirectoryExists(Pasta) then
      Break;
    // processo do servidor ainda soltando os arquivos
    Sleep(1000);
    Application.ProcessMessages;
  end;

  if DirectoryExists(Pasta) then
    LogFirebird('Aviso: nao foi possivel apagar toda a pasta ' + Pasta +
      '. Feche o que estiver usando o Firebird 5 e remova a pasta manualmente.', clYellow)
  else
    LogFirebird('Pasta do Firebird 5 removida.', clLime);
end;

procedure TFormPrincipal.RemoverInstalacaoFirebird5;
const
  C_SERVICO = 'FirebirdServerDefaultInstance';
var
  Uninstaller: string;
  VersaoFB5: string;
  Pasta5: string;
  Instsvc: string;
begin
  LogTecnico('Verificando Firebird 5...', clGray);

  if not TFirebirdAmbiente.Firebird5Instalado then
  begin
    LogFirebird('Nenhuma instalação do Firebird 5 encontrada.', clAqua);
    Exit;
  end;

  VersaoFB5 := TFirebirdAmbiente.Versao5;
  if VersaoFB5 <> EmptyStr then
    LogFirebird('Firebird 5 encontrado. versão: ' + VersaoFB5 + '.',
      clYellow)
  else
    LogFirebird('Vestígios do Firebird 5 encontrados.', clYellow);

  Pasta5 := IncludeTrailingPathDelimiter(ExtractFilePath(TFirebirdAmbiente.Executavel5));
  Uninstaller := TFirebirdAmbiente.Desinstalador5;

  // Servico parado ANTES do desinstalador: com o firebird.exe ativo o Inno nao
  // consegue apagar os binarios e deixa a instalacao pela metade.
  TFirebirdServicos.PararTodos(
    LogFirebird, LogTecnico, AtualizarStatus);

  if Uninstaller = EmptyStr then
  begin
    // Residuo de uma remocao anterior (sem unins000.exe): tira o registro do servico
    // e apaga a pasta, em vez de abortar.
    LogFirebird('Desinstalador do Firebird 5 nao encontrado: removendo o residuo da instalacao...',
      clYellow);
    Instsvc := Pasta5 + 'instsvc.exe';
    if TFirebirdServicos.Existe(C_SERVICO) then
    begin
      if FileExists(Instsvc) then
      begin
        if not RunAndWait(Instsvc, 'remove') then
          LogTecnico('instsvc remove: ' + TProcessoWindows.UltimoErro, clYellow);
      end
      else
        LogTecnico('instsvc.exe nao encontrado para remover o servico ' + C_SERVICO, clYellow);
    end;
    LimparResiduosFirebird5(Pasta5);
    TFirebirdServicos.AguardarRemocao5(LogFirebird, LogTecnico);
    if TFirebirdAmbiente.Firebird5Instalado then
      raise Exception.Create(
        'Ainda existem vestigios ativos do Firebird 5 em ' + Pasta5 + '.');
    Exit;
  end;

  LogTecnico('Desinstalador do Firebird 5: ' + Uninstaller, clGray);
  LogFirebird('Removendo Firebird 5...', clYellow);

  if not RunAndWait(
    Uninstaller, '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART') then
    raise Exception.Create('Falha ao remover o Firebird 5.');

  LimparResiduosFirebird5(Pasta5);

  LogFirebird('Desinstalador do Firebird 5 concluído.', clLime);
  TFirebirdServicos.AguardarRemocao5(LogFirebird, LogTecnico);

  if TFirebirdAmbiente.Firebird5Instalado then
    raise Exception.Create(
      'Ainda existem vestígios ativos do Firebird 5 após a Remoção.');

  LogFirebird('Remoção do Firebird 5 confirmada.', clLime);
end;

procedure TFormPrincipal.AtualizarFirebird5_Para_2_5;
var
  InstallerFB25: string;
  VersaoFB25: string;
  Motivo: string;
begin
  InstallerFB25 := EmptyStr;

  // 15/10/2026: so sobraram arquivos do 2.5 (sem o servico): reinstala por cima
  if (TFirebirdAmbiente.Executavel25 = EmptyStr) or Firebird25SoSobras then
  begin
    InstallerFB25 := TFirebirdPacotes.ObterInstalador25(
      LogFirebird, LogTecnico, AtualizarStatus);
    LogTecnico('Instalador selecionado: ' + InstallerFB25, clWhite);

    if not FileExists(InstallerFB25) then
    begin
      LogFirebird('Instalador do Firebird 2.5 não encontrado. O Firebird 5 não será removido.', clRed);
      raise Exception.Create('Instalador do Firebird 2.5 não encontrado: ' + InstallerFB25);
    end;
  end
  else
    LogFirebird('Firebird 2.5 já encontrado. Instalador não será baixado agora.', clAqua);

  RemoverInstalacaoFirebird5;

  LogTecnico('Verificando Firebird 2.5...', clGray);

  if (TFirebirdAmbiente.Executavel25 <> EmptyStr) and (not Firebird25SoSobras) then
  begin
    VersaoFB25 := TFirebirdAmbiente.Versao25;

    if VersaoFB25 <> EmptyStr then
      LogFirebird('Firebird 2.5 já está instalado. versão: ' + VersaoFB25 + '. Nenhuma instalação necessária.', clLime)
    else
      LogFirebird('Firebird 2.5 já está instalado. Nenhuma instalação necessária.', clLime);
    // 09/10/2026: instalado nao quer dizer rodando (a remocao do Firebird 5 para os
    // servicos); o retorno do banco original depende do servidor 2.5 no ar
    if not GarantirServidorFirebird25Rodando(Motivo) then
      LogFirebird('Atenção: o servidor Firebird 2.5 não está pronto: ' + Motivo + '.', clRed);
    Exit;
  end;

  if Firebird25SoSobras then
    LogFirebird('Firebird 2.5 encontrado sem o serviço ' + C_SERVICO_FB25 + ' (' +
      TFirebirdAmbiente.Executavel25 + '): sobra de uma remoção anterior. Será ' +
      'reinstalado por cima.', clYellow);

  if InstallerFB25 = EmptyStr then
  begin
    InstallerFB25 := TFirebirdPacotes.ObterInstalador25(
      LogFirebird, LogTecnico, AtualizarStatus);
    LogTecnico('Instalador selecionado: ' + InstallerFB25, clWhite);
  end;

  if not FileExists(InstallerFB25) then
    raise Exception.Create('Instalador do Firebird 2.5 não encontrado: ' + InstallerFB25);

  TFirebirdServicos.PararTodos(
    LogFirebird, LogTecnico, AtualizarStatus);

  LogTecnico('Instalador do Firebird 2.5 validado.', clGray);
  LogFirebird('Instalando Firebird 2.5...', clYellow);

  if not RunAndWait(InstallerFB25, '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /FORCE') then
  begin
    LogFirebird('Falha ao instalar Firebird 2.5.', clRed);
    raise Exception.Create('Falha ao instalar o Firebird 2.5.');
  end;

  VersaoFB25 := TFirebirdAmbiente.Versao25;

  if VersaoFB25 <> EmptyStr then
    LogFirebird('Firebird 2.5 instalado. Versão: ' + VersaoFB25 + '.', clLime)
  else
    LogFirebird('Firebird 2.5 instalado com sucesso.', clLime);
end;

procedure TFormPrincipal.RemoverTodasInstalacoesFirebird25;
var
  Instalacoes: TFirebirdInstalacaoLista;
  Instalacao: TFirebirdInstalacao;
  ArquivoBackupRegistro: string;
  DesinstaladoresExecutados: TStringList;
  PossuiInstalacaoAtiva: Boolean;
  RemocaoAgendada: Boolean;
  ExecutouDesinstalador: Boolean;
  I: Integer;

  procedure AguardarFinalizacaoDosDesinstaladores;
  var
    InicioEspera: UInt64;
    Decorrido: UInt64;
    Restantes: TFirebirdInstalacaoLista;
    Item: TFirebirdInstalacao;
    AindaPossuiArquivosAtivos: Boolean;
    InnoAtivo: Boolean;
    InnoAvisado: Boolean;
  begin
    // 09/10/2026: o unins000.exe devolve o controle antes de terminar (a remocao e
    // feita por uma copia %TEMP%\_iu*.tmp). Enquanto ela existir, espera ate 120 s
    // no total; sem ela, os 30 s de antes.
    // 15/10/2026: pelo fonte do Inno Setup a 1a fase so termina no fim da remocao; a
    // sobra do log real vem dos contadores SharedDLLs (AjustarContadoresCompartilhados
    // e IsolarSobrasFirebird25). A espera fica como protecao.
    InicioEspera := GetTickCount64;
    InnoAtivo := False;
    InnoAvisado := False;
    repeat
      AindaPossuiArquivosAtivos := False;
      Restantes := TFirebirdInstalacoes.DetectarFamilia25;
      try
        for Item in Restantes do
          if Item.PossuiArquivosAtivos then
          begin
            AindaPossuiArquivosAtivos := True;
            Break;
          end;
      finally
        Restantes.Free;
      end;

      if not AindaPossuiArquivosAtivos then
        Exit;

      StatusBarProcesso.SimpleText :=
        'Aguardando o Windows concluir a Remoção do Firebird 2.5...';
      Sleep(1000);
      Application.ProcessMessages;
      Decorrido := GetTickCount64 - InicioEspera;
      if Decorrido > 30000 then
      begin
        InnoAtivo := TFirebirdInstalacoes.DesinstaladorInnoEmExecucao;
        if InnoAtivo and (not InnoAvisado) then
        begin
          InnoAvisado := True;
          LogFirebird('O desinstalador do Firebird 2.5 ainda está trabalhando em segundo ' +
            'plano: aguardando até 2 minutos...', clYellow);
        end;
      end;
    until (Decorrido > 120000) or ((Decorrido > 30000) and (not InnoAtivo));

    LogFirebird(
      'O Windows ainda apresenta arquivos do Firebird 2.5 após ' +
      IntToStr(Decorrido div 1000) + ' segundos.', clYellow);
    if InnoAtivo then
      LogFirebird('O desinstalador do Firebird 2.5 (_iu*.tmp) ainda está em execução.', clYellow);
  end;

  procedure LimparEntradasOrfas;
  var
    EntradasRestantes: TFirebirdInstalacaoLista;
    Entrada: TFirebirdInstalacao;
  begin
    EntradasRestantes := TFirebirdInstalacoes.DetectarFamilia25;
    try
      for Entrada in EntradasRestantes do
      begin
        if Entrada.PossuiArquivosAtivos then
          Continue;

        if not Entrada.PossuiRegistro then
          Continue;

        LogFirebird('Removendo cadastro órfão de ' +
          Entrada.Identificacao + '...', clYellow);

        if not TFirebirdInstalacoes.RemoverEntradaOrfa(
          Entrada, AtualizarStatus, ArquivoBackupRegistro) then
          raise Exception.Create(
            'não foi possível remover o cadastro órfão de ' +
            Entrada.Identificacao + '.');

        LogTecnico('Backup do cadastro removido: ' +
          ArquivoBackupRegistro, clGray);
        LogFirebird('Cadastro órfão removido com segurança.', clLime);
      end;
    finally
      EntradasRestantes.Free;
    end;
  end;

  procedure AjustarContadoresCompartilhados(const Instalacao: TFirebirdInstalacao);
  var
    Linhas: TStringList;
    Linha: string;
    Erro: string;
    Ajustados: Integer;
  begin
    // 15/10/2026 (log real de 15/10): o instalador do 2.5 marca os executaveis como
    // compartilhados (SharedDLLs). Instalado mais de uma vez, o contador fica > 1 e o
    // desinstalador silencioso mantem os arquivos, o que barrava a instalacao do 5.
    // Contador > 1 volta para 1 (com backup .reg) para o proprio desinstalador apagar.
    if Instalacao.Diretorio = EmptyStr then
      Exit;
    Linhas := TStringList.Create;
    try
      TFirebirdInstalacoes.ListarContadoresCompartilhados(Instalacao.Diretorio, Linhas);
      LogTecnico('Contadores SharedDLLs em ' + Instalacao.Diretorio + ': ' +
        IntToStr(Linhas.Count) + ' valor(es) (visão|arquivo|contador).', clGray);
      for Linha in Linhas do
        LogTecnico('SharedDLLs ' + Linha, clGray);

      Linhas.Clear;
      Ajustados := TFirebirdInstalacoes.NormalizarContadoresCompartilhados(
        Instalacao.Diretorio, BackupDirectory, AtualizarStatus, Linhas, Erro);
      for Linha in Linhas do
        LogTecnico(Linha, clGray);
      if Ajustados > 0 then
        LogFirebird('Contadores de uso compartilhado do Firebird 2.5 ajustados para 1 em ' +
          IntToStr(Ajustados) + ' arquivo(s), para o desinstalador remover os executáveis ' +
          '(backup do registro em ' + BackupDirectory + ').', clYellow);
      if Erro <> EmptyStr then
        LogFirebird('Aviso: contadores de uso compartilhado do Firebird 2.5 não ajustados (' +
          Erro + '). O que sobrar depois do desinstalador será isolado.', clYellow);
    finally
      Linhas.Free;
    end;
  end;

  procedure IsolarSobrasFirebird25;
  var
    Sobras: TFirebirdInstalacaoLista;
    Sobra: TFirebirdInstalacao;
    Feito: TStringList;
    Linha: string;
    Processo: string;
    Motivo: string;
    Carimbo: string;
    Resultado: TResultadoIsolamento;
  begin
    // 15/10/2026 (log real de 15/10): sem desinstalador e com executaveis no disco e
    // sobra de uma desinstalacao que manteve os binarios (contador SharedDLLs ainda
    // > 0 ou sem valor). Os executaveis sao isolados por renomeacao (reversivel,
    // nada e apagado). Servico do 2.5 ainda apontando para a pasta ou processo
    // rodando dela: nao mexe e para.
    Sobras := TFirebirdInstalacoes.DetectarFamilia25;
    Feito := TStringList.Create;
    try
      Carimbo := FormatDateTime('yyyymmdd_hhnnss', Now);
      for Sobra in Sobras do
      begin
        if Sobra.DesinstaladorExiste or (not Sobra.PossuiArquivosAtivos) then
          Continue;

        if ServicoFirebird25NaPasta(Sobra.Diretorio) then
          raise Exception.Create('Os arquivos do Firebird 2.5 em ' + Sobra.Diretorio +
            ' continuam registrados como serviço (' + C_SERVICO_FB25 + '). A remoção do ' +
            'Firebird 2.5 não foi concluída e o Firebird 5 não será instalado.');

        Processo := TFirebirdInstalacoes.ProcessoEmExecucaoNoDiretorio(Sobra.Diretorio);
        if Processo <> EmptyStr then
          raise Exception.Create('Há um programa em execução a partir da pasta do Firebird ' +
            '2.5 (' + Processo + '). Feche esse programa ou reinicie o Windows do servidor e ' +
            'execute o MigraFacil de novo. O Firebird 5 não foi instalado.');

        LogFirebird('Isolando os arquivos que sobraram do Firebird 2.5 em ' +
          Sobra.Diretorio + ' (o desinstalador os manteve)...', clYellow);
        Feito.Clear;
        Resultado := TFirebirdInstalacoes.IsolarSobra(Sobra,
          [LocalDatabaseFileName(TAppConfig.Database), BackupDirectory], Carimbo,
          Feito, Motivo);
        for Linha in Feito do
          LogFirebird(Linha, clGray);
        case Resultado of
          riIsolada:
            LogFirebird('Arquivos do Firebird 2.5 isolados (renomeados; nada foi apagado).',
              clLime);
          riAgendadaNoBoot:
            LogFirebird('Parte dos arquivos do Firebird 2.5 está em uso: o Windows troca o ' +
              'nome deles na próxima reinicialização.', clYellow);
        else
          raise Exception.Create('Não foi possível isolar os arquivos que sobraram do ' +
            'Firebird 2.5 em ' + Sobra.Diretorio + ': ' + Motivo +
            '. O Firebird 5 não será instalado.');
        end;
      end;
    finally
      Feito.Free;
      Sobras.Free;
    end;
  end;

begin
  Instalacoes := TFirebirdInstalacoes.DetectarFamilia25;
  DesinstaladoresExecutados := TStringList.Create;
  try
    DesinstaladoresExecutados.CaseSensitive := False;

    if Instalacoes.Count = 0 then
    begin
      LogFirebird('Nenhuma instalação da família Firebird 2.5 encontrada.',
        clAqua);
      Exit;
    end;

    LogFirebird(Format('Instalações do Firebird 2.5 encontradas: %d.',
      [Instalacoes.Count]), clAqua);

    PossuiInstalacaoAtiva := False;
    for I := 0 to Instalacoes.Count - 1 do
    begin
      Instalacao := Instalacoes[I];
      if Instalacao.PossuiArquivosAtivos then
        PossuiInstalacaoAtiva := True;

      LogTecnico('Encontrado: ' + Instalacao.Identificacao + '.',
        clYellow);

      if Instalacao.Diretorio <> EmptyStr then
        LogTecnico('Diretório: ' + Instalacao.Diretorio, clGray);
      if Instalacao.Desinstalador <> EmptyStr then
        LogTecnico('Desinstalador: ' + Instalacao.Desinstalador, clGray);
    end;

    // 09/10/2026: para e espera o PROCESSO do servidor terminar (fbserver preso no
    // momento do desinstalador e uma das hipoteses do 2.5 ter sobrado no log real).
    // Processo vivo depois da espera: nao desinstala pela metade, para antes.
    if PossuiInstalacaoAtiva then
      if not TFirebirdServicos.PararTodosAguardandoProcessos(
        LogFirebird, LogTecnico, AtualizarStatus, 30000) then
        raise Exception.Create(
          'O servidor Firebird 2.5 não terminou de parar (serviço ou processo ainda ' +
          'ativo). A remoção do Firebird 2.5 não foi iniciada e o Firebird 5 não será ' +
          'instalado. Reinicie o Windows do servidor e execute o MigraFacil de novo.');

    for I := 0 to Instalacoes.Count - 1 do
    begin
      Instalacao := Instalacoes[I];

      if Instalacao.DesinstaladorExiste then
      begin
        if DesinstaladoresExecutados.IndexOf(
          Instalacao.Desinstalador) >= 0 then
        begin
          LogTecnico('Desinstalador já executado para outra entrada: ' +
            Instalacao.Desinstalador, clGray);
          Continue;
        end;

        // 15/10/2026: contadores SharedDLLs > 1 voltam para 1 antes do desinstalador
        AjustarContadoresCompartilhados(Instalacao);

        LogFirebird('Removendo ' + Instalacao.Identificacao + '...',
          clYellow);

        if not TFirebirdInstalacoes.ExecutarDesinstalacao(
          Instalacao, AtualizarStatus) then
          raise Exception.Create(
            'Falha ao remover ' + Instalacao.Identificacao + '.');

        DesinstaladoresExecutados.Add(Instalacao.Desinstalador);
        LogTecnico('Desinstalador concluído: ' +
          Instalacao.Identificacao + '.', clLime);
      end
      else if Instalacao.PossuiArquivosAtivos then
        // 15/10/2026: sem desinstalador e com executaveis = sobra de uma remocao
        // anterior (o desinstalador apaga a si mesmo e mantem os binarios com contador
        // SharedDLLs > 0). Antes isto abortava e travava a retomada; agora a sobra e
        // isolada por IsolarSobrasFirebird25, depois do laco.
        LogFirebird('Firebird 2.5 sem desinstalador em ' + Instalacao.Diretorio +
          ': sobra de uma remoção anterior.', clYellow);
    end;
    ExecutouDesinstalador := DesinstaladoresExecutados.Count > 0;
  finally
    DesinstaladoresExecutados.Free;
    Instalacoes.Free;
  end;

  if ExecutouDesinstalador then
    AguardarFinalizacaoDosDesinstaladores;
  IsolarSobrasFirebird25;
  LimparEntradasOrfas;

  Instalacoes := TFirebirdInstalacoes.DetectarFamilia25;
  try
    if Instalacoes.Count > 0 then
    begin
      // 09/10/2026: no log principal (antes so na aba tecnica, que nao era gravada)
      RemocaoAgendada := False;
      for Instalacao in Instalacoes do
      begin
        LogFirebird('Firebird 2.5 ainda encontrado: ' +
          Instalacao.Identificacao + '.', clRed);
        if Instalacao.Diretorio <> EmptyStr then
          LogFirebird('Diretório restante: ' +
            Instalacao.Diretorio, clRed);
        if Instalacao.Desinstalador <> EmptyStr then
          LogFirebird('Desinstalador restante: ' +
            Instalacao.Desinstalador, clRed);
        if Instalacao.PossuiRegistro then
          LogFirebird('Chave restante no Registro: ' +
            Instalacao.ChaveRegistro, clRed);
        if (Instalacao.Diretorio <> EmptyStr) and
           TFirebirdInstalacoes.RemocaoAgendadaNoBoot(Instalacao.Diretorio) then
        begin
          RemocaoAgendada := True;
          LogFirebird('Remoção agendada pelo Windows para a próxima reinicialização: ' +
            Instalacao.Diretorio, clYellow);
        end;
      end;

      if RemocaoAgendada then
        raise Exception.Create(
          'O Windows agendou a remoção dos arquivos restantes do Firebird 2.5 para a próxima ' +
          'reinicialização (arquivos em uso). Reinicie o Windows do servidor e execute o ' +
          'MigraFacil de novo: a migração é retomada de onde parou. O Firebird 5 não foi instalado.');

      raise Exception.Create(
        'Ainda existem instalações da família Firebird 2.5 no Windows. ' +
        'O Firebird 5 não será instalado.');
    end;
  finally
    Instalacoes.Free;
  end;

  LogFirebird(
    'Remoção de todas as instalações da família Firebird 2.5 confirmada.',
    clLime);
end;

function ExeDoImagePath(const ImagePath: string): string;
var
  P: Integer;
begin
  Result := Trim(ImagePath);
  if (Result <> EmptyStr) and (Result[1] = '"') then
  begin
    Delete(Result, 1, 1);
    P := Pos('"', Result);
    if P > 0 then
      Result := Copy(Result, 1, P - 1);
  end
  else
  begin
    P := Pos('.exe', LowerCase(Result));
    if P > 0 then
      Result := Copy(Result, 1, P + 3);
  end;
end;

procedure TFormPrincipal.ValidarServicoFirebird25;
var
  ExeServico: string;
  Versao: string;
begin
  // 09/10/2026: SOMENTE LEITURA. O servico que sera reiniciado e o do Firebird 2.5
  // (nunca reiniciar o servidor de um cliente ja no Firebird 5).
  if not TFirebirdServicos.Existe(C_SERVICO_FB25) then
    raise Exception.Create('O serviço ' + C_SERVICO_FB25 + ' não foi encontrado neste PC. ' +
      'Execute o MigraFacil no servidor onde o Firebird 2.5 está instalado como serviço. ' +
      'Nada foi alterado.');
  ExeServico := ExeDoImagePath(TFirebirdTuning.ImagePathServico(C_SERVICO_FB25));
  if (ExeServico = EmptyStr) or (not FileExists(ExeServico)) then
    raise Exception.Create('O executável do serviço ' + C_SERVICO_FB25 + ' não foi encontrado (' +
      ExeServico + '). Nada foi alterado.');
  Versao := TFirebirdAmbiente.VersaoArquivo(ExeServico);
  if not StartsText('2.5', Versao) then
    raise Exception.Create('O serviço ' + C_SERVICO_FB25 + ' executa ' + ExeServico +
      IfThen(Versao <> EmptyStr, ' (versão ' + Versao + ')', ' (versão não identificada)') +
      ', e não o Firebird 2.5. Nada foi alterado.');
  LogTecnico('Serviço ' + C_SERVICO_FB25 + ': ' + ExeServico + ' (versão ' + Versao + ').', clGray);
end;

function TFormPrincipal.PortaDoBanco: Word;
var
  Database: string;
  Prefixo: string;
  P: Integer;
  Barra: Integer;
  Numero: Integer;
begin
  // 'host/porta:C:\...' -> porta; 'host:C:\...' ou caminho local -> 3050
  Result := 3050;
  Database := Trim(TAppConfig.Database);
  P := Pos(':\', Database);
  if P <= 3 then
    Exit;
  Prefixo := Copy(Database, 1, P - 3);
  Barra := Pos('/', Prefixo);
  if Barra = 0 then
    Exit;
  Numero := StrToIntDef(Trim(Copy(Prefixo, Barra + 1, MaxInt)), 0);
  if (Numero > 0) and (Numero <= 65535) then
    Result := Numero;
end;

function TFormPrincipal.RemocaoFirebird25AgendadaNoBoot: Boolean;
var
  Instalacoes: TFirebirdInstalacaoLista;
  Instalacao: TFirebirdInstalacao;
  Diretorio: string;
begin
  // 09/10/2026: arquivo do 2.5 em uso no desinstalador vira remocao agendada para o
  // boot (PendingFileRenameOperations)
  Result := False;
  Instalacoes := TFirebirdInstalacoes.DetectarFamilia25;
  try
    for Instalacao in Instalacoes do
      if (Instalacao.Diretorio <> EmptyStr) and
         TFirebirdInstalacoes.RemocaoAgendadaNoBoot(Instalacao.Diretorio) then
      begin
        Result := True;
        Exit;
      end;
  finally
    Instalacoes.Free;
  end;
  Diretorio := TFirebirdAmbiente.Diretorio25;
  if Diretorio <> EmptyStr then
    Result := TFirebirdInstalacoes.RemocaoAgendadaNoBoot(Diretorio);
end;

function TFormPrincipal.GarantirServidorFirebird25Rodando(out Motivo: string): Boolean;
var
  ExeServico: string;
  Versao: string;
  Porta: Word;
begin
  // 09/10/2026: servidor 2.5 no ar para o gfix (reabrir o banco). Usado na reabertura
  // depois de falha, no retorno ao 2.5 e na reabertura para uma migracao nova.
  Result := False;
  Motivo := EmptyStr;
  if not TFirebirdServicos.Existe(C_SERVICO_FB25) then
  begin
    Motivo := 'o serviço ' + C_SERVICO_FB25 + ' não existe mais neste PC (Firebird 2.5 removido ' +
      'pela metade?)';
    Exit;
  end;
  ExeServico := ExeDoImagePath(TFirebirdTuning.ImagePathServico(C_SERVICO_FB25));
  if (ExeServico = EmptyStr) or (not FileExists(ExeServico)) then
  begin
    Motivo := 'o executável do serviço ' + C_SERVICO_FB25 + ' não existe mais (' + ExeServico +
      '; Firebird 2.5 removido pela metade?)';
    Exit;
  end;
  Versao := TFirebirdAmbiente.VersaoArquivo(ExeServico);
  if not StartsText('2.5', Versao) then
  begin
    Motivo := 'o serviço ' + C_SERVICO_FB25 + ' executa ' + ExeServico + ' (versão ' + Versao +
      '), que não é o Firebird 2.5';
    Exit;
  end;

  if not TFirebirdServicos.EmExecucao(C_SERVICO_FB25) then
  begin
    LogFirebird('Religando o serviço do Firebird 2.5 para reabrir o banco...', clYellow);
    if not TFirebirdServicos.Iniciar(C_SERVICO_FB25, LogFirebird, LogTecnico,
      AtualizarStatus, 30000) then
    begin
      Motivo := 'o serviço ' + C_SERVICO_FB25 + ' não entrou em execução';
      Exit;
    end;
    if FGuardian25Rodando and TFirebirdServicos.Existe(C_SERVICO_GUARDIAN_FB25) then
      if not TFirebirdServicos.Iniciar(C_SERVICO_GUARDIAN_FB25, LogFirebird, LogTecnico,
        AtualizarStatus, 30000) then
        LogFirebird('Aviso: o Guardian do Firebird 2.5 (' + C_SERVICO_GUARDIAN_FB25 +
          ') não voltou a rodar; o servidor está em execução sem ele.', clYellow);
  end;

  Porta := PortaDoBanco;
  if not TFirebirdServicos.AguardarPorta('127.0.0.1', Porta, 30000) then
  begin
    Motivo := 'o servidor não aceitou conexão na porta ' + IntToStr(Porta) + ' (127.0.0.1)';
    Exit;
  end;
  Result := True;
end;

function TFormPrincipal.ServicoFirebird25NaPasta(const Pasta: string): Boolean;
const
  SERVICOS: array[0..1] of string = (C_SERVICO_FB25, C_SERVICO_GUARDIAN_FB25);
var
  Base: string;
  ExeServico: string;
  I: Integer;
begin
  // 15/10/2026: algum servico do 2.5 (servidor ou Guardian) ainda executa um arquivo
  // de dentro da pasta? Entao a pasta NAO e sobra de desinstalacao.
  Result := False;
  Base := ExcludeTrailingPathDelimiter(Trim(Pasta));
  if Base = EmptyStr then
    Exit;
  Base := IncludeTrailingPathDelimiter(Base);
  for I := Low(SERVICOS) to High(SERVICOS) do
  begin
    if not TFirebirdServicos.Existe(SERVICOS[I]) then
      Continue;
    ExeServico := ExeDoImagePath(TFirebirdTuning.ImagePathServico(SERVICOS[I]));
    if (ExeServico <> EmptyStr) and StartsText(Base, ExeServico) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TFormPrincipal.Firebird25SoSobras: Boolean;
var
  ExeServico: string;
begin
  // 15/10/2026: arquivos do 2.5 no disco sem um servico que execute o 2.5 (sobra de
  // uma desinstalacao que manteve os binarios). Conta como "nao instalado": as
  // rotinas de instalacao do 2.5 reinstalam por cima (o instalador mantem o
  // firebird.conf e o security2.fdb existentes).
  Result := False;
  if TFirebirdAmbiente.Executavel25 = EmptyStr then
    Exit;
  if TFirebirdServicos.Existe(C_SERVICO_FB25) then
  begin
    ExeServico := ExeDoImagePath(TFirebirdTuning.ImagePathServico(C_SERVICO_FB25));
    if (ExeServico <> EmptyStr) and FileExists(ExeServico) and
       StartsText('2.5', TFirebirdAmbiente.VersaoArquivo(ExeServico)) then
      Exit;
  end;
  Result := True;
end;

procedure TFormPrincipal.ReiniciarServicoFirebird25;
const
  C_ESPERA_MS = 60000;
var
  Porta: Word;
begin
  // 09/10/2026 (pedido do Valdo): reinicia o 2.5 antes de qualquer alteracao, para
  // garantir que ninguem esta conectado; o modo exclusivo vem logo em seguida.
  // Obs.: no Classic (fb_inet_server) processos-filho podem sobreviver ao stop; quem
  // garante que ninguem fica conectado e o -force 0 do shutdown que vem em seguida.
  FGuardian25Rodando := TFirebirdServicos.EmExecucao(C_SERVICO_GUARDIAN_FB25);
  LogFirebird('Reiniciando o serviço do Firebird 2.5 (todas as conexões serão encerradas)...',
    clYellow);
  if FGuardian25Rodando then
    LogTecnico('Guardian do Firebird 2.5 em execução: volta junto com o servidor.', clGray);

  if not TFirebirdServicos.PararTodosAguardandoProcessos(LogFirebird, LogTecnico,
    AtualizarStatus, 30000) then
    LogFirebird('Aviso: o servidor Firebird 2.5 não terminou de parar no tempo esperado; ' +
      'tentando iniciar mesmo assim.', clYellow);

  if not TFirebirdServicos.Iniciar(C_SERVICO_FB25, LogFirebird, LogTecnico, AtualizarStatus,
    C_ESPERA_MS) then
    raise Exception.Create('O serviço do Firebird 2.5 (' + C_SERVICO_FB25 + ') não voltou a ' +
      'rodar depois do reinício.' + sLineBreak + sLineBreak +
      'ATENÇÃO: o servidor Firebird está PARADO e o Gestão não conecta até o serviço ' +
      C_SERVICO_FB25 + ' ser iniciado (services.msc) ou o Windows do servidor ser reiniciado.' +
      sLineBreak + 'O banco de dados NÃO foi alterado.');

  if FGuardian25Rodando and TFirebirdServicos.Existe(C_SERVICO_GUARDIAN_FB25) then
    if not TFirebirdServicos.Iniciar(C_SERVICO_GUARDIAN_FB25, LogFirebird, LogTecnico,
      AtualizarStatus, 30000) then
      LogFirebird('Aviso: o Guardian do Firebird 2.5 (' + C_SERVICO_GUARDIAN_FB25 +
        ') não voltou a rodar; o servidor está em execução sem ele.', clYellow);

  Porta := PortaDoBanco;
  if not TFirebirdServicos.AguardarPorta('127.0.0.1', Porta, C_ESPERA_MS) then
    raise Exception.Create('O serviço do Firebird 2.5 foi iniciado, mas o servidor não aceitou ' +
      'conexão na porta ' + IntToStr(Porta) + ' (127.0.0.1) em ' + IntToStr(C_ESPERA_MS div 1000) +
      ' segundos.' + sLineBreak + sLineBreak +
      'ATENÇÃO: o Gestão pode não conectar até o serviço ' + C_SERVICO_FB25 + ' ser reiniciado ' +
      '(services.msc) ou o Windows do servidor ser reiniciado.' + sLineBreak +
      'O banco de dados NÃO foi alterado.');

  LogFirebird('Serviço do Firebird 2.5 reiniciado.', clLime);
end;

function TFormPrincipal.ArquivoFaltandoFirebird5(const Pasta: string): string;
const
  // Arquivos sem os quais a conversao nao anda: ferramentas usadas pelo migrador
  // (isql/gbak/gfix/instsvc), cliente e plugins de engine e autenticacao.
  C_ESSENCIAIS: array[0..8] of string = (
    'firebird.exe', 'isql.exe', 'gbak.exe', 'gfix.exe', 'instsvc.exe',
    'fbclient.dll', 'plugins\engine13.dll', 'plugins\srp.dll', 'fbsvcmgr.exe');
var
  I: Integer;
  Base: string;
begin
  Result := EmptyStr;
  Base := IncludeTrailingPathDelimiter(Pasta);
  for I := Low(C_ESSENCIAIS) to High(C_ESSENCIAIS) do
    if not FileExists(Base + C_ESSENCIAIS[I]) then
    begin
      Result := C_ESSENCIAIS[I];
      Exit;
    end;
end;

function TFormPrincipal.Firebird5Aceitavel(out Motivo: string): Boolean;
var
  Exe: string;
  Porta: string;
  Faltando: string;
begin
  // Firebird 5 que pode atender o banco do Gestao: mesma arquitetura do Windows e
  // porta 3050 (D-06). Instalacao paralela de desenvolvimento (32 bits num Windows
  // 64, outra porta, sem servico) nao e reaproveitada: o oficial e instalado.
  Result := False;
  Motivo := EmptyStr;
  Exe := TFirebirdAmbiente.Executavel5;
  if Exe = EmptyStr then
  begin
    Motivo := 'Firebird 5 não instalado';
    Exit;
  end;
  if TFirebirdAmbiente.WindowsEh64Bits and TFirebirdAmbiente.ArquivoEh32Bits(Exe) then
  begin
    Motivo := 'a instalação encontrada (' + Exe + ') é de 32 bits e o Windows é 64 bits';
    Exit;
  end;
  // Instalacao pela metade (desinstalador Inno rodou com o servico em uso e deixou
  // firebird.exe, gbak e fbclient, mas levou isql, plugins e unins000): nao serve.
  // Sem plugins o servidor nem autentica; sem isql o retrato da conversao falha.
  Faltando := ArquivoFaltandoFirebird5(ExtractFilePath(Exe));
  if Faltando <> EmptyStr then
  begin
    Motivo := 'a instalacao encontrada em ' + ExtractFilePath(Exe) +
      ' esta incompleta (falta ' + Faltando + ')';
    Exit;
  end;
  Porta := Trim(TFirebirdTuning.ValorAtivoConf(ExtractFilePath(Exe) + 'firebird.conf',
    'RemoteServicePort'));
  if (Porta <> EmptyStr) and (Porta <> '3050') then
  begin
    Motivo := 'a instalação encontrada (' + Exe + ') usa a porta ' + Porta +
      ' (o Gestão usa a 3050)';
    Exit;
  end;
  Result := True;
end;

procedure TFormPrincipal.GarantirServidorFirebird5(const InstaladorObtido: string);
const
  C_SERVICO = 'FirebirdServerDefaultInstance';
var
  Motivo: string;
  Instalador: string;
  Exe5: string;
  Instsvc: string;
  ExeServico: string;
  LogInstalacao: string;
  Inicio: UInt64;
  Mudou: Boolean;
begin
  // Idempotente: Firebird 5 aceitavel instalado, servico registrado para ELE e rodando.
  // A remocao do 2.5 leva junto o servico FirebirdServerDefaultInstance (era do 2.5);
  // sem isto o restore (gbak -se) nao encontra servidor.
  Mudou := False;

  // 1) Firebird 5 aceitavel; senao instala o oficial
  if not Firebird5Aceitavel(Motivo) then
  begin
    Mudou := True;
    if TFirebirdAmbiente.Firebird5Instalado then
      LogFirebird('O Firebird 5 encontrado não serve para o servidor: ' + Motivo +
        '. Instalando o Firebird 5 oficial...', clYellow)
    else
      LogFirebird('Instalando Firebird 5...', clYellow);
    Instalador := InstaladorObtido;
    if (Instalador = EmptyStr) or (not FileExists(Instalador)) then
      Instalador := TFirebirdPacotes.ObterInstalador5(LogFirebird, LogTecnico, AtualizarStatus);
    if (Instalador = EmptyStr) or (not FileExists(Instalador)) then
      raise Exception.Create('Instalador do Firebird 5 não encontrado: ' + Instalador);
    TFirebirdServicos.PararTodos(LogFirebird, LogTecnico, AtualizarStatus);
    LogInstalacao := IncludeTrailingPathDelimiter(BackupDirectory) +
      'fb5_instalacao_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.log';
    ForceDirectories(BackupDirectory);
    LogFirebird('Log da instalação do Firebird 5: ' + LogInstalacao, clGray);
    if not RunAndWait(Instalador, '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /FORCE /LOG=' +
      QuoteParam(LogInstalacao)) then
      raise Exception.Create('Falha ao instalar o Firebird 5. ' +
        TProcessoWindows.UltimoErro + ' Consulte o log: ' + LogInstalacao);
    if not Firebird5Aceitavel(Motivo) then
      raise Exception.Create('O Firebird 5 foi instalado, mas ainda não serve para o servidor: ' +
        Motivo + '.');
    LogFirebird('Firebird 5 instalado. Versão: ' + TFirebirdAmbiente.Versao5 + '.', clLime);
  end;
  Exe5 := TFirebirdAmbiente.Executavel5;
  Instsvc := ExtractFilePath(Exe5) + 'instsvc.exe';
  if not FileExists(Instsvc) then
    raise Exception.Create('instsvc.exe não encontrado na instalação do Firebird 5: ' +
      ExtractFilePath(Exe5));

  // 2) servico registrado para ESTE Firebird 5
  if TFirebirdServicos.Existe(C_SERVICO) then
  begin
    ExeServico := ExeDoImagePath(TFirebirdTuning.ImagePathServico(C_SERVICO));
    if (ExeServico <> EmptyStr) and
       (not SameText(ExpandFileName(ExeServico), ExpandFileName(Exe5))) then
    begin
      if FileExists(ExeServico) then
        raise Exception.Create('O serviço ' + C_SERVICO + ' aponta para ' + ExeServico +
          ', e não para o Firebird 5 em ' + Exe5 + '. Ajuste o serviço e tente de novo.');
      // registro orfao (o exe nao existe mais): troca pelo do Firebird 5
      Mudou := True;
      LogFirebird('Removendo o registro antigo do serviço ' + C_SERVICO + ' (' + ExeServico +
        ' não existe mais)...', clYellow);
      if not RunAndWait(Instsvc, 'remove') then
        raise Exception.Create('Não foi possível remover o registro antigo do serviço ' +
          C_SERVICO + ': ' + TProcessoWindows.UltimoErro);
    end;
  end;
  if not TFirebirdServicos.Existe(C_SERVICO) then
  begin
    Mudou := True;
    LogFirebird('Registrando o serviço do Firebird 5 (' + C_SERVICO + ')...', clYellow);
    if not RunAndWait(Instsvc, 'install -auto') then
      raise Exception.Create('Não foi possível registrar o serviço do Firebird 5: ' +
        TProcessoWindows.UltimoErro);
  end;

  // 3) servico em execucao
  if not TFirebirdServicos.EmExecucao(C_SERVICO) then
  begin
    Mudou := True;
    LogFirebird('Iniciando o serviço do Firebird 5...', clYellow);
    if not RunAndWait(Instsvc, 'start') then
      LogTecnico('instsvc start: ' + TProcessoWindows.UltimoErro, clRed);
    Inicio := GetTickCount64;
    while (not TFirebirdServicos.EmExecucao(C_SERVICO)) and (GetTickCount64 - Inicio < 30000) do
    begin
      Sleep(250);
      Application.ProcessMessages;
    end;
    if not TFirebirdServicos.EmExecucao(C_SERVICO) then
      raise Exception.Create('O serviço do Firebird 5 (' + C_SERVICO + ') não entrou em execução.');
  end;

  // Servico em execucao nao garante banco de seguranca inicializado. Esta
  // validacao tambem ocorre na retomada, antes de qualquer restore.
  // Endpoint sempre local (09/10/2026): Garantir recusa host/IP diferente de
  // localhost e abortava a etapa quando o CONFIG.INI usa o IP/nome do servidor.
  TSegurancaFirebird5.Garantir(ExtractFilePath(Exe5),
    'localhost:' + LocalDatabaseFileName(TAppConfig.Database),
    BackupDirectory, LogFirebird, LogTecnico, AtualizarStatus);

  if Mudou then
    LogFirebird('Servidor Firebird 5 pronto: versão ' + TFirebirdAmbiente.Versao5 + ', serviço ' +
      C_SERVICO + ' em execução (' + Exe5 + ').', clLime)
  else
    LogTecnico('Servidor Firebird 5 conferido: versão ' + TFirebirdAmbiente.Versao5 +
      ', serviço em execução (' + Exe5 + ').', clGray);
end;

procedure TFormPrincipal.AtualizarFirebird2_5;
var
  InstallerFB5: string;
  VersaoFB25: string;
  Motivo: string;
begin
  ValidarFbClientDescarregado;
  LogTecnico('Arquitetura do Windows: ' +
    TFirebirdAmbiente.ArquiteturaWindows + '.', clAqua);
  LogTecnico('Verificando Firebird 5...', clGray);

  InstallerFB5 := EmptyStr;
  if Firebird5Aceitavel(Motivo) then
    LogFirebird('Firebird 5 já instalado (versão ' + TFirebirdAmbiente.Versao5 +
      '): será reaproveitado.', clAqua)
  else
  begin
    if TFirebirdAmbiente.Firebird5Instalado then
      LogFirebird('O Firebird 5 encontrado não serve para o servidor: ' + Motivo +
        '. Será instalado o Firebird 5 oficial.', clYellow);
    // antes de remover o 2.5: sem instalador, nada e removido
    InstallerFB5 := TFirebirdPacotes.ObterInstalador5(
      LogFirebird, LogTecnico, AtualizarStatus);
    LogTecnico('Instalador selecionado: ' + InstallerFB5, clWhite);
    if not FileExists(InstallerFB5) then
    begin
      LogFirebird('Instalador compatível com o Windows não encontrado. O Firebird 2.5 não será removido.', clRed);
      raise Exception.Create('Instalador do Firebird 5 não encontrado: ' + InstallerFB5);
    end;
  end;

  LogTecnico('Verificando Firebird 2.5...', clGray);

  if TFirebirdInstalacoes.ExisteFamilia25 then
  begin
    VersaoFB25 := TFirebirdAmbiente.Versao25;

    if VersaoFB25 <> EmptyStr then
      LogTecnico('Firebird 2.5 encontrado. Versão: ' +
        VersaoFB25 + '.', clGray)
    else
      LogTecnico('Instalações da família Firebird 2.5 encontradas.',
        clGray);

    RemoverTodasInstalacoesFirebird25;
  end
  else
  begin
    LogFirebird(
      'Nenhuma instalação da família Firebird 2.5 encontrada. Continuando...',
      clAqua);
  end;

  // instala o oficial (se preciso), registra e inicia o servico do Firebird 5
  GarantirServidorFirebird5(InstallerFB5);
end;

procedure TFormPrincipal.LogTecnico(const Texto: string; Cor: TColor);
var
  Linha: string;
begin
  Linha := '[' + FormatDateTime('hh:nn:ss', Now) + '] ' + Texto;
  TConsole.InserirLinha(reLogTecnico, Linha, Cor);
  // 09/10/2026: o tecnico vai so para o arquivo tecnico
  GravarLogTecnicoArquivo(Linha);
  Application.ProcessMessages;
end;

procedure TFormPrincipal.LogFirebird(const Texto: string; Cor: TColor);
var
  Linha: string;
begin
  Linha := '[' + FormatDateTime('hh:nn:ss', Now) + '] ' + Texto;
  TConsole.InserirLinha(reLog, Linha, Cor);
  GravarLogProcesso(Linha);
  // 09/10/2026: o arquivo tecnico tem a cronologia completa
  GravarLogTecnicoArquivo(Linha);
  StatusBarProcesso.SimpleText := Texto;
  Application.ProcessMessages;
end;

procedure TFormPrincipal.ExecutarInstalacaoFirebird(const Versao5: Boolean);
var
  NomeFirebird: string;
  Instalador: string;
  VersaoInstalada: string;
  Mensagem: string;
  JaInstalado: Boolean;
  OutraVersaoPresente: Boolean;
  Inicio: UInt64;
  CursorAnterior: TCursor;
begin
  if FProcessoEmAndamento then
  begin
    TMensagens.Aviso(SMsgProcessoEmAndamento);
    Exit;
  end;

  if Versao5 then
    NomeFirebird := 'Firebird 5'
  else
    NomeFirebird := 'Firebird 2.5';

  CursorAnterior := Screen.Cursor;
  FProcessoEmAndamento := True;
  try
    try
      if Versao5 then
        JaInstalado := TFirebirdAmbiente.Firebird5Instalado
      else
      begin
        JaInstalado := TFirebirdAmbiente.Executavel25 <> EmptyStr;
        // 15/10/2026: so sobraram arquivos (sem o servico do 2.5): reinstala por cima
        if JaInstalado and Firebird25SoSobras then
        begin
          LogFirebird('Firebird 2.5 encontrado sem o serviço ' + C_SERVICO_FB25 + ' (' +
            TFirebirdAmbiente.Executavel25 + '): sobra de uma remoção anterior. Será ' +
            'reinstalado por cima.', clYellow);
          JaInstalado := False;
        end;
      end;

      if JaInstalado then
      begin
        Mensagem := NomeFirebird + ' já está instalado.';
        LogFirebird(Mensagem, clAqua);
        TMensagens.Informacao(Mensagem);
        Exit;
      end;

      if Versao5 then
        OutraVersaoPresente := TFirebirdInstalacoes.ExisteFamilia25
      else
        OutraVersaoPresente := TFirebirdAmbiente.Firebird5Instalado;

      if OutraVersaoPresente then
      begin
        if Versao5 then
          Mensagem := 'Foi encontrado Firebird 2.5. Use a opção ' +
            '"Remover Firebird 2.5 e reinstalar Firebird 5".'
        else
          Mensagem := 'Foi encontrado Firebird 5. Use a opção ' +
            '"Remover Firebird 5 e reinstalar Firebird 2.5".';
        LogFirebird(Mensagem, clYellow);
        TMensagens.Aviso(Mensagem);
        Exit;
      end;

      if not TMensagens.ConfirmarContinuacao(
        'Esta ferramenta instalará o ' + NomeFirebird + '.') then
        Exit;

      Screen.Cursor := crHourGlass;
      Inicio := GetTickCount64;
      LogFirebird('Instalação isolada do ' + NomeFirebird +
        ' iniciada.', clAqua);
      LogFirebird('Arquitetura do Windows: ' +
        TFirebirdAmbiente.ArquiteturaWindows + '.', clAqua);

      if Versao5 then
        Instalador := TFirebirdPacotes.ObterInstalador5(
          LogFirebird, LogTecnico, AtualizarStatus)
      else
        Instalador := TFirebirdPacotes.ObterInstalador25(
          LogFirebird, LogTecnico, AtualizarStatus);

      if not FileExists(Instalador) then
        raise Exception.Create('Instalador do ' + NomeFirebird +
          ' não encontrado: ' + Instalador);

      LogFirebird('Instalando ' + NomeFirebird + '...', clYellow);
      if not RunAndWait(Instalador,
        '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /FORCE') then
        raise Exception.Create('Falha ao instalar o ' + NomeFirebird +
          '. ' + TProcessoWindows.UltimoErro);

      if Versao5 then
      begin
        JaInstalado := TFirebirdAmbiente.Firebird5Instalado;
        VersaoInstalada := TFirebirdAmbiente.Versao5;
      end
      else
      begin
        JaInstalado := TFirebirdAmbiente.Executavel25 <> EmptyStr;
        VersaoInstalada := TFirebirdAmbiente.Versao25;
      end;

      if not JaInstalado then
        raise Exception.Create('O instalador terminou, mas o executável do ' +
          NomeFirebird + ' não foi encontrado. Verifique a instalação.');

      // 15/10/2026: reinstalacao sobre sobra so vale com o servico do 2.5 de volta
      if (not Versao5) and Firebird25SoSobras then
        raise Exception.Create('O instalador terminou, mas o serviço ' + C_SERVICO_FB25 +
          ' do Firebird 2.5 não foi criado. Verifique a instalação.');

      if VersaoInstalada <> EmptyStr then
        LogFirebird('Versão detectada: ' + VersaoInstalada + '.', clLime);
      LogFirebird('Instalação do ' + NomeFirebird + ' concluída em ' +
        FormatDuration(GetTickCount64 - Inicio) + '.', clLime);
      TMensagens.Sucesso(NomeFirebird + ' instalado com sucesso.');
    except
      on E: Exception do
      begin
        LogFirebird('Erro ao instalar ' + NomeFirebird + ': ' +
          E.Message, clRed);
        AtualizarStatus('Erro ao instalar ' + NomeFirebird + '.');
        TMensagens.Excecao('Não foi possível instalar o ' + NomeFirebird +
          '.', E);
      end;
    end;
  finally
    Screen.Cursor := CursorAnterior;
    FProcessoEmAndamento := False;
  end;
end;

procedure TFormPrincipal.popupInstalarFB5Click(Sender: TObject);
begin
  ExecutarInstalacaoFirebird(True);
end;

procedure TFormPrincipal.popupInstalarFB25Click(Sender: TObject);
begin
  ExecutarInstalacaoFirebird(False);
end;

procedure TFormPrincipal.popupRemoverFB2_5_E_Instalar_5ClickClick(
  Sender: TObject);
begin
  if FProcessoEmAndamento then
  begin
    TMensagens.Aviso(SMsgProcessoEmAndamento);
    Exit;
  end;

  if not TMensagens.ConfirmarContinuacao(
    'Esta etapa removerá o Firebird 2.5 e instalará o Firebird 5.') then
    Exit;

  FProcessoEmAndamento := True;
  try
    ExecutarEtapaAtualizacaoFirebird;
    if FUltimaEtapaExecutadaComSucesso then
      AvisarConclusao(SMsgFirebirdAtualizado);
  finally
    FProcessoEmAndamento := False;
  end;
end;

procedure TFormPrincipal.popupRemoverFB5_E_Instalar_2_5ClickClick(
  Sender: TObject);
begin
  if FProcessoEmAndamento then
  begin
    TMensagens.Aviso(SMsgProcessoEmAndamento);
    Exit;
  end;

  if not TMensagens.ConfirmarContinuacaoAtencao(
    'Esta ferramenta removerá o Firebird 5 e reinstalará o Firebird 2.5.') then
    Exit;

  FProcessoEmAndamento := True;
  try
    ExecutarEtapaInstalacaoFirebird25;
    if FUltimaEtapaExecutadaComSucesso then
      TMensagens.Sucesso(SMsgFirebird25Instalado);
  finally
    FProcessoEmAndamento := False;
  end;
end;

procedure TFormPrincipal.popupRemoverSomenteFB5Click(Sender: TObject);
var
  Inicio: UInt64;
begin
  if FProcessoEmAndamento then
  begin
    TMensagens.Aviso(SMsgProcessoEmAndamento);
    Exit;
  end;

  if not TMensagens.ConfirmarContinuacaoAtencao(
    'Esta ferramenta removerá somente o Firebird 5.' +
    sLineBreak + 'Nenhuma outra versão será instalada em seguida.') then
    Exit;

  Inicio := GetTickCount64;
  FProcessoEmAndamento := True;
  Screen.Cursor := crHourGlass;
  try
    try
      LogFirebird('Remoção isolada do Firebird 5 iniciada.', clAqua);
      RemoverInstalacaoFirebird5;
      LogFirebird('Remoção isolada do Firebird 5 finalizada em ' +
        FormatDuration(GetTickCount64 - Inicio) + '.', clLime);
      StatusBarProcesso.SimpleText := 'Remoção do Firebird 5 concluída.';
      TMensagens.Sucesso(SMsgRemocaoFirebird5Concluida);
    except
      on E: Exception do
      begin
        LogFirebird('Erro ao remover Firebird 5: ' + E.Message, clRed);
        StatusBarProcesso.SimpleText := 'Erro ao remover Firebird 5.';
        TMensagens.Excecao('Não foi possível remover o Firebird 5.', E);
      end;
    end;
  finally
    Screen.Cursor := crDefault;
    FProcessoEmAndamento := False;
  end;
end;

procedure TFormPrincipal.popupRemoverSomenteFB25Click(Sender: TObject);
var
  Inicio: UInt64;
begin
  if FProcessoEmAndamento then
  begin
    TMensagens.Aviso(SMsgProcessoEmAndamento);
    Exit;
  end;

  if not TMensagens.ConfirmarContinuacaoAtencao(
    'Esta ferramenta removerá todas as instalações da família Firebird 2.5.' +
    sLineBreak + 'Nenhuma outra versão será instalada em seguida.') then
    Exit;

  Inicio := GetTickCount64;
  FProcessoEmAndamento := True;
  Screen.Cursor := crHourGlass;
  try
    try
      LogFirebird(
        'Remoção isolada da família Firebird 2.5 iniciada.', clAqua);
      RemoverTodasInstalacoesFirebird25;
      LogFirebird(
        'Remoção isolada da família Firebird 2.5 finalizada em ' +
        FormatDuration(GetTickCount64 - Inicio) + '.', clLime);
      StatusBarProcesso.SimpleText :=
        'Remoção da família Firebird 2.5 concluída.';
      TMensagens.Sucesso(SMsgRemocaoFirebird25Concluida);
    except
      on E: Exception do
      begin
        LogFirebird('Erro ao remover Firebird 2.5: ' +
          E.Message, clRed);
        StatusBarProcesso.SimpleText := 'Erro ao remover Firebird 2.5.';
        TMensagens.Excecao('Não foi possível remover o Firebird 2.5.', E);
      end;
    end;
  finally
    Screen.Cursor := crDefault;
    FProcessoEmAndamento := False;
  end;
end;

end.
