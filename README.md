# Fluxo Clínicas

Sistema Ruby/Sinatra para automação ética de reativação de contatos, prospecção B2B, controle de mensagens, relatórios e acompanhamento de clínicas.

O projeto foi criado para funcionar primeiro como MVP local no Termux/Debian e depois ser preparado para hospedagem no Render com PostgreSQL.

---

## Visão geral

O Fluxo Clínicas possui dois fluxos principais:

1. Fluxo de pacientes/leads da clínica
- Cadastro manual de contatos
- Importação CSV
- Templates de campanha
- Geração de mensagens
- Abertura do WhatsApp com mensagem pronta
- Registro de respostas
- Status automático do lead
- Relatório web
- Relatório PDF

2. Fluxo de Prospects B2B
- Coleta de clínicas odontológicas via OpenStreetMap
- Importação de lotes de 50 clínicas
- Deduplicação por telefone, nome, cidade, endereço e origem
- Filtro de prospects com telefone
- Registro de contato
- Registro de resposta
- Conversão de prospect em cliente
- Histórico de eventos
- Arquivamento de ignorados após 48h
- Bloqueio de contato por 6 meses

---

## Tecnologias usadas

- Ruby
- Sinatra
- Puma
- Sequel
- SQLite para desenvolvimento local
- PostgreSQL via DATABASE_URL para produção
- Prawn para PDF
- CSV para importação/exportação
- Git/GitHub
- Render preparado via render.yaml
- Prometheus metrics via /metrics

---

## Estrutura do projeto

.
├── Gemfile
├── Gemfile.lock
├── Procfile
├── README.md
├── app
│   ├── public
│   ├── services
│   │   ├── csv_importer.rb
│   │   ├── message_scheduler.rb
│   │   ├── prospect_importer.rb
│   │   ├── prospect_manager.rb
│   │   └── response_registrar.rb
│   └── views
│       ├── campaigns.erb
│       ├── companies.erb
│       ├── contacts.erb
│       ├── dashboard.erb
│       ├── import_result.erb
│       ├── imports.erb
│       ├── layout.erb
│       ├── messages.erb
│       ├── new_contact.erb
│       ├── new_response.erb
│       ├── prospect_events.erb
│       ├── prospect_response.erb
│       ├── prospects.erb
│       ├── prospects_archive_result.erb
│       ├── prospects_import.erb
│       ├── prospects_import_result.erb
│       ├── reports.erb
│       ├── responses.erb
│       └── schedule_result.erb
├── app.rb
├── config
│   ├── database.rb
│   └── puma.rb
├── config.ru
├── db
│   ├── seeds.rb
│   └── setup.rb
├── render.yaml
├── runtime.txt
├── scripts
│   ├── backup_sqlite.sh
│   ├── coletar_clinicas_sp_lote2_osm.rb
│   ├── coletar_clinicas_sp_osm.rb
│   ├── coletar_proximo_lote_osm.rb
│   ├── limpar_prospects_duplicados.rb
│   └── simplificar_prospects.rb
└── storage
    ├── imports
    ├── prospects
    └── reports

---

## Rotas principais

| Rota | Função |
|---|---|
| / | Dashboard principal |
| /contacts | Contatos/pacientes/leads |
| /contacts/new | Novo contato manual |
| /campaigns | Templates de campanha |
| /messages | Fila de mensagens |
| /responses | Respostas recebidas |
| /imports | Importação de contatos CSV |
| /reports | Relatório web |
| /reports/pdf | Relatório PDF |
| /prospects | Prospects B2B |
| /prospects/import | Importar clínicas B2B |
| /companies | Clientes confirmados |
| /health | Health check |
| /metrics | Métricas Prometheus |

---

## Rodar localmente

Instalar dependências:

bundle install

Criar/verificar banco:

ruby db/setup.rb

Criar templates padrão:

ruby db/seeds.rb

Rodar o app:

ruby app.rb

Acessar:

http://127.0.0.1:4567

---

## Banco de dados

O projeto usa conexão dinâmica em config/database.rb.

Se DATABASE_URL estiver vazia, usa SQLite local:

db/fluxo_clinicas.sqlite3

Se DATABASE_URL existir, usa PostgreSQL:

DATABASE_URL=postgres://usuario:senha@host:5432/banco

Isso permite desenvolvimento local com SQLite e produção no Render com PostgreSQL.

---

## Backup local

Criar backup do SQLite:

./scripts/backup_sqlite.sh

Os backups ficam em:

backups/

---

## Coleta de clínicas odontológicas

Coletar primeiro lote:

ruby scripts/coletar_clinicas_sp_osm.rb

Coletar lote 2:

ruby scripts/coletar_clinicas_sp_lote2_osm.rb

Coletar próximo lote inteligente, evitando duplicados já existentes no banco:

FETCH_LIMIT=800 ruby scripts/coletar_proximo_lote_osm.rb

Os arquivos ficam em:

storage/prospects/

Exemplos:

clinicas_odontologicas_sp_50.csv
clinicas_odontologicas_sp_lote_002.csv
clinicas_odontologicas_sp_lote_003.csv

---

## Deduplicação de prospects

Limpar duplicados:

ruby scripts/limpar_prospects_duplicados.rb

A deduplicação considera:

- Telefone/WhatsApp
- Nome
- Cidade
- Endereço
- Fonte e ID do OpenStreetMap

---

## Fluxo de Prospects B2B

1. Coletar lote de clínicas.
2. Importar até 50 clínicas.
3. Filtrar prospects com telefone.
4. Abrir WhatsApp com mensagem pronta.
5. Marcar como contatado.
6. Registrar resposta.
7. Se confirmar, converter em cliente.
8. Se ignorar por mais de 48h, arquivar.
9. Bloquear novo contato por 6 meses.
10. Buscar próximo lote sem duplicar.

Tela recomendada para operação:

/prospects?phone=with

---

## Mensagem B2B padrão

Olá, tudo bem? Sou da Fluxo Clínicas. Ajudamos clínicas odontológicas a reativar pacientes antigos pelo WhatsApp e entregar somente os interessados para agendamento. Posso te mostrar como funcionaria para a sua clínica?

---

## Métricas Prometheus

Endpoint:

/metrics

Exemplos de métricas:

fluxo_clinicas_contacts_total
fluxo_clinicas_messages_total
fluxo_clinicas_messages_pending_total
fluxo_clinicas_messages_sent_total
fluxo_clinicas_messages_failed_total
fluxo_clinicas_responses_total
fluxo_clinicas_interested_total
fluxo_clinicas_schedule_total
fluxo_clinicas_converted_total
fluxo_clinicas_response_rate_percent
fluxo_clinicas_interest_rate_percent
fluxo_clinicas_conversion_rate_percent
fluxo_clinicas_contacts_by_status

---

## Render

O projeto possui render.yaml.

Build command sugerido:

bundle install && ruby db/setup.rb && ruby db/seeds.rb

Start command:

bundle exec rackup config.ru -p $PORT -o 0.0.0.0

Health check:

/health

Em produção, use PostgreSQL via DATABASE_URL.

---

## GitHub Actions

O projeto possui pipeline CI em:

.github/workflows/ci.yml

O CI verifica:

- Instalação Ruby
- Instalação de gems
- Sintaxe do app.rb
- Setup do banco
- Seeds
- Rota /health
- Rota /metrics

---

## Cuidados éticos e LGPD

Este sistema deve ser usado somente com dados legítimos e públicos ou bases autorizadas.

Boas práticas:

- Não usar dados de pacientes sem autorização da clínica.
- Não enviar mensagens em massa abusivas.
- Respeitar pedidos de remoção ou não perturbar.
- Não prometer resultados clínicos, financeiros ou estéticos.
- Registrar histórico de contato.
- Evitar contatar a mesma clínica novamente em menos de 6 meses.
- Priorizar contato comercial respeitoso e manual no início.

---

## Status atual do MVP

- Dashboard funcionando
- Contatos funcionando
- Importação CSV funcionando
- Campanhas funcionando
- Fila de mensagens funcionando
- WhatsApp manual funcionando
- Registro de respostas funcionando
- Relatórios funcionando
- PDF funcionando
- Prospects B2B funcionando
- Coleta OpenStreetMap funcionando
- Deduplicação funcionando
- PostgreSQL preparado
- Render preparado
- Pipeline CI preparado

---

## Próximas melhorias

- Paginação de prospects
- Login de usuário
- Multiempresa
- Upload CSV pelo navegador
- Filtro avançado por cidade
- Exportação de prospects para CSV
- Dashboard B2B separado
- Worker para rotinas automáticas
- Integração com WhatsApp Business API
- Cobrança via Pix, Asaas ou Mercado Pago
