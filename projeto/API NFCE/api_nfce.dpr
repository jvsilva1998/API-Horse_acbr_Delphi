program api_nfce;

uses
  Vcl.Forms,
  menu in 'menu.pas' {Form1},
  regras_nfe in 'regras\regras_nfe.pas',
  nfe in 'servicos\nfe.pas',
  funcoes in 'funcoes.pas',
  parametros in 'parametros.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
