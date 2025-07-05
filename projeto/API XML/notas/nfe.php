<?php


if(isset($_GET['id'])){
  $id = $_GET["id"];
   if (!is_numeric($id)){
    header("Location:https://sistemavendaki.com.br/");
   } else { // começa aqui // // se iniciando com os numeros (1 - notasNFE  2 - eventosNFE 
      
    if($id[0] == "1") {
      notasNFE(substr($id, 1));
    }

    if($id[0] == "2") {
      eventosNFE(substr($id, 1));
    }
   }
} else {
header("Location:https://sistemavendaki.com.br/"); 
}


     function notasNFE($id) {
        $bdcon4       = mysqli_connect('localhost', 'kinotas', '2236', 'kinotas');
        $xmldata      = mysqli_query($bdcon4 ,"SELECT nomedestinatario  FROM notas_nfe WHERE tiponota=1 and chaveacesso = '$id'");

        $registro   =  mysqli_affected_rows($bdcon4);
        mysqli_close($bdcon4); 

        if ($registro == 1){
          $reg          = mysqli_fetch_array($xmldata);
          $destinatario = $reg['nomedestinatario']; 
           
          echo '<!doctype html>
          <html lang="pt-br">
         <head>
           <meta charset="utf-8">
           <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
           <meta name="description" content="">
           <meta name="author" content="">
           <link rel="icon" href="favicon.ico">
         
           <title>'.mb_convert_case(ucfirst(strtolower(($destinatario))), MB_CASE_TITLE, "UTF-8").' , sua NF-e está aqui - kinotas.com.br</title>
         
           <link href="bootstrap.min.css" rel="stylesheet">
           <link href="pricing.css" rel="stylesheet">
         </head>
         
         
         <body>
           <div class="d-flex flex-column flex-md-row align-items-center p-3 px-md-4 mb-3 bg-white border-bottom shadow-sm">
             <h5 class="my-0 mr-md-auto font-weight-normal">Kinotas</h5>
           </div>
         
           <div class="pricing-header px-3 py-3 pt-md-5 pb-md-4 mx-auto text-center">
             <h1 style="font-size:25px">Olá, '.$destinatario.'</h1>
             <p class="lead">Foi gerada uma nota fiscal pra você, e pra  facilitar a sua vida basta escolher uma das opções abaixo..</p>
           </div>
         
           <div class="container">
             <div class="card-deck mb-3 text-center">
               <div class="card mb-4 shadow-sm">
                 <div class="card-header">
                   <h4 class="my-0 font-weight-normal">PDF SIMPLES</h4>
                 </div>
                 <div class="card-body">
                   <ul class="list-unstyled mt-3 mb-4">
                     <li>DANFE simplificado</li>
                     <li>Informações de endereço</li>
                     <li>Serve como etiqueta dos correios</li>
                   </ul>
                   <button type="button" class="btn btn-lg btn-block btn-primary" onclick="location.href=\'http://api.kinotas.com.br:82/nfe/nfe.php?id=3'.$id.'\'" type="button" class="btn btn-lg btn-block btn-outline-primary">VER</button>
                 </div>
               </div>
               <div class="card mb-4 shadow-sm">
                 <div class="card-header">
                   <h4 class="my-0 font-weight-normal">PDF COMPLETO</h4>
                 </div>
                 <div class="card-body">
                   <ul class="list-unstyled mt-3 mb-4">
                     <li>DANFE completo</li>
                     <li>Exibe todos os produtos</li>
                     <li>Nota fiscal padrão</li>
                   </ul>
                   <button  onclick="location.href=\'http://api.kinotas.com.br:82/nfe/nfe.php?id=1'.$id.'\'" type="button" class="btn btn-lg btn-block btn-primary">VER</button>
                 </div>
               </div>
               <div class="card mb-4 shadow-sm">
                 <div class="card-header">
                   <h4 class="my-0 font-weight-normal">XML DA NOTA</h4>
                 </div>
                 <div class="card-body">
                   <ul class="list-unstyled mt-3 mb-4">
                     <li>Arquivo da Nota Fiscal</li>
                     <li>Formato XML</li>
                     <li>Serve para a contabilidade</li>
                   </ul>
                   <button onclick="location.href=\'http://api.kinotas.com.br:82/nfe/nfe.php?id=2'.$id.'\'" type="button"  class="btn btn-lg btn-block btn-primary">BAIXAR</button>
                 </div>
               </div>
             </div>
         
           <script src="https://code.jquery.com/jquery-3.3.1.slim.min.js" integrity="sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo" crossorigin="anonymous"></script>
           <script>window.jQuery || document.write("<script src="../../assets/js/vendor/jquery-slim.min.js"><\/script>")</script>
           <script src="popper.min.js"></script>
           <script src="bootstrap.min.js"></script>
           <script src="holder.min.js"></script>
           <script>
             Holder.addTheme("thumb", {
               bg: "#55595c",
               fg: "#eceeef",
               text: "Thumbnail"
             });
           </script>
         </body>
         </html>';
            } else {
              header("Location:https://sistemavendaki.com.br/"); 
          }
            
          
    }

     function eventosNFE($id) {
        $bdcon4       = mysqli_connect('localhost', 'kinotas', '2236', 'kinotas');
        $xmldata      = mysqli_query($bdcon4 ," select eventosNfe.tipoEvento,notas_nfe.serienota,notas_nfe.numeronota from eventosNfe
        join notas_nfe on notas_nfe.id = eventosNfe.idNfe
        where eventosNfe.protocolo = '$id'");

        $registro   =  mysqli_affected_rows($bdcon4);
        mysqli_close($bdcon4); 
        
      
        if ($registro == 1){
          $reg          = mysqli_fetch_array($xmldata);
          
          if ($reg['tipoEvento'] == '1'){ 
              $destinatario = 'Cancelamento';
          }

          if ($reg['tipoEvento'] == '2'){ 
            $destinatario = 'Correção';
        }
                  
          echo '<!doctype html>
          <html lang="pt-br">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
          <meta name="description" content="">
          <meta name="author" content="">
          <link rel="icon" href="favicon.ico">
        
          <title> Um evento de '.$destinatario.' foi registrado na sua NFe - kinotas.com.br</title>
        
          <link href="bootstrap.min.css" rel="stylesheet">
          <link href="pricing.css" rel="stylesheet">
        </head>
        
        
        <body>
          <div class="d-flex flex-column flex-md-row align-items-center p-3 px-md-4 mb-3 bg-white border-bottom shadow-sm">
            <h5 class="my-0 mr-md-auto font-weight-normal">Kinotas</h5>
          </div>
        
          <div class="pricing-header px-3 py-3 pt-md-5 pb-md-4 mx-auto text-center">
            <h1 style="font-size:25px">Olá, Tudo bem? </h1>
            <p class="lead">Um evento de '.$destinatario.' foi registrado em uma NFe com o Nª '.$reg['numeronota'].' e Série '.$reg['serienota'].'  </p>
          </div>
        
          <div class="container">
            <div class="card-deck mb-3 text-center">
              <div class="card mb-4 shadow-sm">
                <div class="card-header">
                  <h4 class="my-0 font-weight-normal">PDF DO EVENTO</h4>
                </div>
                <div class="card-body">
                  <ul class="list-unstyled mt-3 mb-4">
                    <li>DANFE simplificado</li>
                    <li>Informações do evento</li>
                    <li>Serve como comprovante</li>
                  </ul>
                  <button type="button" class="btn btn-lg btn-block btn-primary" onclick="location.href=\'http://api.kinotas.com.br:82/nfe/nfe.php?id=4'.$id.'\'" type="button" class="btn btn-lg btn-block btn-outline-primary">VER</button>
                </div>
              </div>

              <div class="card mb-4 shadow-sm">
                <div class="card-header">
                  <h4 class="my-0 font-weight-normal">XML DO EVENTO</h4>
                </div>
                <div class="card-body">
                  <ul class="list-unstyled mt-3 mb-4">
                    <li>Arquivo do evento</li>
                    <li>Formato XML</li>
                    <li>Serve para a contabilidade</li>
                  </ul>
                  <button onclick="location.href=\'http://api.kinotas.com.br:82/nfe/nfe.php?id=5'.$id.'\'" type="button"  class="btn btn-lg btn-block btn-primary">BAIXAR</button>
                </div>
              </div>
            </div>
        
          <script src="https://code.jquery.com/jquery-3.3.1.slim.min.js" integrity="sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo" crossorigin="anonymous"></script>
          <script>window.jQuery || document.write("<script src="../../assets/js/vendor/jquery-slim.min.js"><\/script>")</script>
          <script src="popper.min.js"></script>
          <script src="bootstrap.min.js"></script>
          <script src="holder.min.js"></script>
          <script>
            Holder.addTheme("thumb", {
              bg: "#55595c",
              fg: "#eceeef",
              text: "Thumbnail"
            });
          </script>
        </body>
        </html>';
            } else {
              header("Location:https://sistemavendaki.com.br/"); 
          }
             
    } 

  ?>





 

  





