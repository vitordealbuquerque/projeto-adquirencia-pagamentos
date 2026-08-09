# Passo a passo — Power BI (Adquirência de Pagamentos)

Do zero até o dashboard: extração dos dados, modelo, todas as medidas DAX e qual gráfico usar em cada bloco do fundo (`06_prints/fundo_dashboard_powerbi.png`, prompt no item 11 de `PROMPTS_CLAUDE_DESIGN.md`).

---

## Parte 1 — Extração dos dados no Power BI

1. Extraia os 3 CSVs de `03_dados/` (`lojistas.csv`, `maquininhas.csv`, `transacoes.csv`) numa pasta local, mantendo a estrutura `projeto-adquirencia-pagamentos/03_dados/`.
2. Abra o Power BI Desktop → **Obter dados → Texto/CSV** → importe os 3 arquivos. Delimitador é `;` (ponto e vírgula) — confira se o Power BI detectou certo, senão ajuste manualmente na tela de pré-visualização.
3. No Poder Query (**Transformar dados**), confirme os tipos de coluna: `data_transacao` como Data/Hora, `valor_bruto`/`taxa_mdr_pct`/`valor_taxa`/`valor_liquido` como Decimal, `parcelas` como Número Inteiro, `antecipada` como Verdadeiro/Falso.
4. **Início → Fechar e Aplicar**.
5. Confirma no painel "Dados" que veio: `transacoes` (60.000 linhas), `lojistas` (3.000), `maquininhas` (3.990). Se algum número vier diferente, confira o CSV de origem.

## Parte 2 — Conferir o modelo

1. Vá na view **Modelo** (ícone de diagrama, barra lateral esquerda).
2. Confirme as duas relações: `lojistas[lojista_id]` → `transacoes[lojista_id]` e `maquininhas[maquininha_id]` → `transacoes[maquininha_id]`, ambas 1 para muitos, direção única (filtro de lojistas/maquininhas para transações).
3. Crie a coluna calculada `ano_mes` em `transacoes` (mesma lógica do `03_limpeza.sql`), se ela não vier pronta da extração:

```dax
ano_mes = FORMAT(transacoes[data_transacao], "YYYY-MM")
```

## Parte 3 — Medidas DAX

Crie cada uma como **Nova medida** (não confundir com coluna calculada — nome duplicado entre os dois trava o Power BI com erro de nome já em uso).

| Medida | Fórmula DAX | Formato | Valor real (referência) |
|---|---|---|---|
| Transacoes Totais | `COUNTROWS(transacoes)` | inteiro | 60.000 |
| Aprovadas | `CALCULATE(COUNTROWS(transacoes), transacoes[status]="Aprovada")` | inteiro | 54.693 |
| Negadas | `CALCULATE(COUNTROWS(transacoes), transacoes[status]="Negada")` | inteiro | 4.114 |
| Chargebacks | `CALCULATE(COUNTROWS(transacoes), transacoes[status]="Chargeback")` | inteiro | 1.193 |
| Taxa Aprovacao % | `DIVIDE([Aprovadas], [Transacoes Totais])` | percentual | 91,16% |
| Chargeback Rate % | `DIVIDE([Chargebacks], [Transacoes Totais])` | percentual | 1,99% |
| TPV | `CALCULATE(SUM(transacoes[valor_bruto]), transacoes[status]="Aprovada")` | moeda | R$ 7.710.096,87 |
| Ticket Medio | `CALCULATE(AVERAGE(transacoes[valor_bruto]), transacoes[status]="Aprovada")` | moeda | R$ 140,97 |
| Receita MDR | `CALCULATE(SUM(transacoes[valor_taxa]), transacoes[status]="Aprovada")` | moeda | R$ 203.760,95 |
| MDR Medio Blended % | `DIVIDE([Receita MDR], [TPV])` | percentual | 2,64% |
| TPV Mes Anterior | ver bloco abaixo | moeda | — (varia por mês) |
| Crescimento MoM % | `DIVIDE([TPV] - [TPV Mes Anterior], [TPV Mes Anterior])` | percentual | Nov: +32,81% · Dez: +12,53% |
| % Antecipacao Credito | `DIVIDE(CALCULATE(COUNTROWS(transacoes), transacoes[antecipada]=TRUE(), transacoes[modalidade]<>"Débito"), CALCULATE(COUNTROWS(transacoes), transacoes[status]="Aprovada", transacoes[modalidade]<>"Débito"))` | percentual | ≈ 18% |

`TPV Mes Anterior` usa a mesma lógica de "mês anterior sem tabela calendário" já validada nos outros projetos do portfólio (comparação de texto, já que `ano_mes` no formato `YYYY-MM` ordena certo):

```dax
TPV Mes Anterior =
VAR MesAtual = SELECTEDVALUE(transacoes[ano_mes])
VAR MesAnterior =
    CALCULATE(MAX(transacoes[ano_mes]), FILTER(ALL(transacoes[ano_mes]), transacoes[ano_mes] < MesAtual))
RETURN
    CALCULATE([TPV], transacoes[ano_mes] = MesAnterior)
```

Isso espelha o `LAG()` usado no `04_analises.sql` (KPI 4).

## Parte 4 — Gráficos: o que colocar em cada bloco do fundo

Abra `fundo_dashboard_powerbi.png` (gerado a partir do prompt do item 11 em `PROMPTS_CLAUDE_DESIGN.md`) como imagem de fundo da página (**Formatar página → Imagem de fundo**, transparência 0%) e encaixe os visuais exatamente nas molduras:

### Cards de KPI (topo)

| Bloco no fundo | Visual | Campo |
|---|---|---|
| TPV | Cartão | `TPV` |
| TICKET MÉDIO | Cartão | `Ticket Medio` |
| TAXA DE APROVAÇÃO | Cartão | `Taxa Aprovacao %` |
| CHARGEBACK RATE | Cartão | `Chargeback Rate %` |
| RECEITA DE MDR | Cartão | `Receita MDR` |

### EVOLUÇÃO MENSAL

Visual (ícone no painel Visualizações): **Gráfico de Linhas**.
* Eixo X: `transacoes[ano_mes]`
* Valores (eixo primário): `TPV`
* Valores (eixo secundário): `Taxa Aprovacao %`
* Tooltip: `Crescimento MoM %`

### TPV POR BANDEIRA

Visual (ícone no painel Visualizações): **Gráfico de Rosca**.
* Legenda: `transacoes[bandeira]`
* Valores: `TPV`

### RANKING LOJISTAS

Visual (ícone no painel Visualizações): **Gráfico de Barras Agrupadas** (o de barra na horizontal, não confundir com "Gráfico de Colunas Agrupadas" que é na vertical). Filtro de página/visual: Top 15 por TPV (**Filtros → Tipo de filtro: Top N**).
* Eixo Y: `lojistas[nome_fantasia]`
* Valores: `TPV`

### MODALIDADE X MDR

Visual (ícone no painel Visualizações): **Gráfico de Colunas Clusterizadas e Linhas** (combo — Ticket Médio e MDR % têm escalas muito diferentes; colunas simples achatariam a menor).
* Eixo X: `transacoes[modalidade]`
* Eixo y da coluna: `Ticket Medio`
* Eixo y da linha: MDR médio da modalidade (crie a medida `MDR Medio Modalidade % = CALCULATE(AVERAGE(transacoes[taxa_mdr_pct]), transacoes[status]="Aprovada")`)

### TPV POR REGIÃO

Visual (ícone no painel Visualizações): **Gráfico de Colunas Agrupadas**.
* Eixo X: `lojistas[regiao]`
* Valores: `TPV`

> **Nota importante (armadilha já mapeada nos outros projetos do portfólio):** o visual nativo **Mapa** do Power BI depende de geocodificação via Bing/Azure Maps, que exige conta Microsoft e às vezes confunde sigla de UF brasileira com sigla de estado americano. Por isso esse bloco usa **Gráfico de Colunas Agrupadas** por região em vez de mapa — mais simples, sem dependência externa, e não perde a informação (o dado já está agregado por região/UF no `04_analises.sql`, KPI 9). Se ainda assim quiser tentar o Mapa, ele vem desabilitado por padrão: Arquivo → Opções e configurações → Opções → Segurança → "Mapa e visuais de Mapa Preenchido".

### Página extra (opcional) — Motivos de negada e chargeback

Não está no fundo atual, mas dá pra adicionar como página 2:
* Visual: **Gráfico de Barras Agrupadas**
* Eixo Y: `transacoes[motivo]`
* Valores: contagem de `transacoes[transacao_id]`
* Filtro de página: `transacoes[status]` em (`Negada`, `Chargeback`)

## Depois de montar

Tira os prints direto do Power BI Desktop com os dados reais carregados — são esses que entram no README e no post do LinkedIn (nunca usar mockup fabricado no lugar do print real).
# Passo a passo — Power BI (Adquirência de Pagamentos)

Do zero até o dashboard: extração dos dados, modelo, todas as medidas DAX e qual gráfico usar em cada bloco do fundo (`06_prints/fundo_dashboard_powerbi.png`, prompt no item 11 de `PROMPTS_CLAUDE_DESIGN.md`).

---

## Parte 1 — Extração dos dados no Power BI

1. Extraia os 3 CSVs de `03_dados/` (`lojistas.csv`, `maquininhas.csv`, `transacoes.csv`) numa pasta local, mantendo a estrutura `projeto-adquirencia-pagamentos/03_dados/`.
2. Abra o Power BI Desktop → **Obter dados → Texto/CSV** → importe os 3 arquivos. Delimitador é `;` (ponto e vírgula) — confira se o Power BI detectou certo, senão ajuste manualmente na tela de pré-visualização.
3. No Poder Query (**Transformar dados**), confirme os tipos de coluna: `data_transacao` como Data/Hora, `valor_bruto`/`taxa_mdr_pct`/`valor_taxa`/`valor_liquido` como Decimal, `parcelas` como Número Inteiro, `antecipada` como Verdadeiro/Falso.
4. **Início → Fechar e Aplicar**.
5. Confirma no painel "Dados" que veio: `transacoes` (60.000 linhas), `lojistas` (3.000), `maquininhas` (3.990). Se algum número vier diferente, confira o CSV de origem.

## Parte 2 — Conferir o modelo

1. Vá na view **Modelo** (ícone de diagrama, barra lateral esquerda).
2. Confirme as duas relações: `lojistas[lojista_id]` → `transacoes[lojista_id]` e `maquininhas[maquininha_id]` → `transacoes[maquininha_id]`, ambas 1 para muitos, direção única (filtro de lojistas/maquininhas para transações).
3. Crie a coluna calculada `ano_mes` em `transacoes` (mesma lógica do `03_limpeza.sql`), se ela não vier pronta da extração:

```dax
ano_mes = FORMAT(transacoes[data_transacao], "YYYY-MM")
```

## Parte 3 — Medidas DAX

Crie cada uma como **Nova medida** (não confundir com coluna calculada — nome duplicado entre os dois trava o Power BI com erro de nome já em uso).

| Medida | Fórmula DAX | Formato | Valor real (referência) |
|---|---|---|---|
| Transacoes Totais | `COUNTROWS(transacoes)` | inteiro | 60.000 |
| Aprovadas | `CALCULATE(COUNTROWS(transacoes), transacoes[status]="Aprovada")` | inteiro | 54.693 |
| Negadas | `CALCULATE(COUNTROWS(transacoes), transacoes[status]="Negada")` | inteiro | 4.114 |
| Chargebacks | `CALCULATE(COUNTROWS(transacoes), transacoes[status]="Chargeback")` | inteiro | 1.193 |
| Taxa Aprovacao % | `DIVIDE([Aprovadas], [Transacoes Totais])` | percentual | 91,16% |
| Chargeback Rate % | `DIVIDE([Chargebacks], [Transacoes Totais])` | percentual | 1,99% |
| TPV | `CALCULATE(SUM(transacoes[valor_bruto]), transacoes[status]="Aprovada")` | moeda | R$ 7.710.096,87 |
| Ticket Medio | `CALCULATE(AVERAGE(transacoes[valor_bruto]), transacoes[status]="Aprovada")` | moeda | R$ 140,97 |
| Receita MDR | `CALCULATE(SUM(transacoes[valor_taxa]), transacoes[status]="Aprovada")` | moeda | R$ 203.760,95 |
| MDR Medio Blended % | `DIVIDE([Receita MDR], [TPV])` | percentual | 2,64% |
| TPV Mes Anterior | ver bloco abaixo | moeda | — (varia por mês) |
| Crescimento MoM % | `DIVIDE([TPV] - [TPV Mes Anterior], [TPV Mes Anterior])` | percentual | Nov: +32,81% · Dez: +12,53% |
| % Antecipacao Credito | `DIVIDE(CALCULATE(COUNTROWS(transacoes), transacoes[antecipada]=TRUE(), transacoes[modalidade]<>"Débito"), CALCULATE(COUNTROWS(transacoes), transacoes[status]="Aprovada", transacoes[modalidade]<>"Débito"))` | percentual | ≈ 18% |

`TPV Mes Anterior` usa a mesma lógica de "mês anterior sem tabela calendário" já validada nos outros projetos do portfólio (comparação de texto, já que `ano_mes` no formato `YYYY-MM` ordena certo):

```dax
TPV Mes Anterior =
VAR MesAtual = SELECTEDVALUE(transacoes[ano_mes])
VAR MesAnterior =
    CALCULATE(MAX(transacoes[ano_mes]), FILTER(ALL(transacoes[ano_mes]), transacoes[ano_mes] < MesAtual))
RETURN
    CALCULATE([TPV], transacoes[ano_mes] = MesAnterior)
```

Isso espelha o `LAG()` usado no `04_analises.sql` (KPI 4).

## Parte 4 — Gráficos: o que colocar em cada bloco do fundo

Abra `fundo_dashboard_powerbi.png` (gerado a partir do prompt do item 11 em `PROMPTS_CLAUDE_DESIGN.md`) como imagem de fundo da página (**Formatar página → Imagem de fundo**, transparência 0%) e encaixe os visuais exatamente nas molduras:

### Cards de KPI (topo)

| Bloco no fundo | Visual | Campo |
|---|---|---|
| TPV | Cartão | `TPV` |
| TICKET MÉDIO | Cartão | `Ticket Medio` |
| TAXA DE APROVAÇÃO | Cartão | `Taxa Aprovacao %` |
| CHARGEBACK RATE | Cartão | `Chargeback Rate %` |
| RECEITA DE MDR | Cartão | `Receita MDR` |

### EVOLUÇÃO MENSAL

Visual (ícone no painel Visualizações): **Gráfico de Linhas**.
* Eixo X: `transacoes[ano_mes]`
* Valores (eixo primário): `TPV`
* Valores (eixo secundário): `Taxa Aprovacao %`
* Tooltip: `Crescimento MoM %`

### TPV POR BANDEIRA

Visual (ícone no painel Visualizações): **Gráfico de Rosca**.
* Legenda: `transacoes[bandeira]`
* Valores: `TPV`

### RANKING LOJISTAS

Visual (ícone no painel Visualizações): **Gráfico de Barras Agrupadas** (o de barra na horizontal, não confundir com "Gráfico de Colunas Agrupadas" que é na vertical). Filtro de página/visual: Top 15 por TPV (**Filtros → Tipo de filtro: Top N**).
* Eixo Y: `lojistas[nome_fantasia]`
* Valores: `TPV`

### MODALIDADE X MDR

Visual (ícone no painel Visualizações): **Gráfico de Colunas Clusterizadas e Linhas** (combo — Ticket Médio e MDR % têm escalas muito diferentes; colunas simples achatariam a menor).
* Eixo X: `transacoes[modalidade]`
* Eixo y da coluna: `Ticket Medio`
* Eixo y da linha: MDR médio da modalidade (crie a medida `MDR Medio Modalidade % = CALCULATE(AVERAGE(transacoes[taxa_mdr_pct]), transacoes[status]="Aprovada")`)

### TPV POR REGIÃO

Visual (ícone no painel Visualizações): **Gráfico de Colunas Agrupadas**.
* Eixo X: `lojistas[regiao]`
* Valores: `TPV`

> **Nota importante (armadilha já mapeada nos outros projetos do portfólio):** o visual nativo **Mapa** do Power BI depende de geocodificação via Bing/Azure Maps, que exige conta Microsoft e às vezes confunde sigla de UF brasileira com sigla de estado americano. Por isso esse bloco usa **Gráfico de Colunas Agrupadas** por região em vez de mapa — mais simples, sem dependência externa, e não perde a informação (o dado já está agregado por região/UF no `04_analises.sql`, KPI 9). Se ainda assim quiser tentar o Mapa, ele vem desabilitado por padrão: Arquivo → Opções e configurações → Opções → Segurança → "Mapa e visuais de Mapa Preenchido".

### Página extra (opcional) — Motivos de negada e chargeback

Não está no fundo atual, mas dá pra adicionar como página 2:
* Visual: **Gráfico de Barras Agrupadas**
* Eixo Y: `transacoes[motivo]`
* Valores: contagem de `transacoes[transacao_id]`
* Filtro de página: `transacoes[status]` em (`Negada`, `Chargeback`)

## Depois de montar

Tira os prints direto do Power BI Desktop com os dados reais carregados — são esses que entram no README e no post do LinkedIn (nunca usar mockup fabricado no lugar do print real).
