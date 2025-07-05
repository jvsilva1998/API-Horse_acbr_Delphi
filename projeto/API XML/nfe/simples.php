<?php
error_reporting(E_ALL);
ini_set('display_errors', 'On');
require_once './vendor/nfephp-org/sped-da/bootstrap.php';

use NFePHP\DA\NFe\DanfeSimples;


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