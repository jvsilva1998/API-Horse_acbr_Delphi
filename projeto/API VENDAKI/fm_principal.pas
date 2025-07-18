unit fm_principal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  XData.Server.Module, Sparkle.Comp.Server, Sparkle.Comp.CorsMiddleware,
  Sparkle.Comp.HttpSysDispatcher, XData.Comp.Server,Sparkle.HttpSys.Config,XData.Aurelius.Model,
  FireDAC.Stan.Intf, FireDAC.Phys, FireDAC.Phys.MySQL,
  Sparkle.HttpServer.Module, Sparkle.HttpServer.Context, FireDAC.Phys.MySQLDef,IniFiles,
  Vcl.OleCtrls, SHDocVw,MSHTML;

type
  Tprincipal = class(TForm)
    Button1: TButton;
    Panel1: TPanel;
    Timer1: TTimer;
    SparkleHttpSysDispatcher1: TSparkleHttpSysDispatcher;
    XDataServer1: TXDataServer;
    XDataServer1CORS: TSparkleCorsMiddleware;
    Edit1: TEdit;
    MemoMunicipio: TMemo;
    FDPhysMySQLDriverLink1: TFDPhysMySQLDriverLink;
    WebBrowser1: TWebBrowser;
    procedure Timer1Timer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure WebBrowser1DocumentComplete(ASender: TObject;
      const pDisp: IDispatch; const URL: OleVariant);
  private

  public

    function retornaNCM(ean:string):string;

  end;

var
  principal: Tprincipal;cliqueIndicacao: Integer;

implementation

{$R *.dfm}

procedure Tprincipal.Button1Click(Sender: TObject);
 begin
     if SparkleHttpSysDispatcher1.Active  = true then
      begin
       SparkleHttpSysDispatcher1.Stop;
       SparkleHttpSysDispatcher1.Active := False;
      end else
            begin
              SparkleHttpSysDispatcher1.Start;
              SparkleHttpSysDispatcher1.Active := true;
            end;
 end;

procedure Tprincipal.FormCreate(Sender: TObject);
var
  CONFIG :  THttpSysServerConfig;
  ArqIni : TIniFile;
 begin
   cliqueIndicacao := 0;

   ArqIni := TIniFile.Create('./config.ini');
   //http://api.kinotas.com.br/v2//  - SERVIDOR DE PRODU��O  *DEIXAR NO CAMPO BaseUrl//
   //http://api.kinotas.com.br/hom // - SERVIDOR DE HOMOLOGA��O
   XDataServer1.BaseUrl :=  ArqIni.ReadString('configuracoes', 'host', '');

    try
       Config := THttpSysServerConfig.Create;
       try
        if not Config.IsUrlReserved(XDataServer1.BaseUrl) then
          Config.ReserveUrl(XDataServer1.BaseUrl,[TSidType.CurrentUser, TSidType.NetworkService]);
        finally
        Config.Free;
       end;
      TXDataAureliusModel.Default.Title   := 'API Kinotas';
      TXDataAureliusModel.Default.Version := '1.0' ;

//     XDataServer1.Model.Title := 'Mathematics API';
//     XDataServer1.Model.Version := '1.0';
//     XDataServer1.Model.Description :=
//     '### Overview'#13#10 +
//     'This is an API for **mathematical** operations. '#13#10 +
//     'Feel free to browse and execute several operations like *arithmetic* ' +
//     'and *trigonometric* functions'#13#10#13#10 +
//     '### More info'#13#10 +
//     'Build with [TMS XData](https://www.tmssoftware.com/site/xdata.asp), from ' +
//     '[TMS Software](https://www.tmssoftware.com).' +
//     'A Delphi framework for building REST servers'#13#10 +
//     '[![TMS Software](https://app.sistemavendaki.com.br/assets/media/image/logo.png)]' +
//     '(https://www.tmssoftware.com)';
    finally
      ArqIni.Free;
    end;

 end;

function Tprincipal.retornaNCM(ean: string): string;
 begin

    try
      WebBrowser1.Navigate2('https://cosmos.bluesoft.com.br/produtos/7897975034955');
    finally
      WebBrowser1DocumentComplete(Self,nil,'https://cosmos.bluesoft.com.br/produtos/7897975034955');
    end;

 end;

procedure Tprincipal.Timer1Timer(Sender: TObject);
 begin
   if SparkleHttpSysDispatcher1.Active = true then
      begin
        Panel1.Caption   := 'Servidor ligado';
        Button1.Caption  :=  'DESLIGAR SERVIDOR';
      end else
            begin
               Panel1.Caption   := 'Servidor desligado';
               Button1.Caption  :=  'LIGAR SERVIDOR';
            end;
 end;

procedure Tprincipal.WebBrowser1DocumentComplete(ASender: TObject; const pDisp: IDispatch; const URL: OleVariant);
  var
   doc3:IHTMLDocument3;
   t:string;
   h:string;
   j:string;
   ncm:string;
   i:Integer;
 begin

        if WebBrowser1.Document.QueryInterface(IHTMLDocument3, doc3) = S_OK then
        begin
          t := doc3.getElementById('search_ncm').getAttribute('data-description',0);
          h := doc3.getElementById('product_description').innerText;

          t := doc3.getElementById('search_ncm').getAttribute('data-description',0);
          ncm := t[1]+t[2]+t[3]+t[4]+t[5]+t[6]+t[7]+t[8]+t[9]+t[10]+t[11];
        end;


     try
       h := doc3.getElementById('product_description').innerText;
       showmessage('NOME PRODUTO ' + H);

      except
       showmessage('N�O ENCONTRADO');
     end;


     try
         t := doc3.getElementById('search_ncm').getAttribute('data-description',0);
         ncm := t[1]+t[2]+t[3]+t[4]+t[5]+t[6]+t[7]+t[8]+t[9]+t[10]+t[11];
         SHOWMESSAGE('NCM '+ NCM);
      except
        SHOWMESSAGE('NCM N�O ENCONTRADO');
     end;


      begin
        ShowMessage('Processo de busca finalizado, as imagens est�o na pasta "IMG" e foi gerado o excel na pasta raiz');
        Exit;
      end;

 end;

end.
