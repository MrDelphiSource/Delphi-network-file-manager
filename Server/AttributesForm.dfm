object Form3: TForm3
  AlignWithMargins = True
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'Attributes'
  ClientHeight = 146
  ClientWidth = 540
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = RUSSIAN_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Verdana'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnShow = FormShow
  TextHeight = 14
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 540
    Height = 146
    Align = alClient
    TabOrder = 0
    ExplicitWidth = 534
    ExplicitHeight = 141
    object Label1: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 532
      Height = 14
      Align = alTop
      Alignment = taCenter
      Caption = 'FILENAME'
      WordWrap = True
      ExplicitWidth = 62
    end
    object CheckBox1: TCheckBox
      Left = 16
      Top = 66
      Width = 97
      Height = 17
      Caption = 'Read only'
      TabOrder = 0
      OnClick = CheckBox1Click
    end
    object CheckBox2: TCheckBox
      Left = 119
      Top = 66
      Width = 97
      Height = 17
      Caption = 'Hidden'
      TabOrder = 1
      OnClick = CheckBox2Click
    end
    object CheckBox3: TCheckBox
      Left = 222
      Top = 66
      Width = 97
      Height = 17
      Caption = 'System'
      TabOrder = 2
      OnClick = CheckBox3Click
    end
    object CheckBox4: TCheckBox
      Left = 325
      Top = 66
      Width = 97
      Height = 17
      Caption = 'Archive'
      TabOrder = 3
      OnClick = CheckBox4Click
    end
    object CheckBox5: TCheckBox
      Left = 425
      Top = 66
      Width = 111
      Height = 17
      Caption = 'No attributes'
      TabOrder = 4
      OnClick = CheckBox5Click
    end
    object Button1: TButton
      Left = 280
      Top = 112
      Width = 129
      Height = 25
      Caption = 'Apply attributes'
      TabOrder = 5
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 425
      Top = 112
      Width = 96
      Height = 25
      Caption = 'Cancel'
      TabOrder = 6
      OnClick = Button2Click
    end
  end
end
