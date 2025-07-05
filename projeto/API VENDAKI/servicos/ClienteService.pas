unit ClienteService;

interface

uses
  XData.Server.Module,
  XData.Service.Common,
  parametros,
  funcoes,
  cliente,
  System.JSON,

  dialogs,
  System.SysUtils;


type
 ///<summary>
 ///  esse � um teste
 ///  pronto :)
 /// </summary>
 ///  <param name="codigo>"
 ///  esse � parametro a
 /// </param>



   ///<swagger name="clientes">ol� primeitro teste</swagger>

  [ServiceContract]
  Iclientes= interface(IInvokable)
    ['{04FB9CCB-F5E2-477C-9AD3-639CCB8D5592}']
    [httppost]function   cadastrar(dados:parametros.clientes):TJSONObject;
    [httpdelete]function remover([FromPath]  codigo:string):TJSONObject;
    [httpput]function    alterar([FromPath]  codigo:string;dados:parametros.clientes):TJSONObject;
    [httpget]function    buscar([FromPath] descricao,cpfCnpj:string; codigo:string;registro,pagina:integer):TJSONObject;
  end;

  [ServiceImplementation]
  TIclientes = class(TInterfacedObject, Iclientes)
  private
     function cadastrar(dados:parametros.clientes):TJSONObject;
     function remover(codigo:string):TJSONObject;
     function alterar(codigo:string; dados:parametros.clientes):TJSONObject;
     function buscar(descricao,cpfCnpj,codigo:string;registro,pagina:integer):TJSONObject;
  end;

implementation


 {ALTERAR}
function TIclientes.alterar(codigo: string;dados: parametros.clientes): TJSONObject;
  var
   resultado      : TJSONObject;
   usuario        : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado  :=  cliente.alterar_cliente(codigo,dados,usuario.P['mensagemRetorno'].FindValue('mensagem').Value);
            result     :=  TJSonObject.ParseJSONValue(resultado.P['mensagemRetorno'].ToString) as TJSonObject;
            funcoes.statusHTTP(strtoint(resultado.FindValue('codigoHttp').value));
      end else
           begin
             result := TJSonObject.ParseJSONValue(usuario.P['mensagemRetorno'].ToString) as TJSonObject;
             funcoes.statusHTTP(strtoint(usuario.FindValue('codigoHttp').Value));
           end;
 end;


 {BUSCAR}
function TIclientes.buscar(descricao,cpfCnpj,codigo: string;registro,pagina:integer): TJSONObject;
 var
   usuario    : TJSONObject;
   resultado  : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado := cliente.buscar_cliente(descricao,cpfCnpj,codigo,registro,pagina,usuario.P['mensagemRetorno'].FindValue('mensagem').Value);
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


 {CADASTRAR}
function TIclientes.cadastrar(dados: parametros.clientes): TJSONObject;
  var
   resultado      : TJSONObject;
   usuario        : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado  :=  cliente.cadastra_cliente(dados,usuario.P['mensagemRetorno'].FindValue('mensagem').Value);
            result     :=  TJSonObject.ParseJSONValue(resultado.P['mensagemRetorno'].ToString) as TJSonObject;
            funcoes.statusHTTP(strtoint(resultado.FindValue('codigoHttp').value));
      end else
           begin
             result := TJSonObject.ParseJSONValue(usuario.P['mensagemRetorno'].ToString) as TJSonObject;
             funcoes.statusHTTP(strtoint(usuario.FindValue('codigoHttp').Value));
           end;
 end;


 {REMOVER}
function TIclientes.remover(codigo: string): TJSONObject;
  var
   resultado      : TJSONObject;
   usuario        : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado  :=  cliente.remover_cliente(codigo,usuario.P['mensagemRetorno'].FindValue('mensagem').Value);
            result     :=  TJSonObject.ParseJSONValue(resultado.P['mensagemRetorno'].ToString) as TJSonObject;
            funcoes.statusHTTP(strtoint(resultado.FindValue('codigoHttp').value));
      end else
           begin
             result := TJSonObject.ParseJSONValue(usuario.P['mensagemRetorno'].ToString) as TJSonObject;
             funcoes.statusHTTP(strtoint(usuario.FindValue('codigoHttp').Value));
           end;
 end;




initialization
  RegisterServiceType(TypeInfo(Iclientes));
  RegisterServiceType(TIclientes);

end.

