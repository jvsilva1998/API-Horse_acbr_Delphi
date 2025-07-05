<?php
error_reporting(E_ALL);
ini_set('display_errors', 'On');
require_once './vendor/nfephp-org/sped-da/bootstrap.php';

use NFePHP\DA\NFe\Danfe;
use NFePHP\DA\NFe\DanfeSimples;
use NFePHP\DA\NFe\Daevento;

if(isset($_GET['id'])){
          $id = $_GET["id"];
           if (!is_numeric($id)){
            header("Location:https://sistemavendaki.com.br/");
           } else { // começa aqui // // se iniciando com os numeros (1 - danfeCompletaNFE  2 - xmlNFE 3 - danfeSimplesNFE - 4 danfeEventosNFE   5- xmlEventosNFE ) 
              
            if($id[0] == "1") {
                danfeCompletaNFE(substr($id, 1));
            }

            if($id[0] == "2") {
                xmlNFE(substr($id, 1));
            }

            if($id[0] == "3") {
                danfeSimplesNFE(substr($id, 1));
            }

            if($id[0] == "4") {
                danfeEventosNFE(substr($id, 1));
            }

            if($id[0] == "5") {
                xmlEventosNFE(substr($id, 1));
            }
           }

    } else {
        header("Location:https://sistemavendaki.com.br/"); 
    }

// funções da nfe//

function danfeCompletaNFE($id){
    try {    
        $bdcon4      = mysqli_connect('localhost', 'kinotas', '2236', 'kinotas');
        $xmldata     = mysqli_query($bdcon4 , "SELECT xmlnota,usuarios.logoempresa FROM notas_nfe inner join usuarios on notas_nfe.codusuario = usuarios.codigousuario  WHERE  notas_nfe.tiponota =1 and notas_nfe.chaveacesso = '$id'");
        $reg         = mysqli_fetch_array($xmldata);
        $registro    = mysqli_affected_rows($bdcon4);
        mysqli_close($bdcon4);    
        if ( $registro == 1){
             $xml = $reg['xmlnota']; 
             $danfe = new Danfe($xml);
             $danfe->exibirTextoFatura = false;
             $danfe->exibirPIS = false;
             $danfe->exibirIcmsInterestadual = false;
             $danfe->exibirValorTributos = false;
             $danfe->descProdInfoComplemento = false;
             $danfe->setOcultarUnidadeTributavel(true);
             $danfe->obsContShow(false);
             $danfe->printParameters(
                 $orientacao = 'P', //L- HORIZONTAL P- VERTICAL
                 $papel = 'A4',
                 $margSup = 4,
                 $margEsq = 4
             );
            if ($reg['logoempresa']){
                $logo = 'data://text/plain;base64,'.str_replace('data:image/png;base64,','',$reg['logoempresa']);
            } else {
                $logo = ''; 
            }
            
             $danfe->logoParameters($logo, $logoAlign = 'C', $mode_bw = false);
             $danfe->setDefaultFont($font = 'times');
             $danfe->setDefaultDecimalPlaces(4);
             $danfe->debugMode(false);
             $danfe->creditsIntegratorFooter('Kinotas - kinotas.com.br');
             $pdf = $danfe->render($logo);
             header('Content-Type: application/pdf');
             echo $pdf;

            } else {
                header("Location:https://sistemavendaki.com.br/");   
            }
    
    } catch (Exception $e) {
        header("Location:https://sistemavendaki.com.br/");
    } 
}   


function xmlNFE($id){
    try {
        $bdcon4      = mysqli_connect('localhost', 'kinotas', '2236', 'kinotas');
        $xmldata     = mysqli_query($bdcon4 , "SELECT xmlnota,chaveacesso FROM notas_nfe WHERE tiponota=1 and chaveacesso = '$id'");
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


function danfeSimplesNFE($id){
    try {
        $bdcon4      = mysqli_connect('localhost', 'kinotas', '2236', 'kinotas');
        $xmldata     = mysqli_query($bdcon4 , "SELECT xmlnota FROM notas_nfe WHERE tiponota=1 and chaveacesso = '$id'");
        $reg         = mysqli_fetch_array($xmldata);
        $registro   =  mysqli_affected_rows($bdcon4);
        mysqli_close($bdcon4); 
    
        if ($registro == 1){
        $xml = $reg['xmlnota'];     
        $danfe = new DanfeSimples($xml);
        $danfe->debugMode(false);
        $pdf = $danfe->render();
        header('Content-Type: application/pdf');
        echo $pdf;
    } else {
        header("Location:https://sistemavendaki.com.br/"); 
    }
    
    } catch (Exception $e) {
        header("Location:https://sistemavendaki.com.br/"); 
    }
}


function danfeEventosNFE($id){
    try {
        $bdcon4      = mysqli_connect('localhost', 'kinotas', '2236', 'kinotas');
        $xmldata     = mysqli_query($bdcon4 , "select eventosNfe.xmlEvento,usuarios.razaoempresa,usuarios.enderecoempresa,usuarios.numeroempresa,
        usuarios.complementoempresa,usuarios.bairroempresa,usuarios.cepempresa,usuarios.cidadeempresa,
        usuarios.ufempresa,usuarios.telefoneempresa,usuarios.emailusuario from eventosNfe
        join usuarios on usuarios.codigousuario = eventosNfe.codigoUsuario
        where eventosNfe.tpnpta =1 and eventosNfe.protocolo = '$id'");
    
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
        //  $daevento->logoParameters($logo, 'R');
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


function xmlEventosNFE($id){
    try {
        $bdcon4      = mysqli_connect('localhost', 'kinotas', '2236', 'kinotas');
        $xmldata     = mysqli_query($bdcon4 , "SELECT xmlEvento,protocolo FROM eventosnfe WHERE tpnpta =1 and protocolo = '$id'");
        $reg         = mysqli_fetch_array($xmldata);
        $registro   =  mysqli_affected_rows($bdcon4);
        mysqli_close($bdcon4); 
        if ($registro == 1){
        $xml = $reg['xmlEvento'];    
        header('Content-disposition: attachment; filename='.$reg['protocolo'].'.xml');
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





