unit menu;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, XData.Server.Module,
  Sparkle.Comp.Server,
  Sparkle.Comp.CorsMiddleware, XData.Comp.Server,
  Sparkle.Comp.HttpSysDispatcher, Vcl.StdCtrls, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client,FireDAC.DApt,FireDAC.Phys.MySQL,
  Sparkle.HttpServer.Module, Sparkle.HttpServer.Context, FireDAC.Phys.MySQLDef,IniFiles;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Edit1: TEdit;
    SparkleHttpSysDispatcher1: TSparkleHttpSysDispatcher;
    XDataServer1: TXDataServer;
    XDataServer1CORS: TSparkleCorsMiddleware;
    FDPhysMySQLDriverLink1: TFDPhysMySQLDriverLink;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;cliqueNfe: Integer;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
 var
 ArqIni : TIniFile;
begin
   try
    ArqIni := TIniFile.Create('./config.ini');
    //http://api.kinotas.com.br/v2//  - SERVIDOR DE PRODUÇÃO  *DEIXAR NO CAMPO BaseUrl//
    //http://api.kinotas.com.br/hom // - SERVIDOR DE HOMOLOGAÇÃO
    XDataServer1.BaseUrl :=  ArqIni.ReadString('configuracoes', 'host', '') + '/nfce';
    SparkleHttpSysDispatcher1.Active := True;
   finally
     ArqIni.Free;
   end;

end;

end.
