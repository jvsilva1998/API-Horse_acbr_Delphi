unit utilService;

interface

uses
  XData.Server.Module,
  XData.Service.Common,

  Json,
  funcoes,
  utilidades,
  System.SysUtils;

type
  [ServiceContract]
  Iutil= interface(IInvokable)
    ['{04FB9CCB-F5E2-477C-9AD3-639CCB8D5592}']
    [httpget]function  bancos(pagina,registros:Integer;descricao:string):TJSONObject;
    [httpget]function  ncm(descricao,ncm:string;pagina,registros:Integer):TJSONObject;
    [httpget]function  cfop(descricao,cfop:string;pagina,registros:Integer):TJSONObject;
    [httpget]function  cest(descricao,cest:string;pagina,registros:Integer):TJSONObject;
    [httpget]function  anp(descricao,anp:string;pagina,registros:Integer):TJSONObject;
    [httpget]function  paises(pais,codigo:string;pagina,registros:Integer):TJSONObject;
    [httpget]function  municipios(municipio,uf,codigo:string;pagina,registros:Integer):TJSONObject;
  end;

  [ServiceImplementation]
  TIutil = class(TInterfacedObject, Iutil)
  private
    function  bancos(pagina,registros:Integer;descricao:string):TJSONObject;
    function  ncm(descricao,ncm:string;pagina,registros:Integer):TJSONObject;
    function  cfop(descricao,cfop:string;pagina,registros:Integer):TJSONObject;
    function  cest(descricao,cest:string;pagina,registros:Integer):TJSONObject;
    function  anp(descricao,anp:string;pagina,registros:Integer):TJSONObject;
    function  paises(pais,codigo:string;pagina,registros:Integer):TJSONObject;
    function  municipios(municipio,uf,codigo:string;pagina,registros:Integer):TJSONObject;
  end;

implementation



function TIutil.anp(descricao, anp: string; pagina,registros: Integer): TJSONObject;
 var
   usuario     : TJSONObject;
   resultado   : TJSONObject;
   usuarioADM  : TJSONObject;
   begin
       usuarioADM    := verificaTokenADM(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));

      if usuarioADM.FindValue('codigoHttp').Value = '200' then
        begin
              resultado :=  utilidades.buscar_anp(descricao,anp,pagina,registros);
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

function TIutil.bancos(pagina,registros:Integer;descricao:string): TJSONObject;
 var
   usuario     : TJSONObject;
   resultado   : TJSONObject;
   usuarioADM  : TJSONObject;
 begin
     usuarioADM    := verificaTokenADM(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));

    if usuarioADM.FindValue('codigoHttp').Value = '200' then
      begin
            resultado :=  utilidades.buscar_bancos(descricao,pagina,registros);
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

function TIutil.cest(descricao, cest: string; pagina,registros: Integer): TJSONObject;
 var
   usuario     : TJSONObject;
   resultado   : TJSONObject;
   usuarioADM  : TJSONObject;
   begin
       usuarioADM    := verificaTokenADM(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));

      if usuarioADM.FindValue('codigoHttp').Value = '200' then
        begin
              resultado :=  utilidades.buscar_cest(descricao,cest,pagina,registros);
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

function TIutil.cfop(descricao, cfop: string; pagina,
  registros: Integer): TJSONObject;
 var
   usuario     : TJSONObject;
   resultado   : TJSONObject;
   usuarioADM  : TJSONObject;
 begin
     usuarioADM    := verificaTokenADM(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));

    if usuarioADM.FindValue('codigoHttp').Value = '200' then
      begin
            resultado :=  utilidades.buscar_cfop(descricao,cfop,pagina,registros);
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

function TIutil.municipios(municipio, uf, codigo: string; pagina,registros: Integer): TJSONObject;
 var
   usuario     : TJSONObject;
   resultado   : TJSONObject;
   usuarioADM  : TJSONObject;
 begin
     usuarioADM    := verificaTokenADM(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));

    if usuarioADM.FindValue('codigoHttp').Value = '200' then
      begin
            resultado :=  utilidades.buscar_municipios (uf,municipio,codigo,pagina,registros);
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

function TIutil.ncm(descricao, ncm: string; pagina,registros: Integer): TJSONObject;
 var
   usuario     : TJSONObject;
   resultado   : TJSONObject;
   usuarioADM  : TJSONObject;
 begin
     usuarioADM    := verificaTokenADM(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));

    if usuarioADM.FindValue('codigoHttp').Value = '200' then
      begin
            resultado :=  utilidades.buscar_ncm (descricao,ncm, pagina,registros);
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

function TIutil.paises(pais, codigo: string; pagina,registros: Integer): TJSONObject;
 var
   usuario     : TJSONObject;
   resultado   : TJSONObject;
   usuarioADM  : TJSONObject;
 begin
     usuarioADM    := verificaTokenADM(TXDataOperationContext.Current.Request.Headers.Get('Authorization'));

    if usuarioADM.FindValue('codigoHttp').Value = '200' then
      begin
            resultado :=  utilidades.buscar_paises(pais,codigo, pagina,registros);
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

initialization
  RegisterServiceType(TypeInfo(Iutil));
  RegisterServiceType(TIutil);

end.

