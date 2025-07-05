# 🛠️ API Horse + ACBR + Delphi

Integração de uma API REST usando o Horse (framework) com componentes ACBR em Delphi, para automação de impressoras fiscais, emissão de notas, boletos, entre outros serviços.

---

## 🚀 Funcionalidades

- Configuração de servidor HTTP com Horse
- Endpoints REST com JSON de entrada/saída
- Integração com ACBR: SAT, NF-e, NFce, impressoras, leitura de balança, entre outros
- Registro de logs e tratamento de erros unificado
- Estrutura pronta para deploy Docker ou Windows Service

---

## 🧰 Requisitos

- **Delphi** 10.x ou superior
- **Bibliotecas / componentes**:
  - Horse (framework REST)
  - ACBR (SAT, NFce, SAT, Boleto, Balanca, Impressão)
- Conexão com equipamento fiscal ou emulador
- (Opcional) Banco de dados: FireDAC / UniDAC / Interbase / SQLite

---

## 📥 Instalação & Configuração

1. Clone o repositório:
   ```bash
   git clone https://github.com/jvsilva1998/API-Horse_acbr_Delphi.git
   cd API-Horse_acbr_Delphi
