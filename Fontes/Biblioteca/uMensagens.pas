unit uMensagens;

interface

uses
  System.SysUtils;

resourcestring
  SMsgProcessoEmAndamento = 'Aguarde a conclusão do processo atual.';
  SMsgDesejaContinuar = 'Deseja continuar?';
  SMsgDesejaIniciarAgora = 'Deseja iniciar agora?';
  SMsgBancoDadosNaoEncontrado = 'Banco de dados não encontrado. Verifique se o MigraFacil.exe está ao lado do Gestão.exe, pois ele precisa acessar o Config.ini.';
  SMsgMigracaoInterrompidaBackup = 'A migração foi interrompida na etapa de backup. Consulte o log do processo.';
  SMsgMigracaoInterrompidaAtualizacao = 'A migração foi interrompida na atualização do Firebird. Consulte o log do processo.';
  SMsgMigracaoInterrompidaConversao = 'A migração foi interrompida na conversão do banco. Consulte o log do processo.';
  SMsgMigracaoConcluida = 'Migração concluída com sucesso.';
  SMsgBackupConcluido = 'Backup finalizado com sucesso.';
  SMsgBackupObrigatorio = 'Faça a etapa 1 e conclua o backup antes de atualizar o Firebird.';
  SMsgFirebirdAtualizado = 'Firebird atualizado com sucesso.';
  SMsgRestoreConcluido = 'Restore finalizado com sucesso.';
  SMsgFirebird25Instalado = 'Firebird 2.5 instalado com sucesso.';
  SMsgRemocaoFirebird5Concluida = 'Remoção do Firebird 5 concluída.';
  SMsgRemocaoFirebird25Concluida = 'Remoção da família Firebird 2.5 concluída.';
  // 09/10/2026: mensagem final conforme o resultado da reabertura do banco
  SMsgBancoContinuaFechado = 'ATENÇÃO: o banco de dados CONTINUA FECHADO e o Gestão NÃO conecta em nenhuma estação.' + #13#10#13#10 +
    'O que fazer: reinicie o Windows do servidor e execute o MigraFacil de novo para retomar a migração de onde parou; ' +
    'ou, para voltar ao Firebird 2.5, use a opção "Remover Firebird 5 e reinstalar Firebird 2.5" (Instalar / Remover Firebird), ' +
    'que reabre o banco original.';
  SMsgBancoReaberto25 = 'O banco de dados foi reaberto e o Gestão volta a funcionar no Firebird 2.5.';

type
  TMensagens = class
  private
    class procedure Exibir(const Texto: string; const Icone: Cardinal); static;
  public
    class procedure Informacao(const Texto: string); static;
    class procedure Sucesso(const Texto: string); static;
    class procedure Aviso(const Texto: string); static;
    class procedure Erro(const Texto: string); static;
    class procedure Excecao(const Contexto: string; const E: Exception); static;
    class function Confirmar(const Texto: string): Boolean; static;
    class function ConfirmarAtencao(const Texto: string): Boolean; static;
    class function ConfirmarInicio(const Texto: string): Boolean; static;
    class function ConfirmarContinuacao(const Texto: string): Boolean; static;
    class function ConfirmarContinuacaoAtencao(
      const Texto: string): Boolean; static;
  end;

implementation

uses
  Vcl.Forms, Winapi.Windows, uConst;

class procedure TMensagens.Exibir(const Texto: string; const Icone: Cardinal);
begin
  Application.MessageBox(PChar(Texto), PChar(MSG_CAPTION), MB_OK or Icone);
end;

class procedure TMensagens.Informacao(const Texto: string);
begin
  Exibir(Texto, MB_ICONINFORMATION);
end;

class procedure TMensagens.Sucesso(const Texto: string);
begin
  Exibir(Texto, MB_ICONINFORMATION);
end;

class procedure TMensagens.Aviso(const Texto: string);
begin
  Exibir(Texto, MB_ICONWARNING);
end;

class procedure TMensagens.Erro(const Texto: string);
begin
  Exibir(Texto, MB_ICONERROR);
end;

class procedure TMensagens.Excecao(const Contexto: string; const E: Exception);
begin
  Erro(Contexto + sLineBreak + sLineBreak + E.Message);
end;

class function TMensagens.Confirmar(const Texto: string): Boolean;
begin
  Result := Application.MessageBox(PChar(Texto), PChar(MSG_CAPTION),
    MB_YESNO or MB_ICONQUESTION) = IDYES;
end;

class function TMensagens.ConfirmarAtencao(const Texto: string): Boolean;
begin
  Result := Application.MessageBox(PChar(Texto), PChar(MSG_CAPTION),
    MB_YESNO or MB_ICONWARNING) = IDYES;
end;

class function TMensagens.ConfirmarInicio(const Texto: string): Boolean;
begin
  Result := Confirmar(Texto + sLineBreak + sLineBreak +
    SMsgDesejaIniciarAgora);
end;

class function TMensagens.ConfirmarContinuacao(const Texto: string): Boolean;
begin
  Result := Confirmar(Texto + sLineBreak + sLineBreak +
    SMsgDesejaContinuar);
end;

class function TMensagens.ConfirmarContinuacaoAtencao(
  const Texto: string): Boolean;
begin
  Result := ConfirmarAtencao(Texto + sLineBreak + sLineBreak +
    SMsgDesejaContinuar);
end;
end.