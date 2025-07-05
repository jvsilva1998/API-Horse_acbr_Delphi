
/* Tables */
CREATE TABLE anp (
  codigo     varchar(30),
  descricao  varchar(500)
) ENGINE = InnoDB;

CREATE TABLE bancos (
  cod    bigint,
  banco  varchar(200)
) ENGINE = InnoDB;

CREATE TABLE campanhas (
  id_campanha    varchar(20),
  nome           varchar(100),
  data_inicio    date,
  data_fim       date,
  url_destino    text,
  url_imagem     text,
  cor_fundo      varchar(10),
  cor_fundo2     varchar(10),
  data_cadastro  date
) ENGINE = InnoDB;

CREATE TABLE cfop (
  cfop       varchar(40),
  descricao  text
) ENGINE = InnoDB;

CREATE TABLE clientes (
  nome_razao         varchar(200),
  fantasia_apelido   varchar(200),
  tipo_cliente       varchar(5),
  tipo_contribuinte  varchar(5),
  cpf_cnpj           varchar(50),
  ie                 varchar(50),
  im                 varchar(50),
  endereco           varchar(400),
  numero             varchar(20),
  complemento        varchar(200),
  bairro             varchar(400),
  cidade             varchar(400),
  telefone           varchar(20),
  celular            varchar(20),
  email              varchar(400),
  uf                 varchar(5),
  cep                varchar(15),
  obs                varchar(800),
  cod_cidade         varchar(20),
  cod_cliente        varchar(50),
  cod_usuario        varchar(50),
  data_cadastro      date,
  hora_cadastro      time,
  pais               varchar(40),
  codigo_pais        varchar(20)
) ENGINE = InnoDB;

CREATE TABLE desempenho_campanhas (
  id_campanha  varchar(30),
  id_usuario   varchar(30),
  data_click   date,
  hora_click   time,
  id_click     varchar(30)
) ENGINE = InnoDB;

CREATE TABLE eventosnfe (
  idEvento       varchar(60),
  idNfe          varchar(60),
  tipoEvento     int,
  dataEvento     date,
  horaEvento     time,
  motivoEvento   varchar(800),
  protocolo      varchar(30),
  xmlEvento      blob,
  codigoUsuario  varchar(60),
  tpnpta         int
) ENGINE = InnoDB;

CREATE TABLE historico_movimento_indicacoes (
  codigomovimentacao  varchar(50),
  codigoindicacao     varchar(50),
  codigousuario       varchar(50),
  datamovimento       date,
  horamovimento       time,
  titulomovimento     varchar(60),
  descricaomovimento  varchar(80),
  tipomovimento       char(4),
  valormovimento      decimal(9,2),
  linkexterno         varchar(800)
) ENGINE = InnoDB;

CREATE TABLE inutilizacaonfe (
  id             varchar(60),
  `data`         date,
  hora           time,
  ano            varchar(10),
  serie          varchar(20),
  numeroInicio   int,
  numeroFim      int,
  tpAmbiente     int,
  justificativa  varchar(800),
  protocolo      varchar(30),
  xml            blob,
  codigoUsuario  varchar(60),
  tpnota         int
) ENGINE = InnoDB;

CREATE TABLE municipio (
  codigo  varchar(30),
  nome    varchar(255),
  uf      char(2)
) ENGINE = InnoDB;

CREATE TABLE naturezas (
  descricao          varchar(200),
  codfinalidade      varchar(5),
  cfopestadual       varchar(10),
  cfopinterestadual  varchar(10),
  datacadastro       date,
  horacadastro       time,
  cod_natureza       varchar(50),
  cod_usuario        varchar(50),
  tiponfe            int
) ENGINE = InnoDB;

CREATE TABLE ncm (
  ncm        varchar(40),
  descricao  text
) ENGINE = InnoDB;

CREATE TABLE notas_nfe (
  id                     varchar(20),
  serienota              varchar(20),
  numeronota             varchar(20),
  protocolo              varchar(40),
  chaveacesso            varchar(44),
  xmlnota                blob,
  finalidade             int,
  ambiente               int,
  valornota              decimal(9,2),
  statusnota             varchar(20),
  dataenvio              date,
  horaenvio              time,
  nomedestinatario       varchar(100),
  documentodestinatario  varchar(40),
  codusuario             varchar(60),
  tiponota               int
) ENGINE = InnoDB;

CREATE TABLE paises (
  codigo  varchar(30),
  pais    varchar(50)
) ENGINE = InnoDB;

CREATE TABLE perfil_tributario (
  nome_perfil     varchar(60),
  cod_icms_cst    varchar(10),
  cod_mod_bc      varchar(10),
  cod_cson_cst    varchar(10),
  cod_cst_cofins  varchar(10),
  cod_trib_pis    varchar(10),
  cod_ipi_cst     varchar(10),
  perc_icms       varchar(20),
  perc_pis        varchar(20),
  perc_ipi        varchar(20),
  perc_cofins     varchar(20),
  cod_perfil      varchar(50),
  cod_usuario     varchar(50)
) ENGINE = InnoDB;

CREATE TABLE produtos (
  codigointerno           varchar(100),
  codigobarras            varchar(100),
  descricao               varchar(200),
  preco                   varchar(15),
  peso                    varchar(50),
  medida                  varchar(15),
  ncm                     varchar(50),
  cest                    varchar(50),
  nomeperfiltributario    varchar(100),
  codigoperfiltributario  varchar(30),
  ibptmunicipal           varchar(10),
  ibptestadual            varchar(10),
  ibptfederal             varchar(10),
  cod_produto             varchar(50),
  data_cadastro           date,
  hora_cadastro           time,
  cod_usuario             varchar(50),
  origem                  varchar(10),
  observacoes             varchar(500),
  cfopinterno             varchar(10),
  cfopexterno             varchar(10),
  descricaoanp            varchar(200),
  codigoanp               varchar(40)
) ENGINE = InnoDB;

CREATE TABLE rascunhonotas (
  codigoRascunho  varchar(50),
  cliente         varchar(200),
  valor           varchar(20),
  dataRascunho    date,
  horaRascunho    time,
  jsonRascunho    text,
  tipoNota        int,
  codigoUsuario   varchar(50)
) ENGINE = InnoDB;

CREATE TABLE solicita_saque_indicacao (
  codigosocilitacao       varchar(40),
  statussolicitacao       varchar(30),
  valor                   decimal(9,2),
  datasolicitacao         date,
  horasolicitacao         time,
  datavencimentoresposta  date,
  horavencimentoresposta  time,
  codigoindicacao         varchar(30),
  codigousuario           varchar(60)
) ENGINE = InnoDB;

CREATE TABLE tab_cest (
  cest       varchar(15) NOT NULL,
  ncm        varchar(15),
  descricao  text
) ENGINE = InnoDB;

CREATE TABLE transportadoras (
  nome_razao           varchar(200),
  tipo_transportadora  int,
  cpf_cnpj             varchar(50),
  ie                   varchar(50),
  im                   varchar(50),
  endereco             varchar(400),
  numero               varchar(20),
  bairro               varchar(400),
  cidade               varchar(400),
  telefone             varchar(20),
  celular              varchar(20),
  email                varchar(400),
  uf                   varchar(5),
  cep                  varchar(15),
  obs                  varchar(800),
  cod_transportadora   varchar(50),
  cod_usuario          varchar(50),
  data_cadastro        date,
  hora_cadastro        time
) ENGINE = InnoDB;

CREATE TABLE upcell (
  id          varchar(50),
  produto     varchar(200),
  descricao   varchar(500),
  valor       decimal(9,2),
  imagemUrl   varchar(900),
  textoBotao  varchar(200)
) ENGINE = InnoDB
  CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

CREATE TABLE usuarios (
  cnpjempresa                  varchar(20),
  razaoempresa                 varchar(500),
  fantasiaempresa              varchar(500),
  ieempresa                    varchar(50),
  imempresa                    varchar(50),
  cnaeempresa                  varchar(50),
  telefoneempresa              varchar(20),
  enderecoempresa              varchar(500),
  complementoempresa           varchar(200),
  numeroempresa                varchar(20),
  cepempresa                   varchar(20),
  bairroempresa                varchar(500),
  cidadeempresa                varchar(500),
  ufempresa                    varchar(10),
  regimeempresa                varchar(2),
  segmentoempresa              varchar(2),
  coduf                        varchar(20),
  ibgemunicipio                varchar(30),
  datacadastro                 date,
  horacadastro                 time,
  tokenusuario                 text,
  emailusuario                 varchar(600),
  codigousuario                varchar(50),
  nomeusuario                  varchar(100),
  senhausuario                 varchar(100),
  nfeserie                     int DEFAULT 0,
  nfenumero                    int DEFAULT 0,
  nfeambiente                  int DEFAULT 1,
  nfceserie                    int DEFAULT 0,
  nfcenumero                   int DEFAULT 0,
  nfcecsc                      varchar(200),
  nfceidcsc                    varchar(20),
  nfceambiente                 int DEFAULT 1,
  contadornome                 varchar(100),
  contadoremail                varchar(200),
  contadorcnpj                 varchar(20),
  contadortelefone             varchar(20),
  certificadosenha             varchar(50),
  seriecertificado             varchar(100),
  validadecertificado          varchar(10),
  vencimentolicenca            date,
  celularusuario               varchar(20),
  codigoindicacao              varchar(30),
  licencaatual                 varchar(50),
  bloqueado                    char(2),
  idcobranca                   varchar(70),
  referenciaindicacao          varchar(30),
  saldoindicacoes              decimal(9,2) DEFAULT 0.00,
  pushtoken                    varchar(50),
  bancoindicacao               varchar(300),
  tipocontaindicacao           varchar(20),
  agenciabancoindicacao        varchar(40),
  contabancoindicacao          varchar(50),
  logoempresa                  blob,
  nfeobservacao                varchar(900),
  nfceobservacoes              varchar(900),
  quantidadecredito            int DEFAULT 0,
  saldocredito                 decimal(9,2) DEFAULT 0.00,
  creditousado                 decimal(9,2) DEFAULT 0.00,
  nfeusados                    int DEFAULT 0,
  vencimentocredito            date,
  notasgratis                  int DEFAULT 2,
  quantidadecreditocontratado  int DEFAULT 1,
  nfcelargura                  int DEFAULT 80
) ENGINE = InnoDB;

CREATE TABLE vendas_credito (
  idvenda           varchar(30),
  codigocobranca    varchar(40),
  urlfatura         varchar(900),
  valor             decimal(9,2),
  quantidadeNotas   int,
  vencimento_venda  date,
  data_venda        date,
  hora_venda        time,
  status_venda      varchar(40),
  cod_usuario       varchar(40)
) ENGINE = InnoDB;

CREATE TABLE vendas_usuarios (
  idvenda           varchar(30),
  codigocobranca    varchar(40),
  urlfatura         varchar(900),
  plano             varchar(600),
  valor             decimal(9,2),
  vencimento_venda  date,
  data_venda        date,
  hora_venda        time,
  status_venda      varchar(40),
  dias_vencimento   int,
  cod_usuario       varchar(40),
  vencimentoplano   date
) ENGINE = InnoDB;

CREATE TABLE xml_gerados (
  id           varchar(20),
  codusuario   varchar(60),
  dataInicio   date,
  dataFim      date,
  dataExpira   date,
  dataEmissao  date,
  tiponota     int
) ENGINE = InnoDB;