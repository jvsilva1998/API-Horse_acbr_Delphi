<?php
error_reporting(E_ALL);


if(isset($_GET['id'])){
    $id = $_GET["id"];
} else {

  header("Location:https://sistemavendaki.com.br/"); 
}

try {
    $bdcon4      = mysqli_connect('localhost', 'kinotas', '2236', 'kinotas');
    $xmldata     = mysqli_query($bdcon4 , "SELECT xmlnota,chaveacesso FROM notas_nfe WHERE  chaveacesso = '$id'");
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