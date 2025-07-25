unit IndicacaoService;

interface

uses
  XData.Server.Module,
  XData.Service.Common,
  Json,
  funcoes,
  indicacao,
  System.SysUtils,dialogs,fm_principal;

type
  [ServiceContract]
  Iindicacoes= interface(IInvokable)
    ['{04FB9CCB-F5E2-477C-9AD3-639CCB8D5592}']
    [httpget]function indicador([FromPath] codigoIndicador:string):TJSONObject;
    [httpget]function indicacoes(pagina:Integer;registros:Integer):TJSONObject;
    [httpget]function movimentacoes(pagina:Integer;registros:Integer):TJSONObject;
    [httppost]function banco(banco,tipoConta,agencia,conta:string):TJSONObject;
    [Route('solicita/saque/')] [httppost]function solicitaSaque(valor:double):TJSONObject;
  end;

  [ServiceImplementation]
  TIindicacoes = class(TInterfacedObject, Iindicacoes)
  private

   function  indicador(codigoIndicador:string):TJSONObject;
   function  indicacoes(pagina,registros:Integer):TJSONObject;
   function  solicitaSaque(valor:double):TJSONObject;
   function  movimentacoes(pagina:Integer;registros:Integer):TJSONObject;
   function  banco(banco,tipoConta,agencia,conta:string):TJSONObject;
  end;




implementation


function TIindicacoes.banco(banco, tipoConta, agencia,
  conta: string): TJSONObject;
  var
   resultado      : TJSONObject;
   usuario        : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado  :=  indicacao.atualizaBanco (banco,tipoConta,agencia,conta,usuario.P['mensagemRetorno'].FindValue('mensagem').Value);
            result     :=  TJSonObject.ParseJSONValue(resultado.P['mensagemRetorno'].ToString) as TJSonObject;
            funcoes.statusHTTP(strtoint(resultado.FindValue('codigoHttp').value));
      end else
           begin
             result := TJSonObject.ParseJSONValue(usuario.P['mensagemRetorno'].ToString) as TJSonObject;
             funcoes.statusHTTP(strtoint(usuario.FindValue('codigoHttp').Value));
           end;
 end;

function TIindicacoes.indicacoes(pagina,registros: Integer): TJSONObject;
 var
   usuario    : TJSONObject;
   resultado  : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado :=  indicacao.busca_indicacoes(usuario.P['mensagemRetorno'].FindValue('codigoIndicacao').Value,pagina,registros);   //  (descricao,cpfCnpj,codigo,registro,pagina,usuario.P['mensagemRetorno'].FindValue('mensagem').Value);
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

function TIindicacoes.indicador(codigoIndicador: string): TJSONObject;
  var
   resultado      : TJSONObject;
   usuarioADM     : TJSONObject;
 begin
   usuarioADM    := verificaTokenADM(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));

    if usuarioADM.FindValue('codigoHttp').Value = '200' then
      begin
            resultado  :=  indicacao.busca_indicador(codigoIndicador);
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
             funcoes.statusHTTP(strtoint(usuarioADM.FindValue('codigoHttp').Value));
             result  := TJSonObject.ParseJSONValue(usuarioADM.P['mensagemRetorno'].ToString) as TJSonObject;
           end;
 end;



  {MOVIMENTAÇÕES}
 function TIindicacoes.movimentacoes(pagina, registros: Integer): TJSONObject;
 var
   usuario    : TJSONObject;
   resultado  : TJSONObject;
 begin
     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado :=  indicacao.extrato(usuario.P['mensagemRetorno'].FindValue('mensagem').Value,pagina,registros);
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

{SOLICITA SAQUE}
function TIindicacoes.solicitaSaque(valor: double): TJSONObject;
  var
   resultado      : TJSONObject;
   usuario        : TJSONObject;
   tokenLogado    : string;
 begin

    tokenLogado :=  TXDataOperationContext.Current.Request.Headers.Get('Authorization');
    fm_principal.cliqueIndicacao := fm_principal.cliqueIndicacao + 1;

    if fm_principal.cliqueIndicacao > 1 then
       begin
         if tokenLogado = TXDataOperationContext.Current.Request.Headers.Get('Authorization')  then
         begin
           fm_principal.cliqueIndicacao := 0;
           Sleep(1000);
         end;
       end;

     usuario           := funcoes.logaToken(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));
    if usuario.FindValue('codigoHttp').value = '200' then
      begin
            resultado  :=  indicacao.solicita_saque(usuario.P['mensagemRetorno'].FindValue('mensagem').Value,usuario.P['mensagemRetorno'].FindValue('codigoIndicacao').Value,valor, strtofloat(usuario.P['mensagemRetorno'].FindValue('saldoIndicacao').Value));
            result     :=  TJSonObject.ParseJSONValue(resultado.P['mensagemRetorno'].ToString) as TJSonObject;
            funcoes.statusHTTP(strtoint(resultado.FindValue('codigoHttp').value));
      end else
           begin
             result := TJSonObject.ParseJSONValue(usuario.P['mensagemRetorno'].ToString) as TJSonObject;
             funcoes.statusHTTP(strtoint(usuario.FindValue('codigoHttp').Value));
           end;

  tokenLogado := '';
 end;

initialization
  RegisterServiceType(TypeInfo(Iindicacoes));
  RegisterServiceType(TIindicacoes);
end.

