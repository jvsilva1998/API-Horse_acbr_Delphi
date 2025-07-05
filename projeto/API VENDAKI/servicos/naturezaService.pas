unit naturezaService;

interface

uses
  XData.Server.Module,
  XData.Service.Common,
  parametros,
  Json,
  funcoes,
  natureza,
  System.SysUtils;

type
  [ServiceContract]
  Inaturezas= interface(IInvokable)
    ['{04FB9CCB-F5E2-477C-9AD3-639CCB8D5592}']
    [httppost]function   cadastrar(dados:parametros.naturezas):TJSONObject;
    [httpdelete]function remover([FromPath]  codigo:string):TJSONObject;
    [httpput]function    alterar([FromPath]  codigo:string;dados:parametros.naturezas):TJSONObject;
    [httpget]function    buscar(descricao:string;registro,pagina:integer):TJSONObject;
  end;

  [ServiceImplementation]
  TInaturezas = class(TInterfacedObject, Inaturezas)
  private
     function cadastrar(dados:parametros.naturezas):TJSONObject;
     function remover(codigo:string):TJSONObject;
     function alterar(codigo:string; dados:parametros.naturezas):TJSONObject;
     function buscar(descricao:string;registro,pagina:integer):TJSONObject;
  end;

implementation

{TItransportadoras}


function TInaturezas.alterar(codigo: string;dados: parametros.naturezas): TJSONObject;
  var
   resultado      : TJSONObject;
   usuario        : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado  :=  natureza.altera_natureza(codigo,dados,usuario.P['mensagemRetorno'].FindValue('mensagem').Value);
            result     :=  TJSonObject.ParseJSONValue(resultado.P['mensagemRetorno'].ToString) as TJSonObject;
            funcoes.statusHTTP(strtoint(resultado.FindValue('codigoHttp').value));
      end else
           begin
             result := TJSonObject.ParseJSONValue(usuario.P['mensagemRetorno'].ToString) as TJSonObject;
             funcoes.statusHTTP(strtoint(usuario.FindValue('codigoHttp').Value));
           end;
 end;



function TInaturezas.buscar(descricao:string;registro,pagina:integer): TJSONObject;
 var
   usuario    : TJSONObject;
   resultado  : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado := natureza.busca_natureza(descricao,registro,pagina,usuario.P['mensagemRetorno'].FindValue('mensagem').Value);
            if resultado.FindValue('codigoHttp').Value = '200' then
               begin
                result      := TJSonObject.ParseJSONValue(resultado.P['dadosRetorno'].ToString) as TJSonObject;
               end else
                   begin
                    result  :=  TJSonObject.ParseJSONValue(resultado.P['mensagemRetorno'].ToString) as TJSonObject;
                   end;
            funcoes.statusHTTP(strtoint(resultado.FindValue('codigoHttp').Value));
      end else
           begin
            result := TJSonObject.ParseJSONValue(usuario.P['mensagemRetorno'].ToString) as TJSonObject;
            funcoes.statusHTTP(strtoint(usuario.FindValue('codigoHttp').Value));
           end;
 end;


function TInaturezas.cadastrar(dados: parametros.naturezas): TJSONObject;
  var
   resultado      : TJSONObject;
   usuario        : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado  :=  natureza.cadastro_natureza(dados,usuario.P['mensagemRetorno'].FindValue('mensagem').Value);
            result     :=  TJSonObject.ParseJSONValue(resultado.P['mensagemRetorno'].ToString) as TJSonObject;
            funcoes.statusHTTP(strtoint(resultado.FindValue('codigoHttp').value));
      end else
           begin
             result := TJSonObject.ParseJSONValue(usuario.P['mensagemRetorno'].ToString) as TJSonObject;
             funcoes.statusHTTP(strtoint(usuario.FindValue('codigoHttp').Value));
           end;
 end;

function TInaturezas.remover(codigo: string): TJSONObject;
  var
   resultado      : TJSONObject;
   usuario        : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado  :=  natureza.remove_natureza(codigo,usuario.P['mensagemRetorno'].FindValue('mensagem').Value);
            result     :=  TJSonObject.ParseJSONValue(resultado.P['mensagemRetorno'].ToString) as TJSonObject;
            funcoes.statusHTTP(strtoint(resultado.FindValue('codigoHttp').value));
      end else
           begin
             result := TJSonObject.ParseJSONValue(usuario.P['mensagemRetorno'].ToString) as TJSonObject;
             funcoes.statusHTTP(strtoint(usuario.FindValue('codigoHttp').Value));
           end;
 end;

initialization
  RegisterServiceType(TypeInfo(Inaturezas));
  RegisterServiceType(TInaturezas);

end.

