unit imposto;

interface

uses
  System.SysUtils,
  Vcl.Dialogs,
  FireDAC.Comp.Client,
  parametros,
  System.JSON,
  DataSet.Serialize;

  function cadastra_imposto(dados:parametros.PerfilTibutario;cod_usuario:string):TJSONObject;
  function remover_imposto(codigo:string;cod_usuario:string):TJSONObject;
  function alterar_imposto(codigo:string;dados:parametros.PerfilTibutario;cod_usuario:string):TJSONObject;
  function buscar_imposto(descricao:string;pagina,registro:integer;cod_usuario:string):TJSONObject;

implementation
   uses funcoes;


   {CADASTRO IMPOSTO}
   function cadastra_imposto(dados:parametros.PerfilTibutario;cod_usuario:string):TJSONObject;
  var
   query              : TFDQuery;
   conexao            : TFDConnection;
   codigo             : string;
   json               : string;
   codigoHttp         : integer;
   mensagem           : string;
   tituloMensagem     : string;
  begin
     conexao          := TFDConnection.Create(nil);
     query            := TFDQuery.Create(nil);
     query.Connection := conexao;


        try
         conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);

         query.Close;
         query.SQL.Add('SELECT  nome_perfil from perfil_tributario where nome_perfil = '''+dados.descricao+'''  AND cod_usuario = '''+cod_usuario+'''');
         query.Open();

         if query.RowsAffected <>0 then
             begin
               tituloMensagem := 'Não foi possivel cadastrar imposto';
               mensagem       := 'Já existe um imposto com esse nome';
               codigoHttp     :=  409;

               json           := '{ '+
                           '  "mensagemRetorno": {  '+
                           '   "titulo": "'+ tituloMensagem  +'", '+
                           '   "mensagem": "'+ mensagem  +'" '+
                           ' }, '+
                           ' "dadosRetorno": [], '+
                           ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                           ' }' ;

                  Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                  freeandnil(query);
                  FreeAndNil(conexao);
                  Exit;
             end;


         codigo := funcoes.trigger;

         query.SQL.Clear;
         query.SQL.Add
         ('INSERT INTO perfil_tributario ( '+
                                 'NOME_PERFIL,'+
                                 'COD_ICMS_CST,'+
                                 'COD_MOD_BC,'+
                                 'COD_CSON_CST,'+
                                 'COD_CST_COFINS,'+
                                 'COD_TRIB_PIS,'+
                                 'COD_IPI_CST,'+
                                 'PERC_ICMS,'+
                                 'PERC_PIS,'+
                                 'PERC_IPI,'+
                                 'PERC_COFINS,'+
                                 'cod_perfil,'+
                                 'cod_usuario)values(');
         query.SQL.Add(''''  +funcoes.RemoveAcento(dados.descricao) + '''');
         query.SQL.Add(',''' +IntToStr(dados.icms.codigoCst)+ '''');
         query.SQL.Add(',''' +IntToStr(dados.icms.modalidadeBaseCalculo)+ '''');
         query.SQL.Add(',''' +IntToStr(dados.icms.codigoCsosnCST)+ '''');
         query.SQL.Add(',''' +IntToStr(dados.cofins.CodigoCst)+ '''');
         query.SQL.Add(',''' +IntToStr(dados.pis.CodigoTributacao)+ '''');
         query.SQL.Add(',''' +IntToStr(dados.ipi.CodigoCst)+ '''');
         query.SQL.Add(',''' +CurrToStr(dados.icms.aliquota)+'''');
         query.SQL.Add(',''' +CurrToStr(dados.pis.aliquota)+ '''');
         query.SQL.Add(',''' +CurrToStr(dados.ipi.aliquota)+ '''');
         query.SQL.Add(',''' +CurrToStr(dados.cofins.aliquota)+ '''');
         query.SQL.Add(',''' +codigo+ '''');
         query.SQL.Add(',''' +cod_usuario+ ''')');
         query.ExecSQL;

         if query.RowsAffected = 1  then
            begin
               tituloMensagem := 'Imposto cadsstrado';
               mensagem       :=  codigo;
               codigoHttp     :=  201;
            end;

           except
            on E: Exception do
             begin
               tituloMensagem := 'Erro interno';
               mensagem       :=  funcoes.RemoveAcento(e.Message);
               codigoHttp     :=  500;
              funcoes.logErro(e.Message);
             end;
        end;
       json           := '{ '+
                   '  "mensagemRetorno": {  '+
                   '   "titulo": "'+ tituloMensagem  +'", '+
                   '   "mensagem": "'+ mensagem  +'" '+
                   ' }, '+
                   ' "dadosRetorno": [], '+
                   ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                   ' }' ;

        Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
        freeandnil(query);
        FreeAndNil(conexao);
  end;


   {REMOVER IMPOSTO}
   function remover_imposto(codigo:string;cod_usuario:string):TJSONObject;
   var
   query: TFDQuery;
   conexao : TFDConnection;
   json               : string;
   codigoHttp         : integer;
   mensagem           : string;
   tituloMensagem     : string;
  begin
     conexao          := TFDConnection.Create(nil);
     query            := TFDQuery.Create(nil);
     query.Connection := conexao;

        try
         conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);
         query.SQL.Add('DELETE FROM perfil_tributario WHERE cod_perfil = '''+codigo+''' and cod_usuario = '''+cod_usuario+'''');
         query.ExecSQL;

           if query.RowsAffected = 1 then
                begin
                  {desvincular perfil dos produtos}
                   query.SQL.Clear;
                   query.SQL.Add('UPDATE produtos SET nomeperfiltributario = '''+''+''' ,codigoperfiltributario = '''+''+''' where codigoperfiltributario = '''+codigo+''' and cod_usuario = '''+cod_usuario+'''');
                   query.ExecSQL;

                   tituloMensagem := 'Tudo certo';
                   mensagem       := 'Perfil de imposto removido com sucesso';
                   codigoHttp     := 200;
                end else
                     begin
                       tituloMensagem := 'não foi possivel atualizar';
                       mensagem       := 'o perfil de imposto não existe';
                       codigoHttp     := 404;
                     end;
           except
            on E: Exception do
             begin
              tituloMensagem := 'Erro';
              mensagem       := funcoes.RemoveAcento(e.Message);
              codigoHttp     := 500;
              funcoes.logErro(e.Message);
             end;
        end;
       json           := '{ '+
                   '  "mensagemRetorno": {  '+
                   '   "titulo": "'+ tituloMensagem  +'", '+
                   '   "mensagem": "'+ mensagem  +'" '+
                   ' }, '+
                   ' "dadosRetorno": [], '+
                   ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                   ' }' ;

      Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
      freeandnil(query);
      FreeAndNil(conexao);
  end;


   {ALTERAR IMPOSTO}
   function alterar_imposto(codigo:string;dados:parametros.PerfilTibutario;cod_usuario:string):TJSONObject;
  var
   query   : TFDQuery;
   conexao : TFDConnection;
   json               : string;
   codigoHttp         : integer;
   mensagem           : string;
   tituloMensagem     : string;
   impostoUsado       : string;
  begin
     conexao          := TFDConnection.Create(nil);
     query            := TFDQuery.Create(nil);
     query.Connection := conexao;

        try
           conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);

           query.Close;
           query.SQL.Add('SELECT nome_perfil FROM perfil_tributario WHERE cod_perfil = '''+codigo+''' and  cod_usuario = '''+cod_usuario+'''');
           query.Open;

           impostoUsado :=  query.FieldByName('nome_perfil').AsString;

           query.SQL.Clear;
           query.Close;
           query.SQL.Add('SELECT cod_perfil FROM perfil_tributario WHERE nome_perfil = '''+dados.descricao+''' and cod_usuario = '''+cod_usuario+'''');
           query.Open;

         if query.RowsAffected >= 1 then
            begin
              if impostoUsado <> dados.descricao then
                 begin
                   codigoHttp      := 409;
                   tituloMensagem  := 'não foi possivel alterar imposto';
                   mensagem        := 'o cliente já existe';
                   json            := '{ '+
                           '  "mensagemRetorno": {  '+
                           '   "titulo": "'+ tituloMensagem  +'", '+
                           '   "mensagem": "'+ mensagem  +'" '+
                           ' }, '+
                           ' "dadosRetorno":[],'+
                           ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                           ' }' ;
                    Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                    freeandnil(query);
                    FreeAndNil(conexao);
                    Exit;
                 end;
            end;

           query.SQL.Clear;
           query.SQL.Add('UPDATE perfil_tributario SET NOME_PERFIL = ''' +funcoes.RemoveAcento(dados.descricao) + '''');
           query.SQL.Add(',COD_ICMS_CST= '''+IntToStr(dados.icms.codigoCst)+ '''');
           query.SQL.Add(',COD_MOD_BC= '''+IntToStr(dados.icms.modalidadeBaseCalculo)+ '''');
           query.SQL.Add(',COD_CSON_CST= ''' +IntToStr(dados.icms.codigoCsosnCST)+ '''');
           query.SQL.Add(',COD_CST_COFINS= ''' +IntToStr(dados.cofins.CodigoCst)+ '''');
           query.SQL.Add(',COD_TRIB_PIS= ''' +IntToStr(dados.pis.CodigoTributacao)+ '''');
           query.SQL.Add(',COD_IPI_CST= ''' +IntToStr(dados.ipi.CodigoCst)+ '''');
           query.SQL.Add(',PERC_ICMS= ''' +CurrToStr(dados.icms.aliquota)+ '''');
           query.SQL.Add(',PERC_PIS= ''' +CurrToStr(dados.pis.aliquota)+ '''');
           query.SQL.Add(',PERC_IPI= ''' +CurrToStr(dados.ipi.aliquota)+ '''');
           query.SQL.Add(',PERC_COFINS= ''' +CurrToStr(dados.cofins.aliquota)+ '''');
           query.SQL.Add('WHERE cod_perfil = '''+codigo+''' AND cod_usuario = '''+cod_usuario+'''');
           query.ExecSQL;

         if query.RowsAffected = 1 then
                begin
                   query.SQL.Clear;
                   query.SQL.Add('UPDATE produtos SET nomeperfiltributario = ''' +funcoes.RemoveAcento(dados.descricao) + ''' where codigoperfiltributario = '''+codigo+''' and cod_usuario = '''+cod_usuario+'''');
                   query.ExecSQL;

                   tituloMensagem :=  'Tudo certo';
                   mensagem       :=  'Perfil de imposto atualizado com sucesso';
                   codigoHttp     :=  200;
                end else
                     begin
                       tituloMensagem :=  'não foi possivel atualizar';
                       mensagem       :=  'o perfil de imposto não existe';
                       codigoHttp     :=  404;
                     end;
           except
            on E: Exception do
             begin
              tituloMensagem :=  'Erro interno';
              mensagem       :=  funcoes.RemoveAcento(e.Message);
              codigoHttp     :=  500;
              funcoes.logErro(e.Message);
             end;
        end;
       json           := '{ '+
                   '  "mensagemRetorno": {  '+
                   '   "titulo": "'+ tituloMensagem  +'", '+
                   '   "mensagem": "'+ mensagem  +'" '+
                   ' }, '+
                   ' "dadosRetorno": [], '+
                   ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                   ' }' ;

      Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
      freeandnil(query);
      FreeAndNil(conexao);
  end;


   {BUSCAR IMPOSTO}
   function buscar_imposto(descricao:string;pagina,registro:integer;cod_usuario:string):TJSONObject;
  var
   query              : TFDQuery;
   LJSONArray         : TJSONArray;
   conexao            : TFDConnection;
   json               : string;
   codigoHttp         : integer;
   dados              : string;
   mensagem           : string;
   tituloMensagem     : string;
  begin
       conexao          := TFDConnection.Create(nil);
       query            := TFDQuery.Create(nil);
       query.Connection := conexao;

        try
           conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);
           query.SQL.Add(' SELECT '+
                         ' nome_perfil'+
                         ',cod_icms_cst'+
                         ',cod_mod_bc'+
                         ',cod_cson_cst'+
                         ',cod_cst_cofins'+
                         ',cod_trib_pis'+
                         ',cod_ipi_cst'+
                         ',perc_icms'+
                         ',perc_pis'+
                         ',perc_ipi'+
                         ',perc_cofins'+
                         ',cod_perfil'+
                         ' FROM perfil_tributario where nome_perfil like ''%'+descricao+'%'' AND cod_usuario='''+cod_usuario+'''  ORDER BY nome_perfil ASC LIMIT '+IntToStr(registro)+' OFFSET '+IntToStr((pagina-1) * registro)+'  ');
           query.Open;

           if  query.RowsAffected = 0 then
              begin
               codigoHttp      := 404;
               tituloMensagem  := 'nenhum encontrado';
               mensagem        := 'Nenhum imposto encontrado';
              end else
                   begin
                    codigoHttp := 200;
                    LJSONArray            := query.ToJSONArray;
                    dados := '"impostos":'+ LJSONArray.Format;
                    LJSONArray.Free;
                   end;
           except
            on E: Exception do
             begin
               codigoHttp      := 500;
               tituloMensagem  := 'Erro interno';
               mensagem        := funcoes.RemoveAcento(e.Message);
             end;
        end;
     json := '{ '+
             '  "mensagemRetorno": {  '+
             '   "titulo": "'+ tituloMensagem  +'", '+
             '   "mensagem": "'+ mensagem  +'" '+
             ' }, '+
             ' "dadosRetorno": { '+ dados +'}, '+
             ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
             ' }' ;

      Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
      freeandnil(query);
      FreeAndNil(conexao);
  end;



end.
