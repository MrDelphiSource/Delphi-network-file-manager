object Form1: TForm1
  AlignWithMargins = True
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'File Manager - Client (created by MrDelphiSource) 2025'
  ClientHeight = 123
  ClientWidth = 381
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = RUSSIAN_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Verdana'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 16
  object Label1: TLabel
    Left = 8
    Top = 16
    Width = 30
    Height = 16
    Caption = 'Host'
  end
  object Label2: TLabel
    Left = 8
    Top = 48
    Width = 27
    Height = 16
    Caption = 'Port'
  end
  object Label3: TLabel
    Left = 8
    Top = 96
    Width = 52
    Height = 16
    Caption = 'STATUS'
  end
  object Edit1: TEdit
    Left = 44
    Top = 13
    Width = 173
    Height = 24
    TabOrder = 0
    Text = '127.0.0.1'
  end
  object SpinEdit1: TSpinEdit
    Left = 44
    Top = 43
    Width = 121
    Height = 26
    MaxLength = 5
    MaxValue = 65535
    MinValue = 1
    TabOrder = 1
    Value = 3434
  end
  object Button1: TButton
    Left = 184
    Top = 43
    Width = 143
    Height = 25
    Caption = 'Connect'
    TabOrder = 2
    OnClick = Button1Click
  end
  object ClientSocket: TncClientSource
    EncryptionKey = 'SetEncryptionKey'
    OnConnected = ClientSocketConnected
    OnDisconnected = ClientSocketDisconnected
    OnHandleCommand = ClientSocketHandleCommand
    Host = 'LocalHost'
    Left = 296
    Top = 8
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 4000
    OnTimer = Timer1Timer
    Left = 256
    Top = 8
  end
end
