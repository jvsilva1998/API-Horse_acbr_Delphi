<?php
error_reporting(E_ALL);
ini_set('display_errors', 'On');
require_once '../bootstrap.php';

use NFePHP\DA\NFe\Danfe;
//$xml = file_get_contents(__DIR__ . '/fixtures/mod55-nfe_4.xml');
//$logo = 'data://text/plain;base64,'. base64_encode(file_get_contents(realpath(__DIR__ . '/../images/tulipas.png')));
$logo = "";//realpath(__DIR__ . '/../images/tulipas.png');

   $id = $_GET["id"];

    $bdcon4      = pg_connect("host=localhost port=5432 dbname=kinotas user=postgres password=2236");
    $xmldata     = pg_query($bdcon4 , "SELECT xmlnota FROM notas_nfe WHERE  id = '$id'");
    $reg         = pg_fetch_result($xmldata, 'xmlnota');
    $xmlnovo     = pg_unescape_bytea($reg); 
   // pg_close();
    $xml =$xmlnovo;

try {
    
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
    //$danfe->epec('891180004131899', '14/08/2018 11:24:45'); //marca como autorizada por EPEC
    
    // Caso queira mudar a configuracao padrao de impressao
    /*  $this->printParameters( $orientacao = '', $papel = 'A4', $margSup = 2, $margEsq = 2 ); */
    // Caso queira sempre ocultar a unidade tributável
    /*  $this->setOcultarUnidadeTributavel(true); */
    //Informe o numero DPEC
    /*  $danfe->depecNumber('123456789'); */
    //Configura a posicao da logo
    /*  $danfe->logoParameters($logo, 'C', false);  */
    //Gera o PDF
    $pdf = $danfe->render($logo);
    header('Content-Type: application/pdf');
    echo $pdf;
} catch (InvalidArgumentException $e) {
    echo "Ocorreu um erro durante o processamento :" . $e->getMessage();
}    