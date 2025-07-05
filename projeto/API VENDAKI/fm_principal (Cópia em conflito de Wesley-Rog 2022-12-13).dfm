object principal: Tprincipal
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Servidor - Vendaki'
  ClientHeight = 345
  ClientWidth = 909
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 64
    Top = 107
    Width = 281
    Height = 57
    Caption = 'LIGAR SERVIDOR'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 909
    Height = 73
    Align = alTop
    BevelOuter = bvNone
    Caption = 'Servidor ligado'
    Color = 16770250
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 16744448
    Font.Height = -40
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentBackground = False
    ParentFont = False
    TabOrder = 1
    ExplicitWidth = 689
  end
  object Edit1: TEdit
    Left = 64
    Top = 296
    Width = 281
    Height = 21
    TabOrder = 2
    Text = 'http://localhost:2001/SwaggerUI'
  end
  object WebBrowser1: TWebBrowser
    Left = 379
    Top = 79
    Width = 326
    Height = 238
    TabOrder = 3
    OnDocumentComplete = WebBrowser1DocumentComplete
    ControlData = {
      4C000000B1210000991800000000000000000000000000000000000000000000
      000000004C000000000000000000000001000000E0D057007335CF11AE690800
      2B2E12620F000000000000004C0000000114020000000000C000000000000046
      8000000000000000000000000000000000000000000000000000000000000000
      00000000000000000100000000000000000000000000000000000000}
  end
  object Timer1: TTimer
    Interval = 1
    OnTimer = Timer1Timer
    Left = 166
    Top = 193
  end
  object SparkleHttpSysDispatcher1: TSparkleHttpSysDispatcher
    Left = 216
    Top = 224
  end
  object XDataServer1: TXDataServer
    Dispatcher = SparkleHttpSysDispatcher1
    EntitySetPermissions = <>
    SwaggerOptions.Enabled = True
    SwaggerOptions.AuthMode = Jwt
    SwaggerUIOptions.Enabled = True
    SwaggerUIOptions.ShowFilter = True
    SwaggerUIOptions.DocExpansion = None
    Left = 104
    Top = 240
    object XDataServer1CORS: TSparkleCorsMiddleware
    end
  end
  object FDPhysMySQLDriverLink1: TFDPhysMySQLDriverLink
    Left = 40
    Top = 168
  end
end
