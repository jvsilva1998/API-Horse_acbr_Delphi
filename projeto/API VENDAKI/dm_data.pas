unit dm_data;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait,
  Data.DB, ECripto, FireDAC.Comp.Client, FireDAC.Phys.PG, FireDAC.DApt,
  FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.Phys.SQLite,
  FireDAC.Stan.ExprFuncs, Dialogs;

type
  Tdm_dados = class(TDataModule)
  private
    { Private declarations }
  public
   procedure abreConexao;



  end;

var
  dm_dados: Tdm_dados;

implementation
 

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

{ Tdm_dados }


 {ANTES DE SE CONECTAR}
procedure Tdm_dados.abreConexao;
 begin

 end;

end.
