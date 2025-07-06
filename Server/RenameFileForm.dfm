object Form2: TForm2
  AlignWithMargins = True
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'Rename file'
  ClientHeight = 149
  ClientWidth = 424
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = RUSSIAN_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Verdana'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 14
  object Panel1: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 418
    Height = 143
    Align = alClient
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 56
      Width = 66
      Height = 18
      Caption = 'Rename '
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Verdana'
      Font.Style = []
      ParentFont = False
    end
    object Edit1: TEdit
      Left = 121
      Top = 56
      Width = 280
      Height = 22
      MaxLength = 254
      TabOrder = 0
    end
    object Button1: TButton
      Left = 200
      Top = 104
      Width = 97
      Height = 25
      Caption = 'OK'
      TabOrder = 1
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 312
      Top = 104
      Width = 97
      Height = 25
      Caption = 'Cancel'
      TabOrder = 2
      OnClick = Button2Click
    end
  end
end
