program MigraFacil;

uses
  Vcl.Forms,
  System.SysUtils, System.Classes, System.IOUtils,
  uPrincipal in 'Fontes\uPrincipal.pas' {FormPrincipal},
  uTesteConexao in 'Fontes\Biblioteca\uTesteConexao.pas',
  uSegurancaFirebird5 in '..\erp-desktop\Comum\Firebird\uSegurancaFirebird5.pas',
  uFbClientAutomatico in 'Fontes\Biblioteca\uFbClientAutomatico.pas',
  uConfigIni in 'Fontes\Biblioteca\uConfigIni.pas',
  uConst in 'Fontes\Biblioteca\uConst.pas',
  uMensagens in 'Fontes\Biblioteca\uMensagens.pas',
  uFirebirdAmbiente in '..\erp-desktop\Comum\Firebird\uFirebirdAmbiente.pas',
  uFirebirdPacotes in 'Fontes\Biblioteca\uFirebirdPacotes.pas',
  uGestaoAtualizacao in 'Fontes\Biblioteca\uGestaoAtualizacao.pas',
  uFirebirdInstalacoes in 'Fontes\Biblioteca\uFirebirdInstalacoes.pas',
  uFirebirdServicos in '..\erp-desktop\Comum\Firebird\uFirebirdServicos.pas',
  uFuncoes in 'Fontes\Biblioteca\uFuncoes.pas',
  uMigracaoContratos in '..\erp-desktop\Comum\Firebird\uMigracaoContratos.pas',
  uProcessoWindows in '..\erp-desktop\Comum\Firebird\uProcessoWindows.pas',
  uPreRequisitosConversao in 'Fontes\Biblioteca\uPreRequisitosConversao.pas',
  uValidacaoConversao in 'Fontes\Biblioteca\uValidacaoConversao.pas',
  uFirebirdTuning in '..\erp-desktop\Comum\Firebird\uFirebirdTuning.pas',
  uMarcadorAtualizador in '..\erp-desktop\Comum\Firebird\uMarcadorAtualizador.pas',
  uGbakPadrao in '..\erp-desktop\Comum\Firebird\uGbakPadrao.pas';

{$R *.res}

var
  VersaoServidor: string;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  if (ParamCount >= 2) and SameText(ParamStr(1), '/testeconexao') then
  begin
    try
      // 3o parametro opcional: banco a testar (padrao: o do Config.ini)
      VersaoServidor := TTesteConexao.Executar(ParamStr(3));
      try
        // o MigraFacil le a versao do motor que respondeu neste arquivo
        TFile.WriteAllText(ParamStr(2), 'ENGINE=' + VersaoServidor, TEncoding.UTF8);
      except
        // sem o arquivo a versao fica desconhecida; a conexao em si deu certo
      end;
      Halt(0);
    except
      on E: Exception do
      begin
        try
          TFile.WriteAllText(ParamStr(2), E.Message, TEncoding.UTF8);
        except
          // O processo de teste deve terminar mesmo se o log falhar.
        end;
        Halt(1);
      end;
    end;
  end;
  Application.CreateForm(TFormPrincipal, FormPrincipal);
  Application.Run;
end.
