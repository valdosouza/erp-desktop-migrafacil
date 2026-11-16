# MigraFacil

Converte o banco de dados do Gestão ERP (desktop) do Firebird 2.5 para o Firebird 5.0, com pré-requisitos, backup,
validação da conversão, retomada e volta guiada.

## Compilar

- Delphi 10.2 Tokyo, Win32, configuração Release.
- O projeto usa as units comuns do Gestão em `..\erp-desktop\Comum\Firebird\`: a pasta `erp-desktop` (ERP Desktop) precisa
  estar ao lado desta.
- Linha de comando:

  ```bat
  call "C:\Program Files (x86)\Embarcadero\Studio\19.0\bin\rsvars.bat"
  msbuild MigraFacil.dproj /t:Rebuild /p:Config=Release /p:Platform=Win32
  ```

- O executável sai em `D:\Modelos\Gestao2026\Bin\MigraFacil.exe`.

## Origem

Código vindo do SVN do Gestão, `Gestao/branches/Gestao2016/MigraFacil`, revisão r1408. A história anterior continua no SVN;
este repositório começa com o código atual.
