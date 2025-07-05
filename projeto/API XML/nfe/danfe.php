<?php
error_reporting(E_ALL);
ini_set('display_errors', 'On');
require_once './vendor/nfephp-org/sped-da/bootstrap.php' ;

use NFePHP\DA\NFe\Danfe;
//$xml = file_get_contents(__DIR__ . '/fixtures/mod55-nfe_4.xml');
//$logo = 'data://text/plain;base64,'. base64_encode(file_get_contents(realpath(__DIR__ . '/../images/tulipas.png')));
$logo = "";//realpath(__DIR__ . '/../images/tulipas.png');
    

if(isset($_GET['id'])){
          $id = $_GET["id"];
    } else {
   
        header("Location:https://sistemavendaki.com.br/"); 
    }





try {    
    $bdcon4      = mysqli_connect('localhost', 'kinotas', '2236', 'kinotas');
    $xmldata     = mysqli_query($bdcon4 , "SELECT xmlnota FROM notas_nfe WHERE  chaveacesso = '$id'");
    $reg         = mysqli_fetch_array($xmldata);
    $registro   =  mysqli_affected_rows($bdcon4);
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
             $margSup = 3,
             $margEsq = 3
         );
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