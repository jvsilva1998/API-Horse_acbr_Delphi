unit indicacao;

interface

uses
 System.SysUtils,
 System.Classes,
 vcl.forms,
 Vcl.Dialogs,
 FireDAC.Comp.Client,

 DataSet.Serialize,
 System.JSON,
 EncdDecd;

 function busca_indicador(codigo_indicador:string):TJSONObject;
 function busca_indicacoes(codigoIndicacao:string;pagina,registros:integer):TJSONObject;
 function solicita_saque(cod_usuario,codigo_indicacao:string;valor,saldoAtual:double):TJSONObject;
 function extrato(cod_usuario:string;pagina,registros:integer):TJSONObject;
 function atualizaBanco(banco,tipoConta,agencia,conta:string;cod_usuario:string):TJSONObject;



implementation

uses funcoes;


 {BUSCAR INDICADOR}
 function busca_indicador(codigo_indicador:string):TJSONObject;
   var
   query          : TFDQuery;
   conexao        : TFDConnection;
   dados          : string;
   json           : string;
   codigoHttp     : integer;
   mensagem       : string;
   tituloMensagem : string;
  begin
     conexao          := TFDConnection.Create(nil);
     query            := TFDQuery.Create(nil);
     query.Connection := conexao;

          try
             conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);
             query.Close;
             query.SQL.Add(' SELECT '+
                           ' nomeusuario'+
                           ',codigoindicacao'+
                           ',pushtoken'+
                           ',emailusuario'+
                           ' FROM usuarios where codigoindicacao = '''+codigo_indicador+'''  AND bloqueado = '''+'N'+'''');
             query.Open;

               if  query.RowsAffected <> 1  then
                  begin
                     codigoHttp      := 404;
                     tituloMensagem  := 'nenhum encontrado';
                     mensagem        := 'Nenhum indicador encontrado';
                  end else
                       begin
                          codigoHttp := 200;
                          dados :=  '   "Indicador": { '+
                                    '    "nome": "'+query.FieldByName('nomeusuario').AsString+'",'+
                                    '    "codigoIndicacao": "'+query.FieldByName('codigoindicacao').AsString+'",'+
                                    '    "pushToken": "'+query.FieldByName('pushtoken').AsString+'",'+
                                    '    "email":  "'+query.FieldByName('emailusuario').AsString+'"'+
                                    '  }';
                       end;

             except
              on E: Exception do
               begin
                tituloMensagem := 'Erro interno';
                mensagem       := funcoes.RemoveAcento(e.Message);
                codigoHttp     := 500;
                funcoes.logErro(e.Message);
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

 {LISTA DE INDICAÇÕES}
 function busca_indicacoes(codigoIndicacao:string;pagina,registros:integer):TJSONObject;
   var
   query          : TFDQuery;
   LJSONArray     : TJSONArray;
   conexao        : TFDConnection;
   dados          : string;
   json           : string;
   codigoHttp     : integer;
   mensagem       : string;
   tituloMensagem : string;
  begin
     conexao          := TFDConnection.Create(nil);
     query            := TFDQuery.Create(nil);
     query.Connection := conexao;

          try
             conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);
             query.Close;
             query.SQL.Add(' SELECT '+
                           ' fantasiaempresa'+
                           ',nomeusuario'+
                           ',datacadastro'+
                           ',emailusuario'+
                           ',cidadeempresa'+
                           ',ufempresa'+
                           ' FROM usuarios where referenciaindicacao =  '''+codigoIndicacao+'''  ORDER BY datacadastro ASC  LIMIT '+IntToStr(registros)+' OFFSET '+IntToStr((pagina-1) * registros)+'  ');
             query.Open;

               if  query.RowsAffected = 0  then
                  begin
                     codigoHttp      := 404;
                     tituloMensagem  := 'Nenhum  indicação';
                     mensagem        := 'Nenhuma indicação foi encontrada';
                  end else
                       begin
                          codigoHttp := 200;
                          LJSONArray            := query.ToJSONArray;
                          dados := '"indicacoes":'+ LJSONArray.Format;
                          LJSONArray.Free;
                       end;

             except
              on E: Exception do
               begin
                tituloMensagem := 'Erro interno';
                mensagem       := funcoes.RemoveAcento(e.Message);
                codigoHttp     := 500;
                funcoes.logErro(e.Message);
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

 {SOLICITAÇÃO DE SAQUE}
 function solicita_saque(cod_usuario,codigo_indicacao:string;valor,saldoAtual:double):TJSONObject;
 var
   query             : TFDQuery;
   LJSONArray        : TJSONArray;
   conexao           : TFDConnection;
   dados             : string;
   json              : string;
   codigoHttp        : integer;
   mensagem          : string;
   tituloMensagem    : string;
   codigoSolicitacao : string;
  begin

    if valor < 20 then  //não pode ser menor que 20 reais//
       begin
           codigoHttp      := 400;
           tituloMensagem  := 'Não foi possivel solicitar o saque';
           mensagem        := 'O valor do saque não pode ser menor que 20,00';

           json := '{ '+
                   '  "mensagemRetorno": {  '+
                   '   "titulo": "'+ tituloMensagem  +'", '+
                   '   "saldoAtual": "'+ formatfloat('###,##0.00',saldoAtual) +'", '+
                   '   "mensagem": "'+ mensagem  +'" '+
                   ' }, '+
                   ' "dadosRetorno": { '+ dados +'}, '+
                   ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                   ' }' ;

            Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
            Exit;
       end;


    if valor > saldoAtual then // caso não haja saldo suficiente//
       begin
           codigoHttp      := 400;
           tituloMensagem  := 'Não foi possivel solicitar o saque';
           mensagem        := 'Não há saldo suficiente';

           json := '{ '+
                   '  "mensagemRetorno": {  '+
                   '   "titulo": "'+ tituloMensagem  +'", '+
                   '   "saldoAtual": "'+ formatfloat('###,##0.00',saldoAtual)+'", '+
                   '   "mensagem": "'+mensagem +'" '+
                   ' }, '+
                   ' "dadosRetorno": { '+ dados +'}, '+
                   ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                   ' }' ;

            Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
            Exit;
       end;

      codigoSolicitacao := funcoes.trigger;
      conexao           := TFDConnection.Create(nil);
      query             := TFDQuery.Create(nil);
      query.Connection  := conexao;

          try
             conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);

             query.SQL.Add
             ('INSERT INTO solicita_saque_indicacao  (codigoSocilitacao,'+
                                                     'statusSolicitacao,'+
                                                     'valor,'+
                                                     'dataSolicitacao,'+
                                                     'horaSolicitacao,'+
                                                     'dataVencimentoResposta,'+
                                                     'horaVencimentoResposta,'+
                                                     'codigoIndicacao,'+
                                                     'codigoUsuario)values(');
             query.SQL.Add(''''  +codigoSolicitacao+'''');
             query.SQL.Add(',''' +'PENDENTE'+ ''''); //PENDENTE //NEGADA// APROVADA // ANALISE///
             query.SQL.Add(',''' +funcoes.TrocaVirgPPto(FloatToStr(valor))+ '''');
             query.SQL.Add(',''' +funcoes.formataData(DateToStr(now))+ '''');
             query.SQL.Add(',''' +TimeToStr(now)+'''');
             query.SQL.Add(',''' +funcoes.formataData(DateToStr(now+2))+''''); // 2 DIAS PARA A RESPOSTA//
             query.SQL.Add(',''' +TimeToStr(now)+ '''');
             query.SQL.Add(',''' +codigo_indicacao+ '''');
             query.SQL.Add(',''' +cod_usuario+ ''')');
             query.ExecSQL;

               if  query.RowsAffected = 1  then
                  begin
                     query.SQL.Clear;
                     query.SQL.Add('UPDATE usuarios set saldoindicacoes = '''+ funcoes.TrocaVirgPPto(CurrToStr(saldoAtual - valor))+'''  WHERE codigousuario = '''+cod_usuario+'''');
                     query.ExecSQL;

                     if query.RowsAffected = 1  then  // INSERIR NO EXTRATO//
                        begin
                           query.SQL.Clear;
                           query.SQL.Add
                           ('INSERT INTO historico_movimento_indicacoes  (codigoMovimentacao,'+
                                                                   'codigoIndicacao,'+
                                                                   'codigoUsuario,'+
                                                                   'dataMovimento,'+
                                                                   'horaMovimento,'+
                                                                   'tituloMovimento,'+
                                                                   'descricaoMovimento,'+
                                                                   'tipoMovimento,'+
                                                                   'valorMovimento,'+
                                                                   'linkExterno)values(');
                           query.SQL.Add(''''  +funcoes.trigger+'''');
                           query.SQL.Add(',''' +codigo_indicacao+ '''');
                           query.SQL.Add(',''' +cod_usuario+ '''');
                           query.SQL.Add(',''' +funcoes.formataData(DateToStr(now))+ '''');
                           query.SQL.Add(',''' +TimeToStr(now)+'''');
                           query.SQL.Add(',''' +'Solicitação de saque'+'''');
                           query.SQL.Add(',''' +'Novo saque solicitado Nº '+codigoSolicitacao+'''');
                           query.SQL.Add(',''' +'2'+ '''');   //1- NOVA COMISSAO  //2-SOLICITACAO SAQUE 3-DEPOSITO DA SOLICITACAO //4-INFORMAÇÃO
                           query.SQL.Add(',''' +funcoes.TrocaVirgPPto(FloatToStr(-valor))+ '''');
                           query.SQL.Add(',''' +''+ ''')');
                           query.ExecSQL;

                           if query.RowsAffected = 1 then
                             begin
                               codigoHttp      := 201;
                               tituloMensagem  := 'Tudo certo';
                               mensagem        := 'Solicitação criada com sucesso';

                                json := '{ '+
                               '  "mensagemRetorno": {  '+
                               '   "titulo": "'+ tituloMensagem  +'", '+
                               '   "saldoAtual": "'+ formatfloat('###,##0.00',saldoAtual - valor) +'", '+
                               '   "codigoSolicitacao": "'+codigoSolicitacao+'", '+
                               '   "mensagem": "'+ mensagem  +'" '+
                               ' }, '+
                               ' "dadosRetorno": { '+ dados +'}, '+
                               ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                               ' }' ;

                                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                freeandnil(query);
                                FreeAndNil(conexao);
                                Exit;
                             end;
                        end;
                  end;

             except
              on E: Exception do
               begin
                tituloMensagem := 'Erro interno';
                mensagem       := funcoes.RemoveAcento(e.Message);
                codigoHttp     := 500;
                funcoes.logErro(e.Message);
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

 {EXTRATO DE MOVIMENTAÇÕES INDICAÇÕES}
 function extrato(cod_usuario:string;pagina,registros:integer):TJSONObject;
   var
   query          : TFDQuery;
   LJSONArray     : TJSONArray;
   conexao        : TFDConnection;
   dados          : string;
   json           : string;
   codigoHttp     : integer;
   mensagem       : string;
   tituloMensagem : string;
  begin
     conexao          := TFDConnection.Create(nil);
     query            := TFDQuery.Create(nil);
     query.Connection := conexao;

          try
             conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);
             query.Close;
             query.SQL.Add(' SELECT '+
                           ' codigomovimentacao'+
                           ',datamovimento'+
                           ',TIME_FORMAT(horamovimento, "%H:%i:%s") AS horamovimento'+
                           ',titulomovimento'+
                           ',descricaomovimento'+
                           ',tipomovimento'+
                           ',valormovimento'+
                           ',linkexterno'+
                           ' FROM historico_movimento_indicacoes where codigousuario =  '''+cod_usuario+''' ORDER BY  datamovimento DESC,horamovimento DESC  LIMIT '+IntToStr(registros)+' OFFSET '+IntToStr((pagina-1) * registros)+'  ');
             query.Open;


               if  query.RowsAffected = 0  then
                  begin
                     codigoHttp      := 404;
                     tituloMensagem  := 'Nenhuma movimentação';
                     mensagem        := 'Nenhum extrato foi encontrado';
                  end else
                       begin
                          codigoHttp := 200;
                          LJSONArray            := query.ToJSONArray;
                          dados := '"extratos":'+ LJSONArray.Format;
                          LJSONArray.Free;
                       end;

             except
              on E: Exception do
               begin
                tituloMensagem := 'Erro interno';
                mensagem       := funcoes.RemoveAcento(e.Message);
                codigoHttp     := 500;
                funcoes.logErro(e.Message);
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

 {ATUALIZA CONTA BANCARIA}
 function atualizaBanco(banco,tipoConta,agencia,conta:string;cod_usuario:string):TJSONObject;
    var
   query              : TFDQuery;
   LJSONArray         : TJSONObject;
   conexao            : TFDConnection;
   json               : string;
   codigoHttp         : integer;
   mensagem           : string;
   tituloMensagem     : string;
   novo_token         : string;
  begin
     conexao          := TFDConnection.Create(nil);
     query            := TFDQuery.Create(nil);
     query.Connection := conexao;

        try
           conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);
           query.SQL.Add('UPDATE usuarios SET bancoindicacao = ''' +funcoes.RemoveAcento(banco) + '''');
           query.SQL.Add(',tipocontaindicacao= '''+tipoConta+ '''');
           query.SQL.Add(',agenciabancoindicacao= '''+agencia+ '''');
           query.SQL.Add(',contabancoindicacao= ''' +conta+ '''');
           query.SQL.Add('WHERE codigousuario = '''+cod_usuario+'''');
           query.ExecSQL;

         if query.RowsAffected = 1 then
            begin
             tituloMensagem := 'banco alterado';
             mensagem       := 'O banco foi alterado com sucesso';
             codigoHttp     :=  200;
            end else
                 begin
                   tituloMensagem := 'Oops';
                   mensagem       := 'usuario não encontrado ';
                   codigoHttp     :=  404;
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

       json          := '{ '+
       '  "mensagemRetorno": {  '+
       '   "titulo": "'+ tituloMensagem  +'", '+
       '   "mensagem": "'+ mensagem +'" '+
       ' }, '+
       ' "dadosRetorno": [], '+
       ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
       ' }' ;
      Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
      freeandnil(query);
      FreeAndNil(conexao);
  end;








end.
