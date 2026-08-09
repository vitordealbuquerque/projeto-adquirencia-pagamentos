# Panorama de Pagamentos — Adquirência 2024

Projeto de portfólio para transição de carreira para Análise de Dados. Setor: **meios de pagamento (adquirência/maquininha)**. Ciclo completo: modelagem SQL, limpeza, análise e dashboard executivo em Power BI.

Passo a passo de como o dashboard foi montado (modelo, medidas DAX, gráficos): [`GUIA_POWER_BI.md`](GUIA_POWER_BI.md). Documentação completa do projeto: [`DOCUMENTACAO_PROJETO.md`](DOCUMENTACAO_PROJETO.md).

---

## A base

Base sintética (mas calibrada com padrões reais de mercado de adquirência) de uma operadora fictícia de maquininhas de cartão em 2024: 3.000 lojistas cadastrados, 3.990 maquininhas ativadas e 60.000 transações processadas, cobrindo as 19 UFs mais representativas do país. Cada transação carrega bandeira, modalidade (débito, crédito à vista, crédito parcelado), taxa de MDR aplicada, status (aprovada, negada ou chargeback) e, quando aprovada, se houve antecipação de recebíveis.

Os números a seguir vieram de execução real de SQL contra essa base, não são estimativa: 60.000 transações, 54.693 aprovadas, 4.114 negadas e 1.193 chargebacks. Taxa de aprovação de 91,16% e chargeback rate de 1,99%. TPV (volume total processado) de R$ 7.710.096,87, com ticket médio de R$ 140,97. Receita de MDR de R$ 203.760,95, equivalente a uma taxa média blended de 2,64% sobre o volume.

---

## Como o projeto foi montado

A base foi gerada em Python, com distribuições calibradas para reproduzir padrões reais de adquirência: MDR menor no débito e maior no crédito parcelado, taxa de aprovação em torno de 91%, chargeback rate abaixo de 2%, e sazonalidade de volume puxada por Black Friday e Natal em novembro e dezembro.

A modelagem, limpeza e análise rodaram em PostgreSQL, num schema próprio (`adquirencia`). O pipeline usa CTE, window functions (`RANK` para ranquear lojistas por volume e `LAG` para calcular o crescimento mês a mês) e `PERCENTILE_CONT` para medir a distribuição de ticket por segmento de lojista. Os 10 blocos de análise estão em `02_sql/04_analises.sql`.

O dashboard final foi montado no Power BI, com modelo semântico próprio, medidas DAX e visuais nativos (cartão, linha, rosca, barras e colunas com eixo duplo). O passo a passo completo, incluindo o prompt da imagem de fundo usada como base do layout, está em `GUIA_POWER_BI.md`.

---

## Estrutura do repositório

```
projeto-adquirencia-pagamentos/
├── README.md
├── DOCUMENTACAO_PROJETO.md           # documentação completa do projeto (conceitos, dataset, checklist)
├── GUIA_POWER_BI.md                  # passo a passo do dashboard: modelo, medidas DAX, gráficos
├── 02_sql/
│   ├── 01_criar_tabelas.sql          # DDL + índices + constraints
│   ├── 02_carregar_dados.sql         # COPY dos CSV
│   ├── 03_limpeza.sql                # checagens + colunas derivadas
│   └── 04_analises.sql               # 10 KPIs com CTE/RANK/LAG/PERCENTILE_CONT
├── 03_dados/
│   ├── lojistas.csv                  # 3.000 lojistas cadastrados
│   ├── maquininhas.csv               # 3.990 maquininhas ativadas
│   └── transacoes.csv                # 60.000 transações em 2024
├── 04_dashboard_pagamentos.xlsx      # dashboard executivo com fórmulas
├── 05_post_linkedin.md               # texto pronto pra postar
└── 06_prints/                        # imagens reais do projeto
    ├── fluxograma_ferramentas.png    # pipeline de ferramentas (Python → PostgreSQL → Power BI → GitHub)
    ├── capa_linkedin.png             # capa com os KPIs principais
    ├── print_dashboard_final.png     # dashboard Power BI completo
    ├── print_sql_modalidade_mdr.png       # print real do SQL — modalidade x MDR x ticket médio
    └── print_sql_percentis_segmento.png   # print real do SQL — percentis de ticket por segmento (PERCENTILE_CONT)
```

---

## O que o dashboard mostra

O bloco de topo traz os cinco números que resumem a operação: TPV, ticket médio, taxa de aprovação, chargeback rate e receita de MDR. A evolução mensal mostra o TPV crescendo de R$ 489.705,76 em janeiro para R$ 1.038.482,90 em dezembro, com salto de 32,81% em novembro (Black Friday) puxando o pico do ano. Por bandeira, Visa lidera com 38,05% do TPV, seguida por Mastercard (34,62%) e Elo (18,27%). Por modalidade, o crédito parcelado carrega o MDR mais alto (4,34% médio) contra 1,35% do débito, o que também explica por que ele responde por uma fatia desproporcional da receita de MDR mesmo movimentando menos volume que o débito. O ranking de lojistas mostra concentração: os 15 maiores TPVs somados já respondem por cerca de 8,6% de todo o volume processado, todos lojistas de porte Grande.

---

## Rodando localmente

Instale PostgreSQL 14+ e um cliente (pgAdmin ou psql). Crie um banco `adquirencia_db`, rode `02_sql/01_criar_tabelas.sql`, carregue os CSV de `03_dados/` com `02_sql/02_carregar_dados.sql` e rode `02_sql/03_limpeza.sql` seguido de `02_sql/04_analises.sql`. Para o dashboard, abra `04_dashboard_pagamentos.xlsx` direto ou siga `GUIA_POWER_BI.md` para remontar em Power BI Desktop.

---

## Autor

**Vitor França** — engcivil.vitorfranca@gmail.com
Em transição para Análise de Dados.
