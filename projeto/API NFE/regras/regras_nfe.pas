unit regras_nfe;

interface

uses
 System.SysUtils,
 System.Classes,
 vcl.forms,
 Vcl.Dialogs,
 FireDAC.Comp.Client,
 System.JSON,
 DataSet.Serialize,
 parametros,
 Data.DB,
 ACBrNFe,
 pcnConversao,
 funcoes,
 pcnConversaonfe,
 pcnAuxiliar,
 ACBrDFeSSL,
 blcksock,
 Variants;


 function emitirNFE(usuario:TJSonValue; dados:dadosNfce): TJSonObject;
 function consultarNFE(usuario:TJSonValue; parametros:dadosConsulta; pagina:Integer;registros:Integer): TJSonObject;
 function cancelaNFE(usuario:TJSonValue;id,motivo:string)  : TJSonObject;
 function correcaoNFE(usuario:TJSonValue;id,motivo:string) : TJSonObject;
 function consultarEVENTOS(usuario:TJSonValue;id:string;pagina:Integer;registros:Integer): TJSonObject;
 function inutilizarNFE(usuario:TJSonValue;serie,numeroInicio,numeroFim:Int64;justificativa:string): TJSonObject;
 function consultarINUTILIZACOES(usuario:TJSonValue;pagina:Integer;registros:Integer): TJSonObject;
 function gravarRascunho(usuario:TJSonValue;jsonNota:string;tipoNota:integer;cliente:string;valor:string): TJSonObject;
 function buscaRascunhos(usuario:TJSonValue;parametros:consultaRascunhos;pagina:Integer;registros:Integer): TJSonObject;
 function removerRascunho(usuario:TJSonValue;codigoRascunho:string): TJSonObject;
 function atualizaRascunho(usuario:TJSonValue;codigoRascunho:string;jsonNota:string;cliente:string;valor:string): TJSonObject;


 implementation

 function emitirNFE(usuario:TJSonValue;dados:dadosNfce): TJSonObject;
  var
   nfe_componente       : TACBrNFe;
    i                    : integer;
   json                  : string;
   codigoHttp            : integer;
   mensagem              : string;
   tituloMensagem        : string;
   chave_nota            : string;
   query                 : TFDQuery;
   conexao               : TFDConnection;
   descontoRatedo        : Currency;
   aliquotaDescontoRateo : Currency;
   freteRatedo           : Currency;
   aliquotaFreteRateo    : Currency;
   outroRatedo           : Currency;
   aliquotaOutroRateo    : Currency;
   seguroRatedo          : Currency;
   aliquotaSeguroRateo   : Currency;
   valorParcelas         : currency;
   debitar               : integer;
   novaData              : Variant;
 begin

    if  StrToInt(usuario.FindValue('notasgratis').Value) > 0 then
       begin
         debitar := 1; // debitar das notas grátis
       end;

    if StrToInt(usuario.FindValue('notasgratis').Value) = 0 then
       begin
             novaData := usuario.FindValue('vencimentocredito').Value;
         if (StrToInt(usuario.FindValue('quantidadecredito').Value) >0) and (novaData >= now) then
            begin
              debitar := 2; //debitar dos créditos avulsos
            end else
                 begin
                         novaData := usuario.FindValue('vencimentolicenca').Value;
                      if novaData >= now then
                          begin
                            debitar := 3; // debitar do plano atual
                          end else
                               begin // o cliente não tem nenhum saldo e nenhum plano ativo
                                  tituloMensagem := 'Oops você não tem saldo';
                                  mensagem       := 'contrate algum plano ou compre créditos';
                                  codigoHttp     := 401;

                                  json := '{ '+
                                   ' "mensagemRetorno": {  '+
                                   ' "titulo": "'+ tituloMensagem  +'", '+
                                   ' "mensagem": "'+ mensagem  +'" '+
                                   ' }, '+
                                   ' "dadosRetorno": [], '+
                                   ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                   ' }' ;

                                  Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                  FreeAndNil(nfe_componente);
                                  Exit;
                               end;
                 end;
       end;


    nfe_componente      := TACBrNFe.Create(nil);
    nfe_componente.NotasFiscais.Clear;
    nfe_componente.NotasFiscais.Add;

    try
      {web service}
       try
         nfe_componente.Configuracoes.WebServices.TimeOut                 := 900000;
         nfe_componente.Configuracoes.WebServices.Tentativas              := 1000;
         nfe_componente.Configuracoes.WebServices.IntervaloTentativas     := 100;
         nfe_componente.Configuracoes.WebServices.uf                      := usuario.FindValue('ufempresa').Value;
         nfe_componente.Configuracoes.Geral.VersaoDF                      := ve400;
         nfe_componente.Configuracoes.Geral.SSLLib                        := libWinCrypt;
         nfe_componente.Configuracoes.Geral.SSLCryptLib                   := cryWinCrypt;
         nfe_componente.Configuracoes.Geral.SSLHttpLib                    := httpWinHttp;
         nfe_componente.Configuracoes.Geral.SSLXmlSignLib                 := xsLibXml2;
         nfe_componente.SSL.SSLType                                       := LT_TLSv1_2;
         nfe_componente.Configuracoes.Arquivos.Salvar                     := false;
         nfe_componente.Configuracoes.Arquivos.SalvarEvento               := False;
         nfe_componente.Configuracoes.Arquivos.SalvarApenasNFeProcessadas := false;
         nfe_componente.NotasFiscais[0].NFe.infNFe.Versao                 := 4.0;
         nfe_componente.Configuracoes.Arquivos.PathSchemas                := './Schemas';

          if usuario.FindValue('nfeambiente').Value = '1' then
            begin
             nfe_componente.Configuracoes.WebServices.Ambiente            := taProducao;
             nfe_componente.NotasFiscais[0].nfe.ide.tpamb                 := taProducao;
            end else
                 begin
                   nfe_componente.NotasFiscais[0].nfe.ide.tpamb           := tahomologacao;
                   nfe_componente.Configuracoes.WebServices.Ambiente      := taHomologacao;
                 end;

          except
            on E: Exception do
             begin
                tituloMensagem := 'Erro interno(web service)';
                mensagem       :=  funcoes.RemoveAcento(e.Message);
                codigoHttp     :=  500;
                funcoes.logErro(e.Message);

              json := '{ '+
                 ' "mensagemRetorno": {  '+
                 ' "titulo": "'+ tituloMensagem  +'", '+
                 ' "mensagem": "'+ mensagem  +'" '+
                 ' }, '+
                 ' "dadosRetorno": [], '+
                 ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                 ' }' ;

                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                FreeAndNil(nfe_componente);
                Exit;
             end;
       end;


      {dados do emissor}
        try
           if usuario.FindValue('regimeempresa').Value                 = '1' then nfe_componente.NotasFiscais[0].nfe.emit.Crt := crtSimplesNacional;
           if usuario.FindValue('regimeempresa').Value                 = '2' then nfe_componente.NotasFiscais[0].nfe.emit.Crt := crtSimplesExcessoReceita;
           if usuario.FindValue('regimeempresa').Value                 = '3' then nfe_componente.NotasFiscais[0].nfe.emit.Crt := crtregimenormal;

           nfe_componente.NotasFiscais[0].nfe.emit.cnpjcpf            := funcoes.somenteNumeros(usuario.FindValue('cnpjempresa').Value);
           nfe_componente.NotasFiscais[0].nfe.emit.XNOME              := usuario.FindValue('razaoempresa').Value;
           nfe_componente.NotasFiscais[0].nfe.emit.Xfant              := usuario.FindValue('fantasiaempresa').Value;
           nfe_componente.NotasFiscais[0].nfe.emit.IE                 := usuario.FindValue('ieempresa').Value;
           nfe_componente.NotasFiscais[0].nfe.emit.CNAE               := usuario.FindValue('cnaeempresa').Value;
           nfe_componente.NotasFiscais[0].nfe.emit.enderemit.fone     := usuario.FindValue('telefoneempresa').Value;
           nfe_componente.NotasFiscais[0].nfe.emit.enderemit.CEP      := StrToInt(funcoes.somenteNumeros(usuario.FindValue('cepempresa').Value));
           nfe_componente.NotasFiscais[0].nfe.emit.enderemit.XLGR     := usuario.FindValue('enderecoempresa').Value;

           if trim(funcoes.somenteNumeros(usuario.FindValue('numeroempresa').Value)) <> '' then
            begin
              nfe_componente.NotasFiscais[0].nfe.emit.enderemit.nro      := usuario.FindValue('numeroempresa').Value;
            end else
                 begin
                  nfe_componente.NotasFiscais[0].nfe.emit.enderemit.nro  := 'SN';
                 end;

           nfe_componente.NotasFiscais[0].nfe.emit.enderemit.CMUN     := StrToInt(usuario.FindValue('ibgemunicipio').Value);
           nfe_componente.NotasFiscais[0].nfe.emit.enderemit.xmun     := usuario.FindValue('cidadeempresa').Value;
           nfe_componente.NotasFiscais[0].nfe.emit.enderemit.xBairro  := usuario.FindValue('bairroempresa').Value;
           nfe_componente.NotasFiscais[0].nfe.emit.enderemit.uf       := usuario.FindValue('ufempresa').Value;
           nfe_componente.NotasFiscais[0].nfe.emit.enderemit.CPAIS    := 1058;
           nfe_componente.NotasFiscais[0].nfe.emit.enderemit.XPAIS    := 'BRASIL';

         except
            on E: Exception do
             begin
                tituloMensagem := 'Erro interno(dados do emissor)';
                mensagem       :=  funcoes.RemoveAcento(e.Message);
                codigoHttp     :=  500;
                funcoes.logErro(e.Message);

              json := '{ '+
                 ' "mensagemRetorno": {  '+
                 ' "titulo": "'+ tituloMensagem  +'", '+
                 ' "mensagem": "'+ mensagem  +'" '+
                 ' }, '+
                 ' "dadosRetorno": [], '+
                 ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                 ' }' ;

                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                FreeAndNil(nfe_componente);
                Exit;
             end;
        end;

      {dados do cliente}
       try
         if dados.destinatario.info.tipoContribuinte  = 1 then nfe_componente.NotasFiscais[0].nfe.Dest.indIEDest := inContribuinte;
         if dados.destinatario.info.tipoContribuinte  = 2 then nfe_componente.NotasFiscais[0].nfe.Dest.indIEDest := inNaoContribuinte;
         if dados.destinatario.info.tipoContribuinte  = 3 then nfe_componente.NotasFiscais[0].nfe.Dest.indIEDest := inIsento;

         nfe_componente.NotasFiscais[0].nfe.Dest.cnpjcpf            := dados.destinatario.info.cpfCnpj;
         nfe_componente.NotasFiscais[0].nfe.Dest.XNOME              := dados.destinatario.info.nomeRazao;
         nfe_componente.NotasFiscais[0].nfe.Dest.IE                 := dados.destinatario.info.inscricaoEstadual;
         nfe_componente.NotasFiscais[0].nfe.Dest.EnderDest.xLgr     := dados.destinatario.infoEndereco.endereco;


         if funcoes.somenteNumeros(dados.destinatario.infoEndereco.numero) <> '' then
            begin
              nfe_componente.NotasFiscais[0].nfe.Dest.EnderDest.nro      := dados.destinatario.infoEndereco.numero;
            end else
                 begin
                  nfe_componente.NotasFiscais[0].nfe.Dest.EnderDest.nro  := 'SN';
                 end;

         nfe_componente.NotasFiscais[0].nfe.Dest.EnderDest.xCpl     := funcoes.limiteCaracteres(60,dados.destinatario.infoEndereco.complemento);
         nfe_componente.NotasFiscais[0].nfe.Dest.EnderDest.xBairro  := funcoes.limiteCaracteres(60,dados.destinatario.infoEndereco.bairro);
         nfe_componente.NotasFiscais[0].nfe.Dest.EnderDest.xMun     := funcoes.limiteCaracteres(60,dados.destinatario.infoEndereco.cidade);
         nfe_componente.NotasFiscais[0].nfe.Dest.EnderDest.UF       := dados.destinatario.infoEndereco.uf;
         nfe_componente.NotasFiscais[0].nfe.Dest.EnderDest.cPais    := dados.destinatario.infoEndereco.codigoPais;
         nfe_componente.NotasFiscais[0].nfe.Dest.EnderDest.XPAIS    := dados.destinatario.infoEndereco.pais;
         nfe_componente.NotasFiscais[0].nfe.Dest.EnderDest.fone     := dados.destinatario.info.telefone;

         if dados.destinatario.infoEndereco.codigoPais <> 1058 then {CLIENTE FORA DO PAIS}
            begin
              nfe_componente.NotasFiscais[0].nfe.Dest.EnderDest.cMun := 9999999;
              nfe_componente.NotasFiscais[0].nfe.Dest.EnderDest.xMun := 'EXTERIOR';
              nfe_componente.NotasFiscais[0].nfe.Dest.idEstrangeiro  := dados.destinatario.info.cpfCnpj;
            end else
                 begin
                   nfe_componente.NotasFiscais[0].nfe.Dest.EnderDest.cMun     := strtoint(dados.destinatario.infoEndereco.codigoCidade);
                   nfe_componente.NotasFiscais[0].nfe.Dest.EnderDest.CEP  := StrToInt(funcoes.somenteNumeros(dados.destinatario.infoEndereco.cep));
                 end;

           except
            on E: Exception do
             begin
                tituloMensagem := 'Erro interno(dados do cliente)';
                mensagem       :=  funcoes.RemoveAcento(e.Message);
                codigoHttp     :=  500;
                funcoes.logErro(e.Message);

              json := '{ '+
                 ' "mensagemRetorno": {  '+
                 ' "titulo": "'+ tituloMensagem  +'", '+
                 ' "mensagem": "'+ mensagem  +'" '+
                 ' }, '+
                 ' "dadosRetorno": [], '+
                 ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                 ' }' ;

                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                FreeAndNil(nfe_componente);
                Exit;
             end;
       end;


           {dados do frete}
           with nfe_componente.NotasFiscais[0].nfe do
           begin
               try

                    {transportadora}
                     try
                      Transp.Transporta.CNPJCPF  := funcoes.somenteNumeros(dados.frete.transporte.cpfCnpj);
                      Transp.Transporta.xNome    := UpperCase(dados.frete.transporte.nome);
                      Transp.Transporta.IE       := dados.frete.transporte.ie;
                      Transp.Transporta.xEnder   := UpperCase(dados.frete.transporte.endereco);
                      Transp.Transporta.xMun     := UpperCase(dados.frete.transporte.municipio);
                      Transp.Transporta.UF       := UpperCase(dados.frete.transporte.uf);
                      except
                      {opcional}
                     end;


                    {veiculo}
                     try
                      Transp.veicTransp.placa    := dados.frete.transporte.infoVeiculo.placa;
                      Transp.veicTransp.UF       := dados.frete.transporte.infoVeiculo.uf;
                      Transp.veicTransp.RNTC     := dados.frete.transporte.infoVeiculo.rntc;
                      except
                      {opcional}
                     end;


                    {volume}
                     try
                       with Transp.Vol.Add do
                         begin
                          qVol  := dados.frete.volume.quantidadeVolume;
                          esp   := UpperCase(dados.frete.volume.especie);
                          marca := UpperCase(dados.frete.volume.marca);
                          nVol  := dados.frete.volume.numeroVolume;
                          pesoL := dados.frete.volume.pesoLiquido;
                          pesoB := dados.frete.volume.pesoBruto;
                         end;
                      except
                      {opcional}
                     end;

                    {tipo de frete}
                    if dados.frete.modoFrete.tipoFrete = 1 then transp.modFrete  := mfContaEmitente;
                    if dados.frete.modoFrete.tipoFrete = 2 then transp.modFrete  := mfContaDestinatario;
                    if dados.frete.modoFrete.tipoFrete = 3 then transp.modFrete  := mfContaTerceiros;
                    if dados.frete.modoFrete.tipoFrete = 4 then transp.modFrete  := mfSemFrete;

                   except
                    on E: Exception do
                     begin
                        tituloMensagem := 'Erro interno(dados do frete)';
                        mensagem       :=  funcoes.RemoveAcento(e.Message);
                        codigoHttp     :=  500;
                        funcoes.logErro(e.Message);

                      json := '{ '+
                         ' "mensagemRetorno": {  '+
                         ' "titulo": "'+ tituloMensagem  +'", '+
                         ' "mensagem": "'+ mensagem  +'" '+
                         ' }, '+
                         ' "dadosRetorno": [], '+
                         ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                         ' }' ;

                        Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                        FreeAndNil(nfe_componente);
                        Exit;
                     end;
               end;
           end;



       {dados dos produtos}
       try
           for I := 0 to  High(dados.infProduto) do
           begin
             with nfe_componente.NotasFiscais[0].nfe.Det.Add do
                 begin
                  Prod.NCM               := dados.infProduto[i].ncm;
                  Prod.uCom              := dados.infProduto[i].medida;
                  Prod.uTrib             := dados.infProduto[i].medida;
                  Prod.nitem             := i+1;

                  if  trim(dados.infProduto[i].codigoInterno) = '' then
                      begin
                        Prod.cProd := IntToStr(Prod.nitem);
                      end else
                           begin
                             Prod.cProd  := dados.infProduto[i].codigoInterno;
                           end;

                  Prod.xProd             := dados.infProduto[i].descricao;
                  Prod.vUnCom            := dados.infProduto[i].valorUnitario;
                  Prod.cEAN              := dados.infProduto[i].ean;
                  Prod.cEANTrib          := dados.infProduto[i].ean;
                  Prod.qCom              := dados.infProduto[i].quantidade;
                  Prod.vOutro            := dados.infProduto[i].valorAcrescimo;
                  Prod.qTrib             := dados.infProduto[i].quantidade;
                  Prod.vUnTrib           := dados.infProduto[i].valorUnitario;

                  if (dados.destinatario.infoEndereco.uf <> usuario.FindValue('ufempresa').Value)  or (dados.destinatario.infoEndereco.codigoPais <> 1058)   then
                      begin
                        Prod.CFOP := dados.natureza.cfopExterno;
                      end else
                            begin
                              Prod.CFOP  := dados.natureza.cfopInterno;
                            end;

                  Prod.IndTot            := itSomaTotalNFe;
                  Prod.CEST              := dados.infProduto[i].cest;
                  Prod.vDesc             := dados.infProduto[i].valorDesconto;
                  Prod.vProd             := dados.infProduto[i].valorUnitario*dados.infProduto[i].quantidade;

                     {tributação gás e gasolina}
                    try
                      prod.comb.cProdANP     := StrToInt(dados.infProduto[i].impostos.anp.codigo);
                      Prod.comb.UFcons       := dados.destinatario.infoEndereco.uf;
                      Prod.comb.descANP      := dados.infProduto[i].impostos.anp.descricao;
                     except
                      {opcional}
                    end;

                 // prod.comb.pGLP         := StrToCurr(produtos.PERC_GLP.Strings[i]);
                 // Prod.comb.pGNn         := StrToCurr(produtos.PERC_GAS.Strings[i]);
                 // Prod.comb.pGNi         := StrToCurr(produtos.PERC_GAS_IMPORT.Strings[i]);
                 // Prod.comb.vPart        := StrToCurr(produtos.VALOR_PARTIDA.Strings[i]);
                  /////////////////////////////////////////////////////////////////////////

                  {outros pagamentos}

                   if dados.outros.valorSeguro > 0.01 then
                      begin
                       aliquotaSeguroRateo   := 0;
                       seguroRatedo          := 0;
                       aliquotaSeguroRateo   := Prod.vUnCom /Prod.vProd;
                       seguroRatedo          := aliquotaSeguroRateo * dados.outros.valorSeguro;
                       Prod.vSeg             := seguroRatedo /Length(dados.infProduto) * dados.infProduto[i].quantidade ;
                      end;


                   try
                     if dados.frete.modoFrete.valor > 0.01 then
                        begin
                         aliquotaFreteRateo  := 0;
                         freteRatedo         := 0;
                         aliquotaFreteRateo  := Prod.vUnCom / Prod.vProd;
                         freteRatedo         := aliquotaFreteRateo * dados.frete.modoFrete.valor;
                         Prod.vFrete         := freteRatedo /Length(dados.infProduto) * dados.infProduto[i].quantidade;
                        end;
                    except
                       {opcional}
                   end;


                  {Cáculo de outros impostos}
                    imposto.ICMS.vBC       := dados.infProduto[i].impostos.icms.bcIcms;
                    imposto.ICMS.pICMS     := dados.infProduto[i].impostos.icms.aliquota; {aliquota}
                    Imposto.ICMS.vICMS     := Imposto.ICMS.vBC * Imposto.ICMS.pICMS /100;

                    imposto.PIS.vBC        := Prod.vProd - Prod.vDesc + Prod.vOutro;
                    imposto.PIS.pPIS       := dados.infProduto[i].impostos.pis.aliquota;
                    imposto.PIS.vPIS       := Imposto.PIS.vBC * Imposto.PIS.pPIS /100;

                    Imposto.COFINS.vBC     := Prod.vProd - Prod.vDesc + Prod.vOutro;
                    Imposto.COFINS.pCOFINS := dados.infProduto[i].impostos.cofins.aliquota;
                    imposto.COFINS.vCOFINS := Imposto.COFINS.vBC * Imposto.COFINS.pCOFINS /100;

                    Imposto.IPI.vBC        := Prod.vProd - Prod.vDesc + Prod.vOutro;
                    Imposto.IPI.pIPI       := dados.infProduto[i].impostos.ipi.aliquota;
                    Imposto.IPI.vIPI       := Imposto.IPI.vBC * Imposto.IPI.pIPI /100 ;



                 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                    {TOTAIS DA NOTA FISCAL}
                   with nfe_componente.NotasFiscais[0].nfe do
                    begin
                       total.ICMSTot.vProd    := total.ICMSTot.vProd    + 0 + Prod.vProd;
                       total.ICMSTot.vIPI     := total.ICMSTot.vIPI     + 0 + Imposto.IPI.vIPI;
                       total.ICMSTot.vICMS    := total.ICMSTot.vICMS    + 0 + Imposto.ICMS.vICMS;
                       total.ICMSTot.vBC      := total.ICMSTot.vBC      + 0 + imposto.ICMS.vBC;
                       total.ICMSTot.vCOFINS  := total.ICMSTot.vCOFINS  + 0 + imposto.COFINS.vCOFINS;
                       total.ICMSTot.vPIS     := total.ICMSTot.vPIS     + 0 + imposto.PIS.vPIS;
                       total.ICMSTot.vDesc    := total.ICMSTot.vDesc    + 0 + Prod.vDesc;
                       total.ICMSTot.vOutro   := total.ICMSTot.vOutro   + 0 + Prod.vOutro;
                       total.ICMSTot.vSeg     := total.ICMSTot.vSeg     + 0 + Prod.vSeg;
                       total.ICMSTot.vFrete   := total.ICMSTot.vFrete   + 0 + Prod.vFrete;
                       total.ICMSTot.vNF      := total.ICMSTot.vProd    + 0 + total.ICMSTot.vOutro+total.ICMSTot.vIPI+ Total.ICMSTot.vST +Total.ICMSTot.vFrete +Total.ICMSTot.vSeg + Total.ICMSTot.vII+total.ICMSTot.vST - total.ICMSTot.vDesc;

                 {     tb_federal             := tb_federal             + 0 + StrToCurr(produtos.preco.Strings[i]) * StrToCurr(produtos.IMPOSTO_FEDERAL.Strings[i]) / 100;
                       tb_municipal           := tb_municipal           + 0 + StrToCurr(produtos.preco.Strings[i]) * StrToCurr(produtos.IMPOSTO_MUNICIPAL.Strings[i]) / 100;
                       tb_estadual            := tb_estadual            + 0 + StrToCurr(produtos.preco.Strings[i]) * StrToCurr(produtos.IMPOSTO_ESTADUAL.Strings[i]) / 100;
                       total_tb               := tb_estadual + tb_municipal + tb_federal;
                       versao_ibpt            := produtos.VERSAO_IBPT;     }
                    end;


                  {TRIBUTAÇÃO ICMS}
                  if dados.infProduto[i].impostos.icms.tributacao   = 0     then Imposto.ICMS.CST   := cst00;
                  if dados.infProduto[i].impostos.icms.tributacao   = 10    then Imposto.ICMS.CST   := cst10;
                  if dados.infProduto[i].impostos.icms.tributacao   = 20    then Imposto.ICMS.CST   := cst20;
                  if dados.infProduto[i].impostos.icms.tributacao   = 30    then Imposto.ICMS.CST   := cst30;
                  if dados.infProduto[i].impostos.icms.tributacao   = 40    then Imposto.ICMS.CST   := cst40;
                  if dados.infProduto[i].impostos.icms.tributacao   = 41    then Imposto.ICMS.CST   := cst41;
                  if dados.infProduto[i].impostos.icms.tributacao   = 50    then Imposto.ICMS.CST   := cst50;
                  if dados.infProduto[i].impostos.icms.tributacao   = 51    then Imposto.ICMS.CST   := cst51;
                  if dados.infProduto[i].impostos.icms.tributacao   = 60    then Imposto.ICMS.CST   := cst60;
                  if dados.infProduto[i].impostos.icms.tributacao   = 70    then Imposto.ICMS.CST   := cst70;
                  if dados.infProduto[i].impostos.icms.tributacao   = 90    then Imposto.ICMS.CST   := cst90;

                   //REGRAS ICMS PARA FORA DO PAIS//
                  if dados.destinatario.infoEndereco.codigoPais <> 1058     then
                     begin
                       Imposto.ICMS.CST   := cst41;
                     end;

                  {TRIBUTAÇÃO IPI}
                  if dados.infProduto[i].impostos.ipi.tributacao    = 0     then Imposto.IPI.CST    := ipi00;
                  if dados.infProduto[i].impostos.ipi.tributacao    = 1     then Imposto.IPI.CST    := ipi01;
                  if dados.infProduto[i].impostos.ipi.tributacao    = 2     then Imposto.IPI.CST    := ipi02;
                  if dados.infProduto[i].impostos.ipi.tributacao    = 3     then Imposto.IPI.CST    := ipi03;
                  if dados.infProduto[i].impostos.ipi.tributacao    = 4     then Imposto.IPI.CST    := ipi04;
                  if dados.infProduto[i].impostos.ipi.tributacao    = 5     then Imposto.IPI.CST    := ipi05;
                  if dados.infProduto[i].impostos.ipi.tributacao    = 49    then Imposto.IPI.CST    := ipi49;
                  if dados.infProduto[i].impostos.ipi.tributacao    = 50    then Imposto.IPI.CST    := ipi50;
                  if dados.infProduto[i].impostos.ipi.tributacao    = 51    then Imposto.IPI.CST    := ipi51;
                  if dados.infProduto[i].impostos.ipi.tributacao    = 52    then Imposto.IPI.CST    := ipi52;
                  if dados.infProduto[i].impostos.ipi.tributacao    = 53    then Imposto.IPI.CST    := ipi53;
                  if dados.infProduto[i].impostos.ipi.tributacao    = 54    then Imposto.IPI.CST    := ipi54;
                  if dados.infProduto[i].impostos.ipi.tributacao    = 55    then Imposto.IPI.CST    := ipi55;
                  if dados.infProduto[i].impostos.ipi.tributacao    = 99    then Imposto.IPI.CST    := ipi99;

                  {TRIBUTAÇÃO COFINS}
                  if dados.infProduto[i].impostos.cofins.tributacao = 1     then Imposto.COFINS.CST := cof01;
                  if dados.infProduto[i].impostos.cofins.tributacao = 2     then Imposto.COFINS.CST := cof02;
                  if dados.infProduto[i].impostos.cofins.tributacao = 3     then Imposto.COFINS.CST := cof03;
                  if dados.infProduto[i].impostos.cofins.tributacao = 4     then Imposto.COFINS.CST := cof04;
                  if dados.infProduto[i].impostos.cofins.tributacao = 5     then Imposto.COFINS.CST := cof05;
                  if dados.infProduto[i].impostos.cofins.tributacao = 6     then Imposto.COFINS.CST := cof06;
                  if dados.infProduto[i].impostos.cofins.tributacao = 7     then Imposto.COFINS.CST := cof07;
                  if dados.infProduto[i].impostos.cofins.tributacao = 8     then Imposto.COFINS.CST := cof08;
                  if dados.infProduto[i].impostos.cofins.tributacao = 9     then Imposto.COFINS.CST := cof09;
                  if dados.infProduto[i].impostos.cofins.tributacao = 49    then Imposto.COFINS.CST := cof49;
                  if dados.infProduto[i].impostos.cofins.tributacao = 50    then Imposto.COFINS.CST := cof50;
                  if dados.infProduto[i].impostos.cofins.tributacao = 51    then Imposto.COFINS.CST := cof51;
                  if dados.infProduto[i].impostos.cofins.tributacao = 52    then Imposto.COFINS.CST := cof52;
                  if dados.infProduto[i].impostos.cofins.tributacao = 53    then Imposto.COFINS.CST := cof53;
                  if dados.infProduto[i].impostos.cofins.tributacao = 54    then Imposto.COFINS.CST := cof54;
                  if dados.infProduto[i].impostos.cofins.tributacao = 55    then Imposto.COFINS.CST := cof55;
                  if dados.infProduto[i].impostos.cofins.tributacao = 56    then Imposto.COFINS.CST := cof56;
                  if dados.infProduto[i].impostos.cofins.tributacao = 60    then Imposto.COFINS.CST := cof60;
                  if dados.infProduto[i].impostos.cofins.tributacao = 61    then Imposto.COFINS.CST := cof61;
                  if dados.infProduto[i].impostos.cofins.tributacao = 62    then Imposto.COFINS.CST := cof62;
                  if dados.infProduto[i].impostos.cofins.tributacao = 63    then Imposto.COFINS.CST := cof63;
                  if dados.infProduto[i].impostos.cofins.tributacao = 64    then Imposto.COFINS.CST := cof64;
                  if dados.infProduto[i].impostos.cofins.tributacao = 65    then Imposto.COFINS.CST := cof65;
                  if dados.infProduto[i].impostos.cofins.tributacao = 66    then Imposto.COFINS.CST := cof66;
                  if dados.infProduto[i].impostos.cofins.tributacao = 67    then Imposto.COFINS.CST := cof67;
                  if dados.infProduto[i].impostos.cofins.tributacao = 70    then Imposto.COFINS.CST := cof70;
                  if dados.infProduto[i].impostos.cofins.tributacao = 71    then Imposto.COFINS.CST := cof71;
                  if dados.infProduto[i].impostos.cofins.tributacao = 72    then Imposto.COFINS.CST := cof72;
                  if dados.infProduto[i].impostos.cofins.tributacao = 73    then Imposto.COFINS.CST := cof73;
                  if dados.infProduto[i].impostos.cofins.tributacao = 74    then Imposto.COFINS.CST := cof74;
                  if dados.infProduto[i].impostos.cofins.tributacao = 75    then Imposto.COFINS.CST := cof75;
                  if dados.infProduto[i].impostos.cofins.tributacao = 98    then Imposto.COFINS.CST := cof98;
                  if dados.infProduto[i].impostos.cofins.tributacao = 99    then Imposto.COFINS.CST := cof99;

                  {TRIBUTAÇÃO PIS}
                  if dados.infProduto[i].impostos.pis.tributacao   = 1      then Imposto.PIS.CST    := pis01;
                  if dados.infProduto[i].impostos.pis.tributacao   = 2      then Imposto.PIS.CST    := pis02;
                  if dados.infProduto[i].impostos.pis.tributacao   = 3      then Imposto.PIS.CST    := pis03;
                  if dados.infProduto[i].impostos.pis.tributacao   = 4      then Imposto.PIS.CST    := pis04;
                  if dados.infProduto[i].impostos.pis.tributacao   = 5      then Imposto.PIS.CST    := pis05;
                  if dados.infProduto[i].impostos.pis.tributacao   = 6      then Imposto.PIS.CST    := pis06;
                  if dados.infProduto[i].impostos.pis.tributacao   = 7      then Imposto.PIS.CST    := pis07;
                  if dados.infProduto[i].impostos.pis.tributacao   = 8      then Imposto.PIS.CST    := pis08;
                  if dados.infProduto[i].impostos.pis.tributacao   = 9      then Imposto.PIS.CST    := pis09;
                  if dados.infProduto[i].impostos.pis.tributacao   = 49     then Imposto.PIS.CST    := pis49;
                  if dados.infProduto[i].impostos.pis.tributacao   = 50     then Imposto.PIS.CST    := pis50;
                  if dados.infProduto[i].impostos.pis.tributacao   = 51     then Imposto.PIS.CST    := pis51;
                  if dados.infProduto[i].impostos.pis.tributacao   = 52     then Imposto.PIS.CST    := pis52;
                  if dados.infProduto[i].impostos.pis.tributacao   = 53     then Imposto.PIS.CST    := pis53;
                  if dados.infProduto[i].impostos.pis.tributacao   = 54     then Imposto.PIS.CST    := pis54;
                  if dados.infProduto[i].impostos.pis.tributacao   = 55     then Imposto.PIS.CST    := pis55;
                  if dados.infProduto[i].impostos.pis.tributacao   = 56     then Imposto.PIS.CST    := pis56;
                  if dados.infProduto[i].impostos.pis.tributacao   = 60     then Imposto.PIS.CST    := pis60;
                  if dados.infProduto[i].impostos.pis.tributacao   = 61     then Imposto.PIS.CST    := pis61;
                  if dados.infProduto[i].impostos.pis.tributacao   = 62     then Imposto.PIS.CST    := pis62;
                  if dados.infProduto[i].impostos.pis.tributacao   = 63     then Imposto.PIS.CST    := pis63;
                  if dados.infProduto[i].impostos.pis.tributacao   = 64     then Imposto.PIS.CST    := pis64;
                  if dados.infProduto[i].impostos.pis.tributacao   = 65     then Imposto.PIS.CST    := pis65;
                  if dados.infProduto[i].impostos.pis.tributacao   = 66     then Imposto.PIS.CST    := pis66;
                  if dados.infProduto[i].impostos.pis.tributacao   = 67     then Imposto.PIS.CST    := pis67;
                  if dados.infProduto[i].impostos.pis.tributacao   = 70     then Imposto.PIS.CST    := pis70;
                  if dados.infProduto[i].impostos.pis.tributacao   = 71     then Imposto.PIS.CST    := pis71;
                  if dados.infProduto[i].impostos.pis.tributacao   = 72     then Imposto.PIS.CST    := pis72;
                  if dados.infProduto[i].impostos.pis.tributacao   = 73     then Imposto.PIS.CST    := pis73;
                  if dados.infProduto[i].impostos.pis.tributacao   = 74     then Imposto.PIS.CST    := pis74;
                  if dados.infProduto[i].impostos.pis.tributacao   = 75     then Imposto.PIS.CST    := pis75;
                  if dados.infProduto[i].impostos.pis.tributacao   = 98     then Imposto.PIS.CST    := pis98;
                  if dados.infProduto[i].impostos.pis.tributacao   = 99     then imposto.PIS.CST    := pis99;

                 {BASE DE CALCULO ICMS ADIONAR ESSA OPÇÃO NO APP }
                  { if produtos.cod_MOD_BC.Strings[i]     = '0'     then Imposto.ICMS.modBC := dbiMargemValorAgregado;
                  if produtos.cod_MOD_BC.Strings[i]     = '1'     then Imposto.ICMS.modBC := dbiPauta;
                  if produtos.cod_MOD_BC.Strings[i]     = '2'     then Imposto.ICMS.modBC := dbiPrecoTabelado;
                  if produtos.cod_MOD_BC.Strings[i]     = '3'     then Imposto.ICMS.modBC := dbiValorOperacao;  }


                  {OGRIGEM DO PRODUTO}
                  if dados.infProduto[i].impostos.icms.origemProduto     = 0     then imposto.ICMS.orig  := oeNacional;
                  if dados.infProduto[i].impostos.icms.origemProduto     = 1     then imposto.ICMS.orig  := oeEstrangeiraImportacaoDireta;
                  if dados.infProduto[i].impostos.icms.origemProduto     = 2     then imposto.ICMS.orig  := oeEstrangeiraAdquiridaBrasil;
                  if dados.infProduto[i].impostos.icms.origemProduto     = 3     then imposto.ICMS.orig  := oeNacionalConteudoImportacaoSuperior40;
                  if dados.infProduto[i].impostos.icms.origemProduto     = 4     then imposto.ICMS.orig  := oeNacionalProcessosBasicos;
                  if dados.infProduto[i].impostos.icms.origemProduto     = 5     then imposto.ICMS.orig  := oeNacionalConteudoImportacaoInferiorIgual40;
                  if dados.infProduto[i].impostos.icms.origemProduto     = 6     then imposto.ICMS.orig  := oeEstrangeiraImportacaoDiretaSemSimilar;
                  if dados.infProduto[i].impostos.icms.origemProduto     = 7     then imposto.ICMS.orig  := oeEstrangeiraAdquiridaBrasilSemSimilar;
                  if dados.infProduto[i].impostos.icms.origemProduto     = 8     then imposto.ICMS.orig  := oeNacionalConteudoImportacaoSuperior70;

                  {JURIDICA DO SIMPLES CST - CSOSN}
                 // if dados.infProduto[i].impostos.icms.csosn   = 0      then Imposto.ICMS.CSOSN := csosnVazio;
                  if dados.infProduto[i].impostos.icms.csosn   = 101    then Imposto.ICMS.CSOSN := csosn101;
                  if dados.infProduto[i].impostos.icms.csosn   = 102    then Imposto.ICMS.CSOSN := csosn102;
                  if dados.infProduto[i].impostos.icms.csosn   = 103    then Imposto.ICMS.CSOSN := csosn103;
                  if dados.infProduto[i].impostos.icms.csosn   = 201    then Imposto.ICMS.CSOSN := csosn201;
                  if dados.infProduto[i].impostos.icms.csosn   = 202    then Imposto.ICMS.CSOSN := csosn202;
                  if dados.infProduto[i].impostos.icms.csosn   = 203    then Imposto.ICMS.CSOSN := csosn203;
                  if dados.infProduto[i].impostos.icms.csosn   = 300    then Imposto.ICMS.CSOSN := csosn300;
                  if dados.infProduto[i].impostos.icms.csosn   = 400    then Imposto.ICMS.CSOSN := csosn400;
                  if dados.infProduto[i].impostos.icms.csosn   = 500    then Imposto.ICMS.CSOSN := csosn500;
                  if dados.infProduto[i].impostos.icms.csosn   = 900    then Imposto.ICMS.CSOSN := csosn900;
                 end;
           end;
           except
            on E: Exception do
             begin
                tituloMensagem := 'Erro interno(dados dos produtos)';
                mensagem       :=  funcoes.RemoveAcento(e.Message);
                codigoHttp     :=  500;
                funcoes.logErro(e.Message);

              json := '{ '+
                 ' "mensagemRetorno": {  '+
                 ' "titulo": "'+ tituloMensagem  +'", '+
                 ' "mensagem": "'+ mensagem  +'" '+
                 ' }, '+
                 ' "dadosRetorno": [], '+
                 ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                 ' }' ;

                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                FreeAndNil(nfe_componente);
                Exit;
             end;
       end;


              try
               for I := 0 to  High(dados.formaPagamento.pagamentos)  do

                    begin

                     if dados.formaPagamento.pagamentos[i].tipo = 1 then
                          begin
                             with nfe_componente.NotasFiscais[0].nfe.pag.Add do
                               begin
                                tPag := fpDinheiro;
                                vPag := dados.formaPagamento.pagamentos[i].valor - dados.formaPagamento.troco;
                               end;
                          end;


                     if dados.formaPagamento.pagamentos[i].tipo = 2 then
                          begin
                             with nfe_componente.NotasFiscais[0].nfe.pag.Add do
                               begin
                                tPag := fpCartaoCredito;
                                vPag := dados.formaPagamento.pagamentos[i].valor;
                               end;
                          end;


                     if dados.formaPagamento.pagamentos[i].tipo = 3 then
                          begin
                             with nfe_componente.NotasFiscais[0].nfe.pag.Add do
                               begin
                                tPag := fpCartaoDebito;
                                vPag := dados.formaPagamento.pagamentos[i].valor;
                               end;
                          end;


                     if dados.formaPagamento.pagamentos[i].tipo = 4 then
                          begin
                             with nfe_componente.NotasFiscais[0].nfe.pag.Add do
                               begin
                                tPag := fpPagamentoInstantaneo;
                                vPag := dados.formaPagamento.pagamentos[i].valor;
                               end;
                          end;


                     if dados.formaPagamento.pagamentos[i].tipo = 5 then
                          begin
                             with nfe_componente.NotasFiscais[0].nfe.pag.Add do
                               begin
                                tPag := fpDuplicataMercantil;
                                vPag := dados.formaPagamento.pagamentos[i].valor;
                               end;
                          end;

                     if dados.formaPagamento.pagamentos[i].tipo = 6 then
                          begin
                             with nfe_componente.NotasFiscais[0].nfe.pag.Add do
                               begin
                                tPag := fpSemPagamento;
                               // vPag := dados.pagamento.pagamentos[i].valor;
                               end;
                          end;

                    end;
              finally

              end;



         {duplicatas}
        try
           valorParcelas := 0;

           for I := 0 to  High(dados.duplicatas)  do
               begin
                 {fatura}
                  nfe_componente.NotasFiscais[0].nfe.cobr.fat.nFat  := '1';


                 with nfe_componente.NotasFiscais[0].nfe.cobr.Dup.Add do
                      begin
                        nDup          := IntToStr(i+1);
                        dVenc         := dados.duplicatas[i].vencimento;
                        vDup          := dados.duplicatas[i].valor;
                        valorParcelas := valorParcelas + vDup;
                      end;
               end;

             nfe_componente.NotasFiscais[0].nfe.cobr.fat.vOrig :=  valorParcelas;
             nfe_componente.NotasFiscais[0].nfe.cobr.fat.vLiq  :=  valorParcelas;
         except
           {serve como opcional}
        end;


        {dados finais da nota fiscal}
      with nfe_componente.NotasFiscais[0].nfe do
       begin
           // if fecha.hr_verao = '0' then ide.demi := StrToDateTime(formatdatetime('dd/mm/yyyy',now)+' '+formatdatetime('hh:mm:ss',now - StrToTime('00:00') ));
          //  if fecha.hr_verao = '1' then ide.demi := StrToDateTime(formatdatetime('dd/mm/yyyy',now)+' '+formatdatetime('hh:mm:ss',now - StrToTime('01:00') ));
          //  if fecha.hr_verao = '2' then ide.demi := StrToDateTime(formatdatetime('dd/mm/yyyy',now)+' '+formatdatetime('hh:mm:ss',now + StrToTime('01:00') ));
            Ide.verproc                                       := 'Kinotas';
            ProcNFe.Versao                                    := '4.0';

            ide.modelo                                        := 55;
            nfe_componente.Configuracoes.Geral.ModeloDF       := moNFe;

            if dados.info.tipoFinalidade = 1 then  ide.finnfe := fnnormal;
            if dados.info.tipoFinalidade = 2 then  ide.finnfe := fnComplementar;
            if dados.info.tipoFinalidade = 3 then  ide.finnfe := fnAjuste;
            if dados.info.tipoFinalidade = 4 then  ide.finnfe := fnDevolucao;

            ide.natop   := dados.natureza.descricao;

            ide.nnf     := StrToint(usuario.FindValue('nfenumero').Value)+1;
            ide.serie   := StrToint(usuario.FindValue('nfeserie').Value);
            ide.cuf     := StrToInt(usuario.FindValue('coduf').Value);
            ide.cmunfg  := StrToInt(usuario.FindValue('ibgemunicipio').Value);

            ide.demi    := StrToDateTime(formatdatetime('dd/mm/yyyy',now));
            nfe_componente.NotasFiscais[0].nfe.ide.tpEmis := tenormal;

            ide.indfinal    := cfConsumidorFinal;
            ide.indPres     := pcPresencial;
            ide.indIntermed := iiOperacaoSemIntermediador;

            InfAdic.infCpl :=  dados.info.dadosAdcionais;
            ide.procemi    :=  peaplicativocontribuinte;

            if funcoes.somenteNumeros(usuario.FindValue('contadorcnpj').Value).Length = 14 then
               begin
                autXML.Add.CNPJCPF :=  usuario.FindValue('contadorcnpj').Value;
               end;

            if dados.formaPagamento.tipoPagamento  = 1 then ide.indPag  :=  ipVista;
            if dados.formaPagamento.tipoPagamento  = 2 then ide.indPag  :=  ipPrazo;
            if dados.formaPagamento.tipoPagamento  = 3 then ide.indPag  :=  ipNenhum;

            if dados.info.tipoNota            = 1 then ide.tpNF    :=  tnsaida;
            if dados.info.tipoNota            = 2 then ide.tpNF    :=  tnentrada;


            if dados.destinatario.infoEndereco.codigoPais = 1058 then
               begin
                 if usuario.FindValue('ufempresa').Value =  dados.destinatario.infoEndereco.uf then
                    begin
                     Ide.idDest           := doInterna;
                    end else
                          begin
                           Ide.idDest     := doInterestadual;
                          end;
               end else
                    begin
                      Ide.idDest           := doExterior;
                      exporta.UFSaidaPais  := usuario.FindValue('ufempresa').Value;
                      exporta.UFembarq     := usuario.FindValue('ufempresa').Value;
                      exporta.xLocEmbarq   := usuario.FindValue('cidadeempresa').Value;
                      exporta.xLocExporta  := usuario.FindValue('cidadeempresa').Value;
                      exporta.xLocDespacho := usuario.FindValue('cidadeempresa').Value;
                    end;

                  try
                   for I := 0 to  High(dados.referencia)  do
                       begin
                        if pcnAuxiliar.ValidarChave(dados.referencia[i].chaveAcesso) = true then
                           begin
                             with Ide.NFref.Add do
                                 begin
                                   refNFe            := dados.referencia[i].chaveAcesso;
                                   RefNF.cUF         := StrToInt(refNFe[1]+ refNFe[2]);
                                   RefNF.AAMM        := refNFe[3]+ refNFe[4] + refNFe[5]+refNFe[6];
                                   RefNF.CNPJ        := dados.destinatario.info.cpfCnpj;
                                  // RefNF.modelo    := 2;
                                  // RefNF.serie     := 1;
                                  // RefNF.nNF       := 16291949;
                                 end;
                           end;
                       end;
                   except
                    {opcional}
                  end;


              ide.hSaiEnt :=  Ttime(now);
              ide.dSaiEnt :=  Tdate(now);

              {INFORMAÇÕES DO DESENVOLVEDOR}
                infRespTec.CNPJ     := '24204956000173';
                infRespTec.xContato := '62985924329';
                infRespTec.email    := 'suporte@sistemavendaki.com.br';
                infRespTec.fone     := '62985924329';
              {INFORMAÇÕES DO DESENVOLVEDOR}
       end;


       {certificado digital}
        try
          novaData := usuario.FindValue('validadecertificado').Value;

          if novaData < now then
              begin
                 tituloMensagem := 'Certificado digital vencido';
                 codigoHttp     :=  400;
                 json := '{ '+
                 ' "mensagemRetorno": {  '+
                 ' "mensagemSefaz": "'+ tituloMensagem+'" '+
                 ' }, '+

                 ' "dadosRetorno": [], '+
                 ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                 ' }' ;

                 Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                 FreeAndNil(nfe_componente);
                 Exit;
              end;


          nfe_componente.Configuracoes.Certificados.Senha            := funcoes.descript(usuario.FindValue('certificadosenha').Value);
          nfe_componente.Configuracoes.Certificados.ArquivoPFX       := '.\certificados\'+usuario.FindValue('codigousuario').Value+'.pfx';
          nfe_componente.Configuracoes.Arquivos.Salvar               := true;
          nfe_componente.NotasFiscais[0].Assinar;

           except
            on E: Exception do
             begin
                tituloMensagem := 'Erro interno (certificado digital)';
                mensagem       :=  funcoes.RemoveAcento(e.Message);
                codigoHttp     :=  500;
                funcoes.logErro(e.Message);

                json := '{ '+
                 ' "mensagemRetorno": {  '+
                 ' "mensagemSefaz": "'+ tituloMensagem+'" '+
                 ' }, '+

                 ' "dadosRetorno": [], '+
                 ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                 ' }' ;

                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                FreeAndNil(nfe_componente);
                Exit;
             end;
        end;



        {validar nota}
       try
           nfe_componente.NotasFiscais[0].Validar;

                except on E: Exception do
                begin
                 tituloMensagem := 'Erro na vialidacao (schema)';
                 mensagem       := funcoes.RemoveAcento(nfe_componente.NotasFiscais.Items[0].ErroValidacao);
                 codigoHttp     :=  404;

                  json := '{ '+
                     ' "mensagemRetorno": {  '+
                     ' "titulo": "'+ tituloMensagem  +'", '+
                     ' "mensagem": "'+ mensagem  +'" '+
                     ' }, '+
                     ' "dadosRetorno": [], '+
                     ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                     ' }' ;

                    Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                    FreeAndNil(nfe_componente);
                    Exit;
                end;
       end;


        {envia nota}
        try
          nfe_componente.Enviar(1,False, true);

          tituloMensagem   := 'Nota enviada com sucesso';
          codigoHttp       :=  201;

          chave_nota       :=  nfe_componente.NotasFiscais[0].NFe.infNFe.ID;
          Delete(chave_nota, 1, 3);


          conexao          := TFDConnection.Create(nil);
          query            := TFDQuery.Create(nil);
          query.Connection := conexao;

          conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);
          query.SQL.Add('UPDATE usuarios set nfenumero = '''+IntToStr(nfe_componente.NotasFiscais[0].NFe.Ide.nNF)+''' WHERE codigousuario = '''+usuario.FindValue('codigousuario').Value+'''');
          query.ExecSQL;


          query.SQL.Clear;
          query.SQL.Add ('INSERT INTO notas_nfe(id,serienota,numeronota,protocolo,chaveacesso,'+
                         'xmlnota,finalidade,valornota,statusnota,dataenvio,horaenvio,'+
                         'nomedestinatario,documentodestinatario,ambiente,tiponota,codusuario)values(');

          query.SQL.Add(''''  +funcoes.trigger+ '''');
          query.SQL.Add(',''' +IntToStr(nfe_componente.NotasFiscais[0].NFe.Ide.serie)+ '''');
          query.SQL.Add(',''' +IntToStr(nfe_componente.NotasFiscais[0].NFe.Ide.nNF)+ '''');
          query.SQL.Add(',''' +nfe_componente.NotasFiscais[0].NFe.procNFe.nProt+ '''');
          query.SQL.Add(',''' +chave_nota+ '''');
          query.SQL.Add(',:xml');
          query.SQL.Add(',''' +IntToStr(dados.info.tipoFinalidade)+ '''');
          query.SQL.Add(',:valor');
          query.SQL.Add(',''' +'ENVIADA'+ '''');
          query.SQL.Add(',''' +FormatDateTime('YYYY-MM-DD',NOW)  + '''');
          query.SQL.Add(',''' +TimeToStr(now)+ '''');
          query.SQL.Add(',''' +dados.destinatario.info.nomeRazao+ '''');
          query.SQL.Add(',''' +dados.destinatario.info.cpfCnpj+ '''');
          query.SQL.Add(',''' +usuario.FindValue('nfeambiente').Value+ '''');
          query.SQL.Add(',''' +'1'+ '''');
          query.SQL.Add(',''' +usuario.FindValue('codigousuario').Value+ ''')');

          query.Params[0].DataType := ftBlob;
          query.Params[0].Value    := nfe_componente.NotasFiscais[0].xml;

          query.Params[1].DataType := ftCurrency;
          query.Params[1].Value    := nfe_componente.NotasFiscais[0].nfe.total.ICMSTot.vNF;

          query.ExecSQL;



          if debitar = 1  then
               begin
                  query.SQL.Clear;
                  query.SQL.Add ('UPDATE usuarios set notasgratis = notasgratis - :quantidade where codigousuario = '''+usuario.FindValue('codigousuario').Value+'''');
                  query.Params[0].DataType := ftFloat;
                  query.Params[0].Value    := '1';
                  query.ExecSQL;
               end;


          if debitar = 2  then
               begin
                  query.SQL.Clear;
                  query.SQL.Add ('UPDATE usuarios set saldocredito = saldocredito - :menos , quantidadecredito = quantidadecredito - :quantidade, nfeusados = nfeusados + :usados  where codigousuario = '''+usuario.FindValue('codigousuario').Value+'''');
                  query.Params[0].DataType := ftFloat;
                  query.Params[0].Value    := 1.49;
                  query.Params[1].DataType := ftInteger;
                  query.Params[1].Value    := 1;
                  query.Params[2].DataType := ftInteger;
                  query.Params[2].Value    := 1;
                  query.ExecSQL;
               end;


              json := '{ '+
                 ' "mensagemRetorno": {  '+
                 ' "mensagemSefaz": {  '+
                 ' "statusSefaz": "'+ IntToStr(nfe_componente.NotasFiscais[0].cStat)+'", '+
                 ' "mensagemSefaz": "'+ funcoes.RemoveAcento(nfe_componente.NotasFiscais[0].msg)+'", '+
                 ' "protocolo": "'+ nfe_componente.NotasFiscais[0].NFe.procNFe.nProt+'", '+
                 ' "numero": "'+IntToStr(nfe_componente.NotasFiscais[0].NFe.Ide.nNF)+'", '+
                 ' "serie": "'+ IntToStr(nfe_componente.NotasFiscais[0].NFe.Ide.serie)+'", '+
                 ' "chaveAcesso": "'+ chave_nota+'" '+
                 ' } '+

                 ' }, '+

                 ' "dadosRetorno": [], '+
                 ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                 ' }' ;

                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                FreeAndNil(nfe_componente);
                freeandnil(query);
                FreeAndNil(conexao);
                Exit;

                except on E: Exception do
                begin

                 tituloMensagem := 'Erro interno (certificado digital)';
                 codigoHttp     :=  404;

                 json := '{ '+
                 ' "mensagemRetorno": {  '+
                 ' "mensagemSefaz": "'+ funcoes.RemoveAcento(e.Message) +'" '+
                 ' }, '+

                 ' "dadosRetorno": [], '+
                 ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                 ' }' ;

                    Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                    FreeAndNil(nfe_componente);
                    Exit;
                end;
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

         json := '{ '+
             '  "mensagemRetorno": {  '+
             '   "titulo": "'+ tituloMensagem  +'", '+
             '   "mensagem": "'+ mensagem  +'" '+
             ' }, '+
             ' "dadosRetorno": [], '+
             ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
             ' }' ;

    Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
    FreeAndNil(nfe_componente);
 end;


 function consultarNFE(usuario:TJSonValue; parametros:dadosConsulta;pagina:Integer;registros:Integer): TJSonObject;
   var
   query              : TFDQuery;
   LJSONArray         : TJSONArray;
   codigoif           : string;
   conexao            : TFDConnection;
   json               : string;
   codigoHttp         : integer;
   dados              : string;
   mensagem           : string;
   tituloMensagem     : string;
   sql                : string;
  begin
     conexao          := TFDConnection.Create(nil);
     query            := TFDQuery.Create(nil);
     query.Connection := conexao;


     if parametros.numeroNota <> ''  then
          begin
             parametros.situacaoNota := '';
             sql          := 'SELECT '+
                          'id,'+
                          'serienota,'+
                          'numeronota,'+
                          'protocolo,'+
                          'chaveacesso,'+
                          'finalidade,'+
                          'ambiente,'+
                          'valornota,'+
                          'statusnota,'+
                          'dataenvio,'+
                          'TIME_FORMAT(horaenvio, "%H:%i:%s") AS horaenvio,'+
                          'nomedestinatario,'+
                          'documentodestinatario,'+
                          'codusuario '+
                          'FROM notas_nfe  where numeronota = '''+parametros.numeroNota+''''+
                          ' AND tiponota = 1 AND codusuario='''+usuario.FindValue('codigousuario').Value+''' ORDER BY dataenvio DESC LIMIT '+IntToStr(pagina-1)+','+IntToStr(registros)+'  ';
          end;


     if parametros.numeroDocumento <> ''  then
          begin
                       parametros.situacaoNota := '';
                       sql :=  'SELECT '+
                          'id,'+
                          'serienota,'+
                          'numeronota,'+
                          'protocolo,'+
                          'chaveacesso,'+
                          'finalidade,'+
                          'ambiente,'+
                          'valornota,'+
                          'statusnota,'+
                          'dataenvio,'+
                          'TIME_FORMAT(horaenvio, "%H:%i:%s") AS horaenvio,'+
                          'nomedestinatario,'+
                          'documentodestinatario,'+
                          'codusuario '+
                          'FROM notas_nfe  where documentodestinatario = '''+parametros.numeroDocumento+''' AND dataenvio BETWEEN  '''+FormatDateTime('YYYY-MM-DD',parametros.dataInicio)+''' AND '''+FormatDateTime('YYYY-MM-DD',parametros.dataFim)+''''+
                          ' AND tiponota = 1 AND codusuario='''+usuario.FindValue('codigousuario').Value+''' ORDER BY dataenvio ASC LIMIT '+IntToStr(pagina-1)+','+IntToStr(registros)+'  ';
          end;


     if parametros.chaveAcesso <> ''  then
         begin
           sql        :=  'SELECT '+
                          'id,'+
                          'serienota,'+
                          'numeronota,'+
                          'protocolo,'+
                          'chaveacesso,'+
                          'finalidade,'+
                          'ambiente,'+
                          'valornota,'+
                          'statusnota,'+
                          'dataenvio,'+
                          'TIME_FORMAT(horaenvio, "%H:%i:%s") AS horaenvio,'+
                          'nomedestinatario,'+
                          'documentodestinatario,'+
                          'codusuario '+
                          'FROM notas_nfe  where chaveacesso = '''+parametros.chaveAcesso+''''+
                          ' AND tiponota = 1 AND codusuario='''+usuario.FindValue('codigousuario').Value+''' ORDER BY dataenvio ASC LIMIT '+IntToStr(pagina-1)+','+IntToStr(registros)+'  ';
         end;



      if (parametros.chaveAcesso = '') and (parametros.numeroNota = '') and (parametros.numeroDocumento = '') then
       begin
        sql               := 'SELECT '+
                          'id,'+
                          'serienota,'+
                          'numeronota,'+
                          'protocolo,'+
                          'chaveacesso,'+
                          'finalidade,'+
                          'ambiente,'+
                          'valornota,'+
                          'statusnota,'+
                          'dataenvio,'+
                          'TIME_FORMAT(horaenvio, "%H:%i:%s") AS horaenvio,'+
                          'nomedestinatario,'+
                          'documentodestinatario,'+
                          'codusuario '+
                          'FROM notas_nfe  where  statusnota = '''+parametros.situacaoNota +''' AND  finalidade =  '''+ IntToStr(parametros.finalidade)+''' AND ambiente = '''+ IntToStr(parametros.ambiente)+''' AND dataenvio BETWEEN  '''+FormatDateTime('YYYY-MM-DD',parametros.dataInicio)+''' AND '''+FormatDateTime('YYYY-MM-DD',parametros.dataFim)+''''+
                          ' AND tiponota = 1 AND codusuario='''+usuario.FindValue('codigousuario').Value+''' ORDER BY dataenvio ASC LIMIT '+IntToStr(registros)+' OFFSET '+IntToStr((pagina-1) * registros)+' ';

       end;


        try
           conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);
           query.Close;
           query.SQL.Add(sql);
           query.Open;

           if query.RowsAffected = 0 then
              begin
               codigoHttp      := 404;
               tituloMensagem  := 'nenhum encontrado';
               mensagem        := 'Nenhuma nfe encontrada';
              end else
                   begin
                          codigoHttp := 200;
                          LJSONArray            := query.ToJSONArray;
                          dados := '"notasFiscais":'+ LJSONArray.Format;
                          LJSONArray.Free;
                   end;
           except
            on E: Exception do
             begin
               codigoHttp      := 500;
               tituloMensagem  := 'Erro interno';
               mensagem        := funcoes.RemoveAcento(e.Message);
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


 function cancelaNFE(usuario:TJSonValue;id,motivo:string): TJSonObject;
  var
   nfe_componente        : TACBrNFe;
   json                  : string;
   codigoHttp            : integer;
   mensagem              : string;
   tituloMensagem        : string;
   query                 : TFDQuery;
   conexao               : TFDConnection;
  begin
    conexao              := TFDConnection.Create(nil);
    query                := TFDQuery.Create(nil);
    query.Connection     := conexao;

     try
      conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);
      query.close;
      query.SQL.Add('SELECT statusnota,ambiente,xmlnota FROM notas_nfe WHERE id = '''+id+''' and tiponota =1 and codusuario = '''+usuario.FindValue('codigousuario').Value+'''');
      query.open;

        if query.RowsAffected = 0 then
              begin
               codigoHttp      := 404;
               tituloMensagem  := 'nenhum encontrado';
               mensagem        := 'Nenhuma nfe encontrada';

               json := '{ '+
                 ' "mensagemRetorno": {  '+
                 ' "titulo": "'+ tituloMensagem  +'", '+
                 ' "mensagem": "'+ mensagem  +'" '+
                 ' }, '+
                 ' "dadosRetorno": [], '+
                 ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                 ' }' ;

                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                freeandnil(query);
                FreeAndNil(conexao);
                Exit;
              end ELSE
                    BEGIN
                            try
                               if (query.FieldByName('statusnota').AsString <> 'CANCELADA') then
                                     BEGIN
                                           nfe_componente  := TACBrNFe.Create(nil);
                                           nfe_componente.NotasFiscais.Clear;
                                           nfe_componente.NotasFiscais.Add;

                                            {web service}
                                           try
                                             nfe_componente.Configuracoes.WebServices.TimeOut                 := 900000;
                                             nfe_componente.Configuracoes.WebServices.Tentativas              := 100;
                                             nfe_componente.Configuracoes.WebServices.IntervaloTentativas     := 10;
                                             nfe_componente.Configuracoes.WebServices.uf                      := usuario.FindValue('ufempresa').Value;
                                             nfe_componente.Configuracoes.Geral.VersaoDF                      := ve400;
                                             nfe_componente.Configuracoes.Geral.SSLLib                        := libWinCrypt;
                                             nfe_componente.Configuracoes.Geral.SSLCryptLib                   := cryWinCrypt;
                                             nfe_componente.Configuracoes.Geral.SSLHttpLib                    := httpWinHttp;
                                             nfe_componente.Configuracoes.Geral.SSLXmlSignLib                 := xsLibXml2;
                                             nfe_componente.SSL.SSLType                                       := LT_TLSv1_2;
                                             nfe_componente.Configuracoes.Arquivos.Salvar                     := false;
                                             nfe_componente.Configuracoes.Arquivos.SalvarEvento               := False;
                                             nfe_componente.Configuracoes.Arquivos.SalvarApenasNFeProcessadas := false;
                                             nfe_componente.NotasFiscais[0].NFe.infNFe.Versao                 := 4.0;
                                             nfe_componente.Configuracoes.Arquivos.PathSchemas                := './Schemas';

                                              if query.FieldByName('ambiente').AsString = '1' then
                                                begin
                                                 nfe_componente.Configuracoes.WebServices.Ambiente            := taProducao;
                                                 nfe_componente.NotasFiscais[0].nfe.ide.tpamb                 := taProducao;
                                                end else
                                                     begin
                                                       nfe_componente.NotasFiscais[0].nfe.ide.tpamb           := tahomologacao;
                                                       nfe_componente.Configuracoes.WebServices.Ambiente      := taHomologacao;
                                                     end;

                                              except
                                                on E: Exception do
                                                 begin
                                                    tituloMensagem := 'Erro interno(web service)';
                                                    mensagem       :=  funcoes.RemoveAcento(e.Message);
                                                    codigoHttp     :=  500;
                                                    funcoes.logErro(e.Message);

                                                  json := '{ '+
                                                     ' "mensagemRetorno": {  '+
                                                     ' "titulo": "'+ tituloMensagem  +'", '+
                                                     ' "mensagem": "'+ mensagem  +'" '+
                                                     ' }, '+
                                                     ' "dadosRetorno": [], '+
                                                     ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                                     ' }' ;

                                                     Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                                     FreeAndNil(nfe_componente);
                                                     freeandnil(query);
                                                     FreeAndNil(conexao);
                                                     Exit;
                                                 end;

                                           end;



                                          {certificado digital}
                                          try
                                            nfe_componente.Configuracoes.Certificados.Senha            := funcoes.descript(usuario.FindValue('certificadosenha').Value);
                                            nfe_componente.Configuracoes.Certificados.ArquivoPFX       := '.\certificados\'+usuario.FindValue('codigousuario').Value+'.pfx';
                                            nfe_componente.Configuracoes.Arquivos.Salvar               := true;
                                            nfe_componente.NotasFiscais[0].Assinar;

                                             except
                                              on E: Exception do
                                               begin
                                                  tituloMensagem := 'Erro interno (certificado digital)';
                                                  mensagem       :=  funcoes.RemoveAcento(e.Message);
                                                  codigoHttp     :=  500;
                                                  funcoes.logErro(e.Message);

                                                json := '{ '+
                                                   ' "mensagemRetorno": {  '+
                                                   ' "titulo": "'+ tituloMensagem  +'", '+
                                                   ' "mensagem": "'+ mensagem  +'" '+
                                                   ' }, '+
                                                   ' "dadosRetorno": [], '+
                                                   ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                                   ' }' ;

                                                   Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                                   FreeAndNil(nfe_componente);
                                                   freeandnil(query);
                                                   FreeAndNil(conexao);
                                                   Exit;
                                               end;
                                          end;




                                      {envia cancelamento}
                                        try
                                         nfe_componente.NotasFiscais[0].XML := query.FieldByName('xmlnota').AsString;
                                         nfe_componente.EventoNFe.Evento.Clear;
                                         nfe_componente.EventoNFe.idLote  := 1;


                                          with nfe_componente.EventoNFe.Evento.Add do
                                            begin
                                             if query.FieldByName('ambiente').AsString = '1' then infEvento.tpAmb  := taProducao;
                                             if query.FieldByName('ambiente').AsString = '2' then infEvento.tpAmb  := taHomologacao;
                                             infEvento.dhEvento           := now;
                                             infEvento.tpEvento           := teCancelamento;
                                             infEvento.detEvento.xJust    := motivo;
                                            end;


                                           if (nfe_componente.EnviarEvento(1)) then
                                              begin
                                                 if nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.cStat = 135 then
                                                     begin

                                                         try

                                                              query.SQL.Clear;
                                                              query.SQL.Add ('INSERT INTO eventosNfe (idEvento,idNfe,tipoEvento,dataEvento,horaEvento,'+
                                                                             'motivoEvento,protocolo,xmlEvento,tpnpta,codigoUsuario)values(');

                                                              query.SQL.Add(''''  +funcoes.trigger+ '''');
                                                              query.SQL.Add(',''' +id+ '''');
                                                              query.SQL.Add(',''' +'1'+ ''''); //1 - cancelamento 2 - correção //
                                                              query.SQL.Add(',''' +FormatDateTime('YYYY-MM-DD',NOW)+ '''');
                                                              query.SQL.Add(',''' +TimeToStr(now)+ '''');
                                                              query.SQL.Add(',''' +funcoes.RemoveAcento(motivo)+ '''');
                                                              query.SQL.Add(',''' +nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.nProt+ '''');
                                                              query.SQL.Add(',:xml');
                                                              query.SQL.Add(',''' +'1'+'''');//tipo de nota NFe
                                                              query.SQL.Add(',''' +usuario.FindValue('codigousuario').Value+ ''')');

                                                              query.Params[0].DataType := ftBlob;
                                                              query.Params[0].Value    := nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.xml;
                                                              query.ExecSQL;


                                                              query.SQL.Clear;
                                                              query.SQL.Add('UPDATE notas_nfe SET statusnota = '''+'CANCELADA'+'''  where  id = '''+id+''' AND tiponota =1 AND codusuario = '''+usuario.FindValue('codigousuario').Value+'''');
                                                              query.ExecSQL;


                                                              if query.RowsAffected = 1 then
                                                                 BEGIN
                                                                  codigoHttp     :=  200;
                                                                  json := '{ '+
                                                                     ' "mensagemRetorno": {  '+
                                                                     ' "mensagemSefaz": {  '+
                                                                     ' "statusSefaz": "'+ IntToStr(nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.cStat)+'", '+
                                                                     ' "mensagemSefaz": "'+ funcoes.RemoveAcento(nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.xMotivo)+'", '+
                                                                     ' "protocolo": "'+ nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.nProt+'"'+
                                                                     ' } '+

                                                                     ' }, '+

                                                                     ' "dadosRetorno": [], '+
                                                                     ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                                                     ' }' ;

                                                                    Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                                                    FreeAndNil(nfe_componente);
                                                                    freeandnil(query);
                                                                    FreeAndNil(conexao);
                                                                    Exit;
                                                                 END;




                                                                except on E: Exception do
                                                                    begin

                                                                     tituloMensagem := 'Erro interno';
                                                                     codigoHttp     :=  500;

                                                                     json := '{ '+
                                                                     ' "mensagemRetorno": {  '+
                                                                     ' "mensagemSefaz": "'+ funcoes.RemoveAcento(e.Message) +'" '+
                                                                     ' }, '+

                                                                     ' "dadosRetorno": [], '+
                                                                     ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                                                     ' }' ;

                                                                      Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                                                      FreeAndNil(nfe_componente);
                                                                      freeandnil(query);
                                                                      FreeAndNil(conexao);
                                                                      Exit;
                                                                    end;

                                                         end;

                                                     end else
                                                          begin
                                                            codigoHttp := 200;

                                                            json := '{ '+
                                                               ' "mensagemRetorno": {  '+
                                                               ' "mensagemSefaz": {  '+
                                                               ' "statusSefaz": "'+ IntToStr(nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.cStat)+'", '+
                                                               ' "mensagemSefaz": "'+ funcoes.RemoveAcento(nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.xMotivo)+'", '+
                                                               ' "protocolo": "'+ nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.nProt+'", '+
                                                               ' "chaveAcesso": "'+ nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.id+'" '+
                                                               ' } '+

                                                               ' }, '+

                                                               ' "dadosRetorno": [], '+
                                                               ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                                               ' }' ;

                                                              Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                                              FreeAndNil(nfe_componente);
                                                              freeandnil(query);
                                                              FreeAndNil(conexao);
                                                              Exit;
                                                          end;
                                              end;

                                            except
                                              on E: Exception do
                                               begin
                                                  tituloMensagem := 'Erro interno (certificado digital)';
                                                  mensagem       :=  funcoes.RemoveAcento(e.Message);
                                                  codigoHttp     :=  500;
                                                  funcoes.logErro(e.Message);

                                                json := '{ '+
                                                   ' "mensagemRetorno": {  '+
                                                   ' "titulo": "'+ tituloMensagem  +'", '+
                                                   ' "mensagem": "'+ mensagem  +'" '+
                                                   ' }, '+
                                                   ' "dadosRetorno": [], '+
                                                   ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                                   ' }' ;

                                                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                                FreeAndNil(nfe_componente);
                                                freeandnil(query);
                                                FreeAndNil(conexao);
                                                Exit;
                                               end;

                                        end;

                                     END else
                                          BEGIN
                                              tituloMensagem := 'Não possível cancelar NF-e';
                                              mensagem       := 'NF-e já está cancelada';
                                              codigoHttp     := 409;

                                            json := '{ '+
                                               ' "mensagemRetorno": {  '+
                                               ' "titulo": "'+ tituloMensagem  +'", '+
                                               ' "mensagem": "'+ mensagem  +'" '+
                                               ' }, '+
                                               ' "dadosRetorno": [], '+
                                               ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                               ' }' ;

                                                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                                FreeAndNil(nfe_componente);
                                                freeandnil(query);
                                                FreeAndNil(conexao);
                                                Exit;
                                          END;

                             except
                                on E: Exception do
                                 begin
                                   codigoHttp      := 500;
                                   tituloMensagem  := 'Erro interno';
                                   mensagem        := funcoes.RemoveAcento(e.Message);


                                     json := '{ '+
                                     '  "mensagemRetorno": {  '+
                                     '   "titulo": "'+ tituloMensagem  +'", '+
                                     '   "mensagem": "'+ mensagem  +'" '+
                                     ' }, '+
                                     ' "dadosRetorno": [], '+
                                     ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                     ' }' ;

                                     Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                     FreeAndNil(nfe_componente);
                                     freeandnil(query);
                                     FreeAndNil(conexao);
                                     Exit;
                                 end;
                            end;
                    end;

           except
            on E: Exception do
             begin
               codigoHttp      := 500;
               tituloMensagem  := 'Erro interno';
               mensagem        := funcoes.RemoveAcento(e.Message);


                 json := '{ '+
                 '  "mensagemRetorno": {  '+
                 '   "titulo": "'+ tituloMensagem  +'", '+
                 '   "mensagem": "'+ mensagem  +'" '+
                 ' }, '+
                 ' "dadosRetorno": [], '+
                 ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                 ' }' ;

                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                funcoes.faz_log_texto('',json);
                freeandnil(query);
                FreeAndNil(conexao);
             end;
     end;

       json := '{ '+
       '  "mensagemRetorno": {  '+
       '   "titulo": "'+ tituloMensagem  +'", '+
       '   "mensagem": "'+ mensagem  +'" '+
       ' }, '+
       ' "dadosRetorno": [], '+
       ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
       ' }' ;

       Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
       FreeAndNil(nfe_componente);
       freeandnil(query);
       FreeAndNil(conexao);
  end;


 function correcaoNFE(usuario:TJSonValue;id,motivo:string) : TJSonObject;
var
   nfe_componente        : TACBrNFe;
   json                  : string;
   codigoHttp            : integer;
   mensagem              : string;
   tituloMensagem        : string;
   query                 : TFDQuery;
   conexao               : TFDConnection;
   querySequenciaEvento  : TFDQuery;
   numeroEvento          : integer;
  begin
    conexao              := TFDConnection.Create(nil);
    query                := TFDQuery.Create(nil);
    query.Connection     := conexao;

     try
      conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);
      query.close;
      query.SQL.Add('SELECT ambiente,chaveacesso,xmlnota FROM notas_nfe WHERE id = '''+id+''' AND tiponota = 1 AND codusuario = '''+usuario.FindValue('codigousuario').Value+'''');
      query.open;

        if query.RowsAffected = 0 then
              begin
               codigoHttp      := 404;
               tituloMensagem  := 'nenhum encontrado';
               mensagem        := 'Nenhuma NF-e encontrada';

               json := '{ '+
                 ' "mensagemRetorno": {  '+
                 ' "titulo": "'+ tituloMensagem  +'", '+
                 ' "mensagem": "'+ mensagem  +'" '+
                 ' }, '+
                 ' "dadosRetorno": [], '+
                 ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                 ' }' ;

                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                freeandnil(query);
                FreeAndNil(conexao);
                Exit;
              end ELSE
                    BEGIN
                            try
                                 nfe_componente  := TACBrNFe.Create(nil);
                                 nfe_componente.NotasFiscais.Clear;
                                 nfe_componente.NotasFiscais.Add;

                                  {web service}
                                 try
                                   nfe_componente.Configuracoes.WebServices.TimeOut                 := 900000;
                                   nfe_componente.Configuracoes.WebServices.Tentativas              := 100;
                                   nfe_componente.Configuracoes.WebServices.IntervaloTentativas     := 10;
                                   nfe_componente.Configuracoes.WebServices.uf                      := usuario.FindValue('ufempresa').Value;
                                   nfe_componente.Configuracoes.Geral.VersaoDF                      := ve400;
                                   nfe_componente.Configuracoes.Geral.SSLLib                        := libWinCrypt;
                                   nfe_componente.Configuracoes.Geral.SSLCryptLib                   := cryWinCrypt;
                                   nfe_componente.Configuracoes.Geral.SSLHttpLib                    := httpWinHttp;
                                   nfe_componente.Configuracoes.Geral.SSLXmlSignLib                 := xsLibXml2;
                                   nfe_componente.SSL.SSLType                                       := LT_TLSv1_2;
                                   nfe_componente.Configuracoes.Arquivos.Salvar                     := false;
                                   nfe_componente.Configuracoes.Arquivos.SalvarEvento               := False;
                                   nfe_componente.Configuracoes.Arquivos.SalvarApenasNFeProcessadas := false;
                                   nfe_componente.NotasFiscais[0].NFe.infNFe.Versao                 := 4.0;
                                   nfe_componente.Configuracoes.Arquivos.PathSchemas                := './Schemas';

                                    if query.FieldByName('ambiente').AsString = '1' then
                                      begin
                                       nfe_componente.Configuracoes.WebServices.Ambiente            := taProducao;
                                       nfe_componente.NotasFiscais[0].nfe.ide.tpamb                 := taProducao;
                                      end else
                                           begin
                                             nfe_componente.NotasFiscais[0].nfe.ide.tpamb           := tahomologacao;
                                             nfe_componente.Configuracoes.WebServices.Ambiente      := taHomologacao;
                                           end;

                                    except
                                      on E: Exception do
                                       begin
                                          tituloMensagem := 'Erro interno(web service)';
                                          mensagem       :=  funcoes.RemoveAcento(e.Message);
                                          codigoHttp     :=  500;
                                          funcoes.logErro(e.Message);

                                        json := '{ '+
                                           ' "mensagemRetorno": {  '+
                                           ' "titulo": "'+ tituloMensagem  +'", '+
                                           ' "mensagem": "'+ mensagem  +'" '+
                                           ' }, '+
                                           ' "dadosRetorno": [], '+
                                           ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                           ' }' ;

                                           Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                           FreeAndNil(nfe_componente);
                                           freeandnil(query);
                                           FreeAndNil(conexao);
                                           Exit;
                                       end;

                                 end;



                                {certificado digital}
                                try
                                  nfe_componente.Configuracoes.Certificados.Senha            := funcoes.descript(usuario.FindValue('certificadosenha').Value);
                                  nfe_componente.Configuracoes.Certificados.ArquivoPFX       := '.\certificados\'+usuario.FindValue('codigousuario').Value+'.pfx';
                                  nfe_componente.Configuracoes.Arquivos.Salvar               := true;
                                  nfe_componente.NotasFiscais[0].Assinar;

                                   except
                                    on E: Exception do
                                     begin
                                        tituloMensagem := 'Erro interno (certificado digital)';
                                        mensagem       :=  funcoes.RemoveAcento(e.Message);
                                        codigoHttp     :=  500;
                                        funcoes.logErro(e.Message);

                                      json := '{ '+
                                         ' "mensagemRetorno": {  '+
                                         ' "titulo": "'+ tituloMensagem  +'", '+
                                         ' "mensagem": "'+ mensagem  +'" '+
                                         ' }, '+
                                         ' "dadosRetorno": [], '+
                                         ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                         ' }' ;

                                         Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                         FreeAndNil(nfe_componente);
                                         freeandnil(query);
                                         FreeAndNil(conexao);
                                         Exit;
                                     end;
                                end;



                                querySequenciaEvento                := TFDQuery.Create(nil);
                                querySequenciaEvento.Connection     := conexao;

                                querySequenciaEvento.Close;
                                querySequenciaEvento.SQL.Add('SELECT COUNT(*) as total FROM eventosnfe where tipoEvento = 2  and idNfe = '''+id+''' AND tpnpta = 1 and codigoUsuario = '''+usuario.FindValue('codigousuario').Value+'''');
                                querySequenciaEvento.Open();
                                numeroEvento := querySequenciaEvento.FieldByName('total').AsInteger+1;
                                FreeAndNil(querySequenciaEvento);

                                {envia carta correção}
                                  try
                                   nfe_componente.NotasFiscais[0].XML := query.FieldByName('xmlnota').AsString;
                                   nfe_componente.EventoNFe.Evento.Clear;
                                   nfe_componente.EventoNFe.idLote    := 1;

                                    with nfe_componente.EventoNFe.Evento.add do
                                      begin
                                       if query.FieldByName('ambiente').AsString = '1' then infEvento.tpAmb  := taProducao;
                                       if query.FieldByName('ambiente').AsString = '2' then infEvento.tpAmb  := taHomologacao;

                                       infEvento.chNFe                := query.FieldByName('chaveacesso').AsString;
                                       infEvento.CNPJ                 := usuario.FindValue('cnpjempresa').Value;
                                       infEvento.dhEvento             := now;
                                       infEvento.tpEvento             := teCCe;
                                       infEvento.detEvento.xCorrecao  := motivo;
                                       infEvento.nSeqEvento           := numeroEvento;
                                       InfEvento.cOrgao               := StrToInt(usuario.FindValue('coduf').Value);
                                      end;


                                     if (nfe_componente.EnviarEvento(1)) then
                                        begin
                                           if nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.cStat = 135 then
                                               begin
                                                   try
                                                        query.SQL.Clear;
                                                        query.SQL.Add ('INSERT INTO eventosNfe (idEvento,idNfe,tipoEvento,dataEvento,horaEvento,'+
                                                                       'motivoEvento,protocolo,xmlEvento,tpnpta,codigoUsuario)values(');

                                                        query.SQL.Add(''''  +funcoes.trigger+ '''');
                                                        query.SQL.Add(',''' +id+ '''');
                                                        query.SQL.Add(',''' +'2'+ ''''); //1 - cancelamento 2 - correção //
                                                        query.SQL.Add(',''' +FormatDateTime('YYYY-MM-DD',NOW)+ '''');
                                                        query.SQL.Add(',''' +TimeToStr(now)+ '''');
                                                        query.SQL.Add(',''' +funcoes.RemoveAcento(motivo)+ '''');
                                                        query.SQL.Add(',''' +nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.nProt+ '''');
                                                        query.SQL.Add(',:xml');
                                                        query.SQL.Add(',''' +'1'+ '''');
                                                        query.SQL.Add(',''' +usuario.FindValue('codigousuario').Value+ ''')');

                                                        query.Params[0].DataType := ftBlob;
                                                        query.Params[0].Value    := nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.xml;
                                                        query.ExecSQL;


                                                        if query.RowsAffected = 1 then
                                                           BEGIN
                                                            codigoHttp     :=  200;
                                                            json := '{ '+
                                                               ' "mensagemRetorno": {  '+
                                                               ' "mensagemSefaz": {  '+
                                                               ' "statusSefaz": "'+ IntToStr(nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.cStat)+'", '+
                                                               ' "mensagemSefaz": "'+ funcoes.RemoveAcento(nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.xMotivo)+'", '+
                                                               ' "protocolo": "'+ nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.nProt+'"'+
                                                               ' } '+

                                                               ' }, '+

                                                               ' "dadosRetorno": [], '+
                                                               ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                                               ' }' ;

                                                              Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                                              FreeAndNil(nfe_componente);
                                                              freeandnil(query);
                                                              FreeAndNil(conexao);
                                                              Exit;
                                                           END;


                                                          except on E: Exception do
                                                              begin

                                                               tituloMensagem := 'Erro interno';
                                                               codigoHttp     :=  500;

                                                               json := '{ '+
                                                               ' "mensagemRetorno": {  '+
                                                               ' "mensagemSefaz": "'+ funcoes.RemoveAcento(e.Message) +'" '+
                                                               ' }, '+

                                                               ' "dadosRetorno": [], '+
                                                               ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                                               ' }' ;

                                                                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                                                FreeAndNil(nfe_componente);
                                                                freeandnil(query);
                                                                FreeAndNil(conexao);
                                                                Exit;
                                                              end;

                                                   end;

                                               end else
                                                    begin
                                                      codigoHttp := 200;

                                                      json := '{ '+
                                                         ' "mensagemRetorno": {  '+
                                                         ' "mensagemSefaz": {  '+
                                                         ' "statusSefaz": "'+ IntToStr(nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.cStat)+'", '+
                                                         ' "mensagemSefaz": "'+ funcoes.RemoveAcento(nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.xMotivo)+'", '+
                                                         ' "protocolo": "'+ nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.nProt+'", '+
                                                         ' "chaveAcesso": "'+ nfe_componente.WebServices.EnvEvento.EventoRetorno.retEvento.Items[0].RetInfEvento.id+'" '+
                                                         ' } '+

                                                         ' }, '+

                                                         ' "dadosRetorno": [], '+
                                                         ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                                         ' }' ;

                                                        Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                                        FreeAndNil(nfe_componente);
                                                        freeandnil(query);
                                                        FreeAndNil(conexao);
                                                        Exit;
                                                    end;
                                        end;

                                      except
                                        on E: Exception do
                                         begin
                                            tituloMensagem := 'Erro ao corrigir NF-e';
                                            mensagem       :=  funcoes.RemoveAcento(e.Message);
                                            codigoHttp     :=  400;
                                            funcoes.logErro(e.Message);

                                          json := '{ '+
                                             ' "mensagemRetorno": {  '+
                                             ' "titulo": "'+ tituloMensagem  +'", '+
                                             ' "mensagem": "'+ mensagem  +'" '+
                                             ' }, '+
                                             ' "dadosRetorno": [], '+
                                             ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                             ' }' ;

                                          Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                          FreeAndNil(nfe_componente);
                                          freeandnil(query);
                                          FreeAndNil(conexao);
                                          Exit;
                                         end;

                                  end;



                             except
                                on E: Exception do
                                 begin
                                   codigoHttp      := 500;
                                   tituloMensagem  := 'Erro interno';
                                   mensagem        := funcoes.RemoveAcento(e.Message);


                                     json := '{ '+
                                     '  "mensagemRetorno": {  '+
                                     '   "titulo": "'+ tituloMensagem  +'", '+
                                     '   "mensagem": "'+ mensagem  +'" '+
                                     ' }, '+
                                     ' "dadosRetorno": [], '+
                                     ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                                     ' }' ;

                                     Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                     FreeAndNil(nfe_componente);
                                     freeandnil(query);
                                     FreeAndNil(conexao);
                                     Exit;
                                 end;
                            end;
                    end;

           except
            on E: Exception do
             begin
               codigoHttp      := 500;
               tituloMensagem  := 'Erro interno';
               mensagem        := funcoes.RemoveAcento(e.Message);


                 json := '{ '+
                 '  "mensagemRetorno": {  '+
                 '   "titulo": "'+ tituloMensagem  +'", '+
                 '   "mensagem": "'+ mensagem  +'" '+
                 ' }, '+
                 ' "dadosRetorno": [], '+
                 ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                 ' }' ;

                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                funcoes.faz_log_texto('',json);
                freeandnil(query);
                FreeAndNil(conexao);
             end;
     end;

       json := '{ '+
       '  "mensagemRetorno": {  '+
       '   "titulo": "'+ tituloMensagem  +'", '+
       '   "mensagem": "'+ mensagem  +'" '+
       ' }, '+
       ' "dadosRetorno": [], '+
       ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
       ' }' ;

       Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
       FreeAndNil(nfe_componente);
       freeandnil(query);
       FreeAndNil(conexao);
  end;


 function consultarEVENTOS(usuario:TJSonValue;id:string;pagina:Integer;registros:Integer): TJSonObject;
   var
   query              : TFDQuery;
   LJSONArray         : TJSONArray;
   codigoif           : string;
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
           query.Close;
           query.SQL.Add('select idEvento,idNfe,tipoEvento,dataEvento,TIME_FORMAT(horaEvento, "%H:%i:%s") AS horaEvento,protocolo from eventosnfe where idNfe = '''+id+'''and tpnpta = 1 and codigoUsuario = '''+usuario.FindValue('codigousuario').Value+''' ORDER BY dataEvento ASC LIMIT '+IntToStr(registros)+' OFFSET '+IntToStr((pagina-1) * registros)+' ');
           query.Open;

           if query.RowsAffected = 0 then
              begin
               codigoHttp      := 404;
               tituloMensagem  := 'nenhum encontrado';
               mensagem        := 'Nenhum evento encontrado';
              end else
                   begin
                          codigoHttp  := 200;
                          LJSONArray  := query.ToJSONArray;
                          dados       := '"eventos":'+ LJSONArray.Format;
                          LJSONArray.Free;
                   end;
           except
            on E: Exception do
             begin
               codigoHttp      := 500;
               tituloMensagem  := 'Erro interno';
               mensagem        := funcoes.RemoveAcento(e.Message);
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


 function inutilizarNFE(usuario:TJSonValue;serie,numeroInicio,numeroFim:Int64;justificativa:string):TJSonObject;
var
   nfe_componente        : TACBrNFe;
   json                  : string;
   codigoHttp            : integer;
   mensagem              : string;
   tituloMensagem        : string;
   query                 : TFDQuery;
   conexao               : TFDConnection;
   querySequenciaEvento  : TFDQuery;
   numeroEvento          : integer;
  begin
    conexao              := TFDConnection.Create(nil);
    query                := TFDQuery.Create(nil);
    query.Connection     := conexao;

    nfe_componente:= TACBrNFe.Create(nil);
    nfe_componente.NotasFiscais.Clear;
    nfe_componente.NotasFiscais.Add;


                  {web service}
                 try
                   nfe_componente.Configuracoes.WebServices.TimeOut                 := 900000;
                   nfe_componente.Configuracoes.WebServices.Tentativas              := 100;
                   nfe_componente.Configuracoes.WebServices.IntervaloTentativas     := 10;
                   nfe_componente.Configuracoes.WebServices.uf                      := usuario.FindValue('ufempresa').Value;
                   nfe_componente.Configuracoes.Geral.VersaoDF                      := ve400;
                   nfe_componente.Configuracoes.Geral.SSLLib                        := libWinCrypt;
                   nfe_componente.Configuracoes.Geral.SSLCryptLib                   := cryWinCrypt;
                   nfe_componente.Configuracoes.Geral.SSLHttpLib                    := httpWinHttp;
                   nfe_componente.Configuracoes.Geral.SSLXmlSignLib                 := xsLibXml2;
                   nfe_componente.SSL.SSLType                                       := LT_TLSv1_2;
                   nfe_componente.Configuracoes.Arquivos.Salvar                     := false;
                   nfe_componente.Configuracoes.Arquivos.SalvarEvento               := False;
                   nfe_componente.Configuracoes.Arquivos.SalvarApenasNFeProcessadas := false;
                   nfe_componente.NotasFiscais[0].NFe.infNFe.Versao                 := 4.0;
                   nfe_componente.Configuracoes.Arquivos.PathSchemas                := './Schemas';

                    if usuario.FindValue('nfeambiente').Value                        = '1' then
                      begin
                       nfe_componente.Configuracoes.WebServices.Ambiente            := taProducao;
                       nfe_componente.NotasFiscais[0].nfe.ide.tpamb                 := taProducao;
                      end else
                           begin
                             nfe_componente.NotasFiscais[0].nfe.ide.tpamb           := tahomologacao;
                             nfe_componente.Configuracoes.WebServices.Ambiente      := taHomologacao;
                           end;

                    except
                      on E: Exception do
                       begin
                          tituloMensagem := 'Erro interno(web service)';
                          mensagem       :=  funcoes.RemoveAcento(e.Message);
                          codigoHttp     :=  500;
                          funcoes.logErro(e.Message);

                        json := '{ '+
                           ' "mensagemRetorno": {  '+
                           ' "titulo": "'+ tituloMensagem  +'", '+
                           ' "mensagem": "'+ mensagem  +'" '+
                           ' }, '+
                           ' "dadosRetorno": [], '+
                           ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                           ' }' ;

                           Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                           FreeAndNil(nfe_componente);
                           freeandnil(query);
                           FreeAndNil(conexao);
                           Exit;
                       end;

                 end;



                  {certificado digital}
                  try
                    nfe_componente.Configuracoes.Certificados.Senha            := funcoes.descript(usuario.FindValue('certificadosenha').Value);
                    nfe_componente.Configuracoes.Certificados.ArquivoPFX       := '.\certificados\'+usuario.FindValue('codigousuario').Value+'.pfx';
                    nfe_componente.Configuracoes.Arquivos.Salvar               := true;
                    nfe_componente.NotasFiscais[0].Assinar;

                     except
                      on E: Exception do
                       begin
                          tituloMensagem := 'Erro interno (certificado digital)';
                          mensagem       :=  funcoes.RemoveAcento(e.Message);
                          codigoHttp     :=  500;
                          funcoes.logErro(e.Message);

                        json := '{ '+
                           ' "mensagemRetorno": {  '+
                           ' "titulo": "'+ tituloMensagem  +'", '+
                           ' "mensagem": "'+ mensagem  +'" '+
                           ' }, '+
                           ' "dadosRetorno": [], '+
                           ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                           ' }' ;

                           Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                           FreeAndNil(nfe_componente);
                           freeandnil(query);
                           FreeAndNil(conexao);
                           Exit;
                       end;
                  end;



                  {inutilizar NF-E}
                   try
                     nfe_componente.WebServices.Inutiliza(usuario.FindValue('cnpjempresa').Value,funcoes.RemoveAcento(justificativa),StrToInt(FormatDateTime('yy',now)),55,serie,numeroInicio,numeroFim);

                      except
                        on E: Exception do
                         begin
                            tituloMensagem := 'Erro ao corrigir NF-e';
                            mensagem       :=  funcoes.RemoveAcento(e.Message);
                            codigoHttp     :=  200;
                            funcoes.logErro(e.Message);

                          json := '{ '+
                           ' "mensagemRetorno": {  '+
                           ' "mensagemSefaz": {  '+
                           ' "statusSefaz": "'+ IntToStr(nfe_componente.WebServices.Inutilizacao.CStat)+'", '+
                           ' "mensagemSefaz": "'+ funcoes.RemoveAcento(nfe_componente.WebServices.Inutilizacao.Msg)+'", '+
                           ' "protocolo": "'+nfe_componente.WebServices.Inutilizacao.Protocolo+'"'+
                           ' } '+

                           ' }, '+

                           ' "dadosRetorno": [], '+
                           ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                           ' }' ;

                          Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                          FreeAndNil(nfe_componente);
                          freeandnil(query);
                          FreeAndNil(conexao);
                          Exit;
                         end;

                   end;

                  if nfe_componente.WebServices.Inutilizacao.CStat <> 102 then
                   begin
                        codigoHttp     :=  200;
                        json := '{ '+
                           ' "mensagemRetorno": {  '+
                           ' "mensagemSefaz": {  '+
                           ' "statusSefaz": "'+ IntToStr(nfe_componente.WebServices.Inutilizacao.CStat)+'", '+
                           ' "mensagemSefaz": "'+ funcoes.RemoveAcento(nfe_componente.WebServices.Inutilizacao.Msg)+'", '+
                           ' "protocolo": "'+nfe_componente.WebServices.Inutilizacao.Protocolo+'"'+
                           ' } '+

                           ' }, '+

                           ' "dadosRetorno": [], '+
                           ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                           ' }' ;

                        Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                        FreeAndNil(nfe_componente);
                        freeandnil(query);
                        FreeAndNil(conexao);
                        Exit;
                   end;


                   try
                        conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);

                        query.SQL.Add ('INSERT INTO inutilizacaoNfe (id,data,hora,tpAmbiente,justificativa,'+
                                       'protocolo,ano,serie,numeroInicio,numeroFim,xml,tpnota,codigoUsuario)values(');

                        query.SQL.Add(''''  +funcoes.trigger+ '''');
                        query.SQL.Add(',''' +FormatDateTime('YYYY-MM-DD',NOW)+ '''');
                        query.SQL.Add(',''' +TimeToStr(now)+ '''');
                        query.SQL.Add(',''' +usuario.FindValue('nfeambiente').Value+'''');
                        query.SQL.Add(',''' +funcoes.RemoveAcento(justificativa)+'''');
                        query.SQL.Add(',''' +nfe_componente.WebServices.Inutilizacao.Protocolo+ '''');

                        query.SQL.Add(',''' +FormatDateTime('yy',now)+'''');
                        query.SQL.Add(',''' +IntToStr(serie)+'''');
                        query.SQL.Add(',''' +IntToStr(numeroInicio)+'''');
                        query.SQL.Add(',''' +IntToStr(numeroFim)+'''');

                        query.SQL.Add(',:xml');
                        query.SQL.Add(',''' +'1'+''''); // inutiliza nfe
                        query.SQL.Add(',''' +usuario.FindValue('codigousuario').Value+ ''')');

                        query.Params[0].DataType := ftBlob;
                        query.Params[0].Value    := nfe_componente.WebServices.Inutilizacao.XML_ProcInutNFe;
                        query.ExecSQL;


                        if query.RowsAffected = 1 then
                           BEGIN
                            codigoHttp     :=  200;
                            json := '{ '+
                               ' "mensagemRetorno": {  '+
                               ' "mensagemSefaz": {  '+
                               ' "statusSefaz": "'+ IntToStr(nfe_componente.WebServices.Inutilizacao.CStat)+'", '+
                               ' "mensagemSefaz": "'+ funcoes.RemoveAcento(nfe_componente.WebServices.Inutilizacao.Msg)+'", '+
                               ' "protocolo": "'+nfe_componente.WebServices.Inutilizacao.Protocolo+'"'+
                               ' } '+

                               ' }, '+

                               ' "dadosRetorno": [], '+
                               ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                               ' }' ;

                              Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                              FreeAndNil(nfe_componente);
                              freeandnil(query);
                              FreeAndNil(conexao);
                              Exit;
                           END;


                          except on E: Exception do
                              begin

                               tituloMensagem := 'Erro interno';
                               codigoHttp     :=  500;

                               json := '{ '+
                               ' "mensagemRetorno": {  '+
                               ' "mensagemSefaz": "'+ funcoes.RemoveAcento(e.Message) +'" '+
                               ' }, '+

                               ' "dadosRetorno": [], '+
                               ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                               ' }' ;

                                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                FreeAndNil(nfe_componente);
                                freeandnil(query);
                                FreeAndNil(conexao);
                                Exit;
                              end;
                   end;






       json := '{ '+
       '  "mensagemRetorno": {  '+
       '   "titulo": "'+ tituloMensagem  +'", '+
       '   "mensagem": "'+ mensagem  +'" '+
       ' }, '+
       ' "dadosRetorno": [], '+
       ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
       ' }' ;

       Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
       FreeAndNil(nfe_componente);
       freeandnil(query);
       FreeAndNil(conexao);
  end;


 function consultarINUTILIZACOES(usuario:TJSonValue;pagina:Integer;registros:Integer): TJSonObject;
   var
   query              : TFDQuery;
   LJSONArray         : TJSONArray;
   codigoif           : string;
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
           query.Close;
           query.SQL.Add('select id,data,TIME_FORMAT(hora, "%H:%i:%s") AS hora,serie,numeroInicio,numeroFim,tpAmbiente,justificativa,protocolo  from inutilizacaonfe where tpnota = 1 and codigoUsuario = '''+usuario.FindValue('codigousuario').Value+''' ORDER BY data ASC LIMIT '+IntToStr(registros)+' OFFSET '+IntToStr((pagina-1) * registros)+' ');
           query.Open;

           if query.RowsAffected = 0 then
              begin
               codigoHttp      := 404;
               tituloMensagem  := 'nenhum encontrado';
               mensagem        := 'Nenhuma inutilizacao encontrada';
              end else
                   begin
                          codigoHttp  := 200;
                          LJSONArray  := query.ToJSONArray;
                          dados       := '"inutilizacoes":'+ LJSONArray.Format;
                          LJSONArray.Free;
                   end;
           except
            on E: Exception do
             begin
               codigoHttp      := 500;
               tituloMensagem  := 'Erro interno';
               mensagem        := funcoes.RemoveAcento(e.Message);
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


 function gravarRascunho(usuario:TJSonValue;jsonNota:string;tipoNota:integer;cliente:string;valor:string): TJSonObject;
 var
   json                  : string;
   codigoHttp            : integer;
   mensagem              : string;
   tituloMensagem        : string;
   query                 : TFDQuery;
   conexao               : TFDConnection;
   codigoRascunho        : string;
  begin

    conexao              := TFDConnection.Create(nil);
    query                := TFDQuery.Create(nil);
    query.Connection     := conexao;


                   try
                        conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);

                        query.SQL.Add ('INSERT INTO rascunhonotas (codigoRascunho,cliente,valor,dataRascunho,horaRascunho,'+
                                       'jsonRascunho,tipoNota,codigoUsuario)values(');

                        codigoRascunho := funcoes.trigger;
                        query.SQL.Add(''''  +codigoRascunho+ '''');
                        query.SQL.Add(',''' +funcoes.RemoveAcento(cliente)+ '''');
                        query.SQL.Add(',''' +valor+ '''');

                        query.SQL.Add(',''' +FormatDateTime('YYYY-MM-DD',NOW)+ '''');
                        query.SQL.Add(',''' +TimeToStr(now)+'''');
                        query.SQL.Add(',:json');
                        query.SQL.Add(',''' +IntToStr(tipoNota)+'''');
                        query.SQL.Add(',''' +usuario.FindValue('codigousuario').Value+ ''')');

                        query.Params[0].DataType := ftString;
                        query.Params[0].Value    := jsonNota;

                        query.ExecSQL;


                        if query.RowsAffected = 1 then
                           BEGIN
                            codigoHttp     :=  201;

                             json := '{ '+
                             '  "mensagemRetorno": {  '+
                             '   "titulo": "'+ 'Rascunho salvo'  +'", '+
                             '   "mensagem": "'+codigoRascunho+'" '+
                             ' }, '+
                             ' "dadosRetorno": [], '+
                             ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                             ' }' ;

                              Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                              freeandnil(query);
                              FreeAndNil(conexao);
                              Exit;
                           END;


                          except on E: Exception do
                              begin

                               tituloMensagem := 'Erro interno';
                               codigoHttp     :=  500;

                               json := '{ '+
                               '  "mensagemRetorno": {  '+
                               '   "titulo": "'+ tituloMensagem  +'", '+
                               '   "mensagem": "'+ funcoes.RemoveAcento(e.Message)+'" '+
                               ' }, '+
                               ' "dadosRetorno": [], '+
                               ' "codigoHttp": "'+ IntToStr(codigoHttp) +'" '+
                               ' }' ;

                                Result := TJSonObject.ParseJSONValue(json) as TJSonObject;
                                freeandnil(query);
                                FreeAndNil(conexao);
                                Exit;
                              end;
                   end;


       json := '{ '+
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


 function buscaRascunhos(usuario:TJSonValue;parametros:consultaRascunhos;pagina:Integer;registros:Integer): TJSonObject;
   var
   query              : TFDQuery;
   LJSONArray         : TJSONArray;
   codigoif           : string;
   conexao            : TFDConnection;
   json               : string;
   codigoHttp         : integer;
   dados              : string;
   mensagem           : string;
   tituloMensagem     : string;
   sql                : string;
  begin
     conexao          := TFDConnection.Create(nil);
     query            := TFDQuery.Create(nil);
     query.Connection := conexao;


     if parametros.cliente <> ''  then
          begin
             sql          := 'SELECT '+
                          'codigoRascunho,'+
                          'cliente,'+
                          'valor,'+
                          'dataRascunho,'+
                          'jsonRascunho,'+
                          'tipoNota '+
                          'FROM rascunhonotas  where cliente = '''+parametros.cliente+''''+
                          ' AND codigoUsuario='''+usuario.FindValue('codigousuario').Value+''' ORDER BY dataRascunho ASC LIMIT '+IntToStr(registros)+' OFFSET '+IntToStr((pagina-1) * registros);
          end;


     if parametros.tipoNota <> ''  then
          begin
             sql          := 'SELECT '+
                          'codigoRascunho,'+
                          'cliente,'+
                          'valor,'+
                          'dataRascunho,'+
                          'jsonRascunho,'+
                          'tipoNota '+
                          'FROM rascunhonotas  where tipoNota = '''+parametros.tipoNota+''''+
                          ' AND codigoUsuario='''+usuario.FindValue('codigousuario').Value+''' ORDER BY dataRascunho ASC LIMIT '+IntToStr(registros)+' OFFSET '+IntToStr((pagina-1) * registros);
          end;



       if (Trim(parametros.tipoNota) = '') and  (Trim(parametros.cliente) = '') then
           begin
             sql          := 'SELECT '+
                          'codigoRascunho,'+
                          'cliente,'+
                          'valor,'+
                          'DATE_FORMAT(dataRascunho, "%d/%m/%Y") as dataRascunho,'+
                          'jsonRascunho,'+
                          'tipoNota '+
                          'FROM rascunhonotas '+
                          ' where codigoUsuario='''+usuario.FindValue('codigousuario').Value+''' ORDER BY dataRascunho ASC LIMIT '+IntToStr(registros)+' OFFSET '+IntToStr((pagina-1) * registros);
           end;


        try
           conexao.Open('DriverID='+funcoes.dbDriver+';Database='+funcoes.dbNome+';User_Name='+funcoes.dbUser+';Password='+funcoes.dbSenha+';Port='+funcoes.dbPorta+';Server='+funcoes.dbHost);
           query.Close;
           query.SQL.Add(sql);
           query.Open;

           if query.RowsAffected = 0 then
              begin
               codigoHttp      := 404;
               tituloMensagem  := 'nenhum encontrado';
               mensagem        := 'Nenhuma rascunho encontrado';
              end else
                   begin
                          codigoHttp := 200;
                          LJSONArray            := query.ToJSONArray;
                          dados := '"rascunhos":'+ LJSONArray.Format;
                          LJSONArray.Free;
                   end;
           except
            on E: Exception do
             begin
               codigoHttp      := 500;
               tituloMensagem  := 'Erro interno';
               mensagem        := funcoes.RemoveAcento(e.Message);
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


 function removerRascunho(usuario:TJSonValue;codigoRascunho:string): TJSonObject;
   var
   query              : TFDQuery;
   conexao            : TFDConnection;
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
         query.SQL.Add('DELETE FROM rascunhonotas WHERE codigoRascunho = '''+codigoRascunho+''' and codigoUsuario = '''+usuario.FindValue('codigousuario').Value+'''');
         query.ExecSQL;

          if query.RowsAffected = 1 then
                begin
                   codigoHttp     := 200;
                   tituloMensagem := 'Tudo certo';
                   mensagem       := 'Rascunho removido';
                end else
                     begin
                       codigoHttp     := 404;
                       tituloMensagem := 'Não foi possivel remover';
                       mensagem       := 'Rascunho não existe';
                     end;
           except
            on E: Exception do
             begin
               codigoHttp     := 500;
               tituloMensagem := 'Erro interno';
               mensagem       := funcoes.RemoveAcento(e.Message);
             end;
        end;

     json := '{ '+
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


 function atualizaRascunho(usuario:TJSonValue;codigoRascunho:string;jsonNota:string;cliente:string;valor:string): TJSonObject;
   var
   query              : TFDQuery;
   conexao            : TFDConnection;
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
         query.SQL.Add('UPDATE rascunhonotas SET cliente = '''+cliente+''', valor = '''+valor+''', jsonRascunho = :json where codigoRascunho = '''+codigoRascunho+''' and codigoUsuario = '''+usuario.FindValue('codigousuario').Value+'''');

         query.Params[0].DataType := ftString;
         query.Params[0].Value    := jsonNota;

         query.ExecSQL;

          if query.RowsAffected = 1 then
                begin
                   codigoHttp     := 200;
                   tituloMensagem := 'Tudo certo';
                   mensagem       := 'Rascunho atualizado';
                end else
                     begin
                       codigoHttp     := 404;
                       tituloMensagem := 'Não foi possivel atualizar';
                       mensagem       := 'Rascunho não existe';
                     end;
           except
            on E: Exception do
             begin
               codigoHttp     := 500;
               tituloMensagem := 'Erro interno';
               mensagem       := funcoes.RemoveAcento(e.Message);
             end;
        end;

     json := '{ '+
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









end.

