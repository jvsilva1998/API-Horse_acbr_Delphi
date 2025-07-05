<?php
error_reporting(E_ALL);
ini_set('display_errors', 'On');
require_once './vendor/nfephp-org/sped-da/bootstrap.php';

use NFePHP\DA\NFe\Daevento;
use NFePHP\DA\NFe\Danfce;

if(isset($_GET['id'])){
          $id = $_GET["id"];
           if (!is_numeric($id)){
            header("Location:https://sistemavendaki.com.br/");
           } else { // começa aqui // // se iniciando com os numeros (1 - danfeCompletaNFE  2 - xmlNFE 3 - danfeSimplesNFE - 4 danfeEventosNFE   5- xmlEventosNFE ) 
              
            if($id[0] == "1") {
                danfeNFCE(substr($id, 1));
            }

            if($id[0] == "2") {
                xmlNFCE(substr($id, 1));
            }

            if($id[0] == "3") {
                danfeEventosNFCE(substr($id, 1));
            }
           }

    } else {
        header("Location:https://sistemavendaki.com.br/"); 
    }




function danfeNFCE($id){
    try {    
        $bdcon4      = mysqli_connect('localhost', 'kinotas', '2236', 'kinotas');
        $xmldata     = mysqli_query($bdcon4 , "SELECT xmlnota,usuarios.logoempresa,usuarios.nfcelargura FROM notas_nfe inner join usuarios on notas_nfe.codusuario = usuarios.codigousuario  WHERE tiponota =2 and notas_nfe.chaveacesso = '$id'");
        $reg         = mysqli_fetch_array($xmldata);
        $registro    = mysqli_affected_rows($bdcon4);
        mysqli_close($bdcon4);    
    
        if ( $registro == 1){
             $xml = $reg['xmlnota']; 
             $danfce = new Danfce($xml);
             $danfce->debugMode(true);//seta modo debug, deve ser false em produção
             $danfce->setPaperWidth($reg['nfcelargura']); //seta a largura do papel em mm max=80 e min=58
             $danfce->setMargins(3);//seta as margens
             $danfce->setDefaultFont('arial');//altera o font pode ser 'times' ou 'arial'
             $danfce->setOffLineDoublePrint(true); //ativa ou desativa a impressão conjunta das via do consumidor e da via do estabelecimento qnado a nfce for emitida em contingência OFFLINE
             //$danfce->setPrintResume(true); //ativa ou desativa a impressao apenas do resumo
             //$danfce->setViaEstabelecimento(); //altera a via do consumidor para a via do estabelecimento, quando a NFCe for emitida em contingência OFFLINE
             //$danfce->setAsCanceled(); //força marcar nfce como cancelada 

            if ($reg['logoempresa']){
                $logo = 'data://text/plain;base64,'.str_replace('data:image/png;base64,','',$reg['logoempresa']);
            } else {
                $logo = ''; 
            }

            $danfce->creditsIntegratorFooter('Kinotas - www.kinotas.com.br');
            $pdf = $danfce->render($logo);
            header('Content-Type: application/pdf');
            echo $pdf;
            
            } else {
                header("Location:https://sistemavendaki.com.br/");   
            }
    
    } catch (Exception $e) {
        header("Location:https://sistemavendaki.com.br/");
    } 
}   

function xmlNFCE($id){
    try {
        $bdcon4      = mysqli_connect('localhost', 'kinotas', '2236', 'kinotas');
        $xmldata     = mysqli_query($bdcon4 , "SELECT xmlnota,chaveacesso FROM notas_nfe WHERE tiponota =2 and chaveacesso = '$id'");
        $reg         = mysqli_fetch_array($xmldata);
        $registro   =  mysqli_affected_rows($bdcon4);
        mysqli_close($bdcon4); 
    
        if ($registro == 1){
        $xml = $reg['xmlnota'];    
        header('Content-disposition: attachment; filename='.$reg['chaveacesso'].'.xml');
        header ("Content-Type:text/xml"); 
        echo $xml;
        } else 
           {
            header("Location:https://sistemavendaki.com.br/"); 
           }
    
    } catch (InvalidArgumentException $e) {
        header("Location:https://sistemavendaki.com.br/"); 
    }

}

function danfeEventosNFCE($id){
    try {
        $bdcon4      = mysqli_connect('localhost', 'kinotas', '2236', 'kinotas');
        $xmldata     = mysqli_query($bdcon4 , "select eventosNfe.xmlEvento,usuarios.razaoempresa,usuarios.enderecoempresa,usuarios.numeroempresa,
        usuarios.complementoempresa,usuarios.bairroempresa,usuarios.cepempresa,usuarios.cidadeempresa,
        usuarios.ufempresa,usuarios.telefoneempresa,usuarios.emailusuario from eventosNfe
        join usuarios on usuarios.codigousuario = eventosNfe.codigoUsuario
        where tpnpta =2 and eventosNfe.protocolo = '$id'");
    
        $reg         = mysqli_fetch_array($xmldata);
        $registro   =  mysqli_affected_rows($bdcon4);
        mysqli_close($bdcon4);
    
        if ($registro == 1){
            $xml = $reg['xmlEvento']; 
    
            $dadosEmitente = [
                'razao' => utf8_encode($reg['razaoempresa']),
                'logradouro' => utf8_encode($reg['enderecoempresa']),
                'numero' => $reg['numeroempresa'],
                'complemento' => utf8_encode($reg['complementoempresa']),
                'bairro' => utf8_encode($reg['bairroempresa']),
                'CEP' => $reg['cepempresa'],
                'municipio' =>utf8_encode($reg['cidadeempresa']),
                'UF' => $reg['ufempresa'],
                'telefone' => $reg['telefoneempresa'],
                'email' => $reg['emailusuario']
            ];     
    
            $daevento = new Daevento($xml, $dadosEmitente);
            $daevento->debugMode(true);
            $daevento->creditsIntegratorFooter('Kinotas - kinotas.com.br');
            $daevento->printParameters('P','A4');
            $pdf = $daevento->render();
            header('Content-Type: application/pdf');
            echo $pdf;
        } else {
            header("Location:https://sistemavendaki.com.br/"); 
        }
    
    } catch (\Exception $e) {
        header("Location:https://sistemavendaki.com.br/"); 
    }
}








