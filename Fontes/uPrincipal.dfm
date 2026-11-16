object FormPrincipal: TFormPrincipal
  Left = 0
  Top = 0
  Caption = 'MigraFacil - Migra'#231#227'o assistida Firebird 2.5 para Firebird 5'
  ClientHeight = 768
  ClientWidth = 1024
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pgcPrincipal: TPageControl
    Left = 0
    Top = 0
    Width = 1024
    Height = 749
    ActivePage = tabFerramentas
    Align = alClient
    TabOrder = 0
    object tabMigracao: TTabSheet
      Caption = 'Migra'#231#227'o'
      object gbxConfigIni: TGroupBox
        Left = 0
        Top = 0
        Width = 1016
        Height = 65
        Align = alTop
        Caption = 'Arquivo [Config.ini]'
        TabOrder = 0
        DesignSize = (
          1016
          65)
        object edtDatabase: TLabeledEdit
          Left = 10
          Top = 35
          Width = 711
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          EditLabel.Width = 193
          EditLabel.Height = 13
          EditLabel.Caption = 'Caminho do Banco de Dados [Database]'
          ParentShowHint = False
          ShowHint = False
          TabOrder = 0
        end
        object btnProcurarBanco: TButton
          Left = 731
          Top = 33
          Width = 125
          Height = 25
          Anchors = [akTop, akRight]
          Caption = 'Procurar...'
          TabOrder = 1
          OnClick = btnProcurarBancoClick
        end
        object btnSalvarBanco: TButton
          Left = 866
          Top = 33
          Width = 135
          Height = 25
          Anchors = [akTop, akRight]
          Caption = 'Salvar no Config.ini'
          TabOrder = 2
          OnClick = btnSalvarBancoClick
        end
      end
      object gbxAcoes: TGroupBox
        Left = 0
        Top = 65
        Width = 1016
        Height = 67
        Align = alTop
        Caption = 'Clique aqui para iniciar a migra'#231#227'o'
        TabOrder = 1
        object btnIniciarMigracao: TButton
          Left = 10
          Top = 20
          Width = 260
          Height = 40
          Caption = 'Iniciar migra'#231#227'o assistida'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ImageIndex = 59
          ParentFont = False
          TabOrder = 0
          OnClick = btnIniciarMigracaoClick
        end
      end
      object pnlLog: TPanel
        Left = 0
        Top = 132
        Width = 1016
        Height = 589
        Align = alClient
        TabOrder = 2
        object gbxLog: TGroupBox
          Left = 1
          Top = 1
          Width = 1014
          Height = 587
          Align = alClient
          Caption = 'Log do processo'
          TabOrder = 0
          object reLog: TRichEdit
            Left = 2
            Top = 15
            Width = 1010
            Height = 570
            Align = alClient
            Color = 4473924
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            ScrollBars = ssBoth
            TabOrder = 0
            Zoom = 100
          end
        end
      end
    end
    object tabFerramentas: TTabSheet
      Caption = 'Ferramentas de suporte'
      ImageIndex = 1
      object gbxDiagnostico: TGroupBox
        Left = 0
        Top = 0
        Width = 1016
        Height = 161
        Align = alTop
        Caption = 'Etapas migra'#231#227'o manual'
        TabOrder = 0
        object btnBackup: TButton
          Left = 10
          Top = 20
          Width = 260
          Height = 40
          Caption = '1. Fazer backup de seguran'#231'a'
          ImageIndex = 14
          TabOrder = 0
          OnClick = btnBackupClick
        end
        object btnAtualizarFB2_5_E_Instalar_5: TButton
          Left = 10
          Top = 66
          Width = 260
          Height = 40
          Caption = '2. Atualizar Firebird 2.5 para Firebird 5'
          ImageIndex = 47
          TabOrder = 1
          OnClick = btnAtualizarFB2_5_E_Instalar_5Click
        end
        object btnRestore: TButton
          Left = 10
          Top = 113
          Width = 260
          Height = 40
          Caption = '3. Converter e substituir o banco de dados'
          ImageIndex = 15
          TabOrder = 2
          OnClick = btnRestoreClick
        end
      end
      object gbxFerramentas: TGroupBox
        Left = 0
        Top = 161
        Width = 1016
        Height = 208
        Align = alTop
        Caption = 'Ferramentas'
        TabOrder = 1
        ExplicitTop = 159
        object btnTestarConexao: TButton
          Left = 10
          Top = 20
          Width = 260
          Height = 40
          Caption = 'Testar conex'#227'o com o banco'
          ImageIndex = 67
          TabOrder = 0
          OnClick = btnTestarConexaoClick
        end
        object btn_DetectarVersaoFB: TButton
          Left = 10
          Top = 66
          Width = 260
          Height = 40
          Caption = 'Detectar vers'#227'o do Firebird'
          ImageIndex = 70
          TabOrder = 1
          OnClick = btn_DetectarVersaoFBClick
        end
        object btnRestaurarFbkFB5: TButton
          Left = 10
          Top = 158
          Width = 260
          Height = 40
          Caption = 'Restaurar backup (.fbk) no Firebird 5'
          TabOrder = 3
          OnClick = btnRestaurarFbkFB5Click
        end
        object btnLimparLogs: TButton
          Left = 10
          Top = 112
          Width = 260
          Height = 40
          Caption = 'Limpar Logs'
          ImageIndex = 6
          PopupMenu = PopupMenuRemoverFB
          TabOrder = 2
          OnClick = btnLimparLogsClick
        end
      end
      object gbxInstalarRemover: TGroupBox
        Left = 0
        Top = 369
        Width = 1016
        Height = 162
        Align = alTop
        Caption = 'Instalar / Remover Firebird'
        TabOrder = 2
        object btnRemoverFB5_E_Instalar_2_5Click: TButton
          Left = 10
          Top = 18
          Width = 260
          Height = 40
          Caption = 'Remover Firebird 5 e reinstalar Firebird 2.5'
          DropDownMenu = PopupMenuRemoverFB
          ImageIndex = 6
          PopupMenu = PopupMenuRemoverFB
          TabOrder = 0
          OnClick = popupRemoverFB5_E_Instalar_2_5ClickClick
        end
        object btnRemoverFB2_5_E_Instalar_5Click: TButton
          Left = 276
          Top = 18
          Width = 260
          Height = 40
          Caption = 'Remover Firebird 2.5 e reinstalar Firebird 5'
          DropDownMenu = PopupMenuRemoverFB
          ImageIndex = 6
          PopupMenu = PopupMenuRemoverFB
          TabOrder = 1
          OnClick = popupRemoverFB2_5_E_Instalar_5ClickClick
        end
        object btnRemoverSomenteFB5: TButton
          Left = 10
          Top = 64
          Width = 260
          Height = 40
          Caption = 'Remover o Firebird 5'
          DropDownMenu = PopupMenuRemoverFB
          ImageIndex = 6
          PopupMenu = PopupMenuRemoverFB
          TabOrder = 2
          OnClick = popupRemoverSomenteFB5Click
        end
        object btnRemoverSomenteFB25: TButton
          Left = 276
          Top = 64
          Width = 260
          Height = 40
          Caption = 'Remover o Firebird 2.5'
          DropDownMenu = PopupMenuRemoverFB
          ImageIndex = 6
          PopupMenu = PopupMenuRemoverFB
          TabOrder = 3
          OnClick = popupRemoverSomenteFB25Click
        end
        object btnInstalarFB5: TButton
          Left = 10
          Top = 110
          Width = 260
          Height = 40
          Caption = 'Instalar o Firebird 5'
          DropDownMenu = PopupMenuRemoverFB
          ImageIndex = 6
          PopupMenu = PopupMenuRemoverFB
          TabOrder = 4
          OnClick = popupInstalarFB5Click
        end
        object btnInstalarFB25: TButton
          Left = 276
          Top = 110
          Width = 260
          Height = 40
          Caption = 'Instalar o Firebird 2.5'
          DropDownMenu = PopupMenuRemoverFB
          ImageIndex = 6
          PopupMenu = PopupMenuRemoverFB
          TabOrder = 5
          OnClick = popupInstalarFB25Click
        end
      end
    end
    object tabLogTecnico: TTabSheet
      Caption = 'Log t'#233'cnico'
      ImageIndex = 2
      object gbxLogTecnico: TGroupBox
        Left = 0
        Top = 0
        Width = 1016
        Height = 721
        Align = alClient
        Caption = 'Log t'#233'cnico'
        TabOrder = 0
        object reLogTecnico: TRichEdit
          Left = 2
          Top = 15
          Width = 1012
          Height = 704
          Align = alClient
          Color = 4473924
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ScrollBars = ssBoth
          TabOrder = 0
          Zoom = 100
        end
      end
    end
  end
  object StatusBarProcesso: TStatusBar
    Left = 0
    Top = 749
    Width = 1024
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object PopupMenuRemoverFB: TPopupMenu
    Left = 572
    Top = 465
    object popupRemoverFB5_E_Instalar_2_5Click: TMenuItem
      Caption = 'Remover Firebird 5 e reinstalar Firebird 2.5'
      OnClick = popupRemoverFB5_E_Instalar_2_5ClickClick
    end
    object popupRemoverFB2_5_E_Instalar_5Click: TMenuItem
      Caption = 'Remover Firebird 2.5 e reinstalar Firebird 5'
      OnClick = popupRemoverFB2_5_E_Instalar_5ClickClick
    end
    object menuSeparadorRemocao: TMenuItem
      Caption = '-'
    end
    object popupRemoverSomenteFB5: TMenuItem
      Caption = 'Remover o Firebird 5'
      OnClick = popupRemoverSomenteFB5Click
    end
    object popupRemoverSomenteFB25: TMenuItem
      Caption = 'Remover o Firebird 2.5'
      OnClick = popupRemoverSomenteFB25Click
    end
    object menuSeparadorInstalacao: TMenuItem
      Caption = '-'
    end
    object popupInstalarFB5: TMenuItem
      Caption = 'Instalar o Firebird 5'
      OnClick = popupInstalarFB5Click
    end
    object popupInstalarFB25: TMenuItem
      Caption = 'Instalar o Firebird 2.5'
      OnClick = popupInstalarFB25Click
    end
  end
end
