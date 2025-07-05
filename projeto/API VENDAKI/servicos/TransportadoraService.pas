unit TransportadoraService;

interface

uses
  XData.Server.Module,
  XData.Service.Common,
  parametros,
  Json,
  funcoes,
  transportadora,
  System.SysUtils;

type
  [ServiceContract]
  Itransportadoras= interface(IInvokable)
    ['{04FB9CCB-F5E2-477C-9AD3-639CCB8D5592}']
    [httppost]function   cadastrar(dados:parametros.transportadoras):TJSONObject;
    [httpdelete]function remover([FromPath]  codigo:string):TJSONObject;
    [httpput]function    alterar([FromPath]  codigo:string;dados:parametros.transportadoras):TJSONObject;
    [httpget]function    buscar([FromPath] descricao, [FromPath] cpfCnpj:string; [FromPath]codigo:string;registro,pagina:integer):TJSONObject;
  end;

  [ServiceImplementation]
  TItransportadoras = class(TInterfacedObject, Itransportadoras)
  private
     function cadastrar(dados:parametros.transportadoras):TJSONObject;
     function remover(codigo:string):TJSONObject;
     function alterar(codigo:string; dados:parametros.transportadoras):TJSONObject;
     function buscar(descricao,cpfCnpj,codigo:string;registro,pagina:integer):TJSONObject;
  end;

implementation

{TItransportadoras}

function TItransportadoras.alterar(codigo: string;dados: parametros.transportadoras): TJSONObject;
  var
   resultado      : TJSONObject;
   usuario        : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado  :=  transportadora.alterar_transportadora(codigo,dados,usuario.P['mensagemRetorno'].FindValue('mensagem').Value);
            result     :=  TJSonObject.ParseJSONValue(resultado.P['mensagemRetorno'].ToString) as TJSonObject;
            funcoes.statusHTTP(strtoint(resultado.FindValue('codigoHttp').value));
      end else
           begin
             result    := TJSonObject.ParseJSONValue(usuario.P['mensagemRetorno'].ToString) as TJSonObject;
             funcoes.statusHTTP(strtoint(usuario.FindValue('codigoHttp').Value));
           end;
 end;

function TItransportadoras.buscar(descricao,cpfCnpj,codigo:string;registro,pagina:integer):TJSONObject;
 var
   usuario    : TJSONObject;
   resultado  : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado := transportadora.buscar_transportadora(descricao,cpfCnpj,codigo,registro,pagina,usuario.P['mensagemRetorno'].FindValue('mensagem').Value);
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

function TItransportadoras.cadastrar(dados: parametros.transportadoras): TJSONObject;
  var
   resultado      : TJSONObject;
   usuario        : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado  :=  transportadora.cadastra_transportadora(dados,usuario.P['mensagemRetorno'].FindValue('mensagem').Value);
            result     :=  TJSonObject.ParseJSONValue(resultado.P['mensagemRetorno'].ToString) as TJSonObject;
            funcoes.statusHTTP(strtoint(resultado.FindValue('codigoHttp').value));
      end else
           begin
             result := TJSonObject.ParseJSONValue(usuario.P['mensagemRetorno'].ToString) as TJSonObject;
             funcoes.statusHTTP(strtoint(usuario.FindValue('codigoHttp').Value));
           end;
 end;

function TItransportadoras.remover(codigo: string): TJSONObject;
  var
   resultado      : TJSONObject;
   usuario        : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado  :=  transportadora.remover_transportadora(codigo,usuario.P['mensagemRetorno'].FindValue('mensagem').Value);
            result     :=  TJSonObject.ParseJSONValue(resultado.P['mensagemRetorno'].ToString) as TJSonObject;
            funcoes.statusHTTP(strtoint(resultado.FindValue('codigoHttp').value));
      end else
           begin
             result := TJSonObject.ParseJSONValue(usuario.P['mensagemRetorno'].ToString) as TJSonObject;
             funcoes.statusHTTP(strtoint(usuario.FindValue('codigoHttp').Value));
           end;
 end;

initialization
  RegisterServiceType(TypeInfo(Itransportadoras));
  RegisterServiceType(TItransportadoras);

end.

