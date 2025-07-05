<?php

error_reporting(E_ALL);
ini_set('display_errors', 'On');
require_once './vendor/nfephp-org/sped-da/bootstrap.php';
use NFePHP\DA\NFe\Daevento;

if(isset($_GET['id'])){
    $id = $_GET["id"];
} else {
  header("Location:https://sistemavendaki.com.br/"); 
}

try {
    $bdcon4      = mysqli_connect('localhost', 'kinotas', '2236', 'kinotas');
    $xmldata     = mysqli_query($bdcon4 , "select eventosNfe.xmlEvento,usuarios.razaoempresa,usuarios.enderecoempresa,usuarios.numeroempresa,
    usuarios.complementoempresa,usuarios.bairroempresa,usuarios.cepempresa,usuarios.cidadeempresa,
    usuarios.ufempresa,usuarios.telefoneempresa,usuarios.emailusuario from eventosNfe
    join usuarios on usuarios.codigousuario = eventosNfe.codigoUsuario
    where eventosNfe.protocolo = '$id'");

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