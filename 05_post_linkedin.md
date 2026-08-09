# Post pronto pro LinkedIn (versão humanizada — final)

> Terceiro projeto do portfólio. Dessa vez fui pra meios de pagamento.
>
> Modelei a operação de uma adquirente de maquininhas do zero: 3.000 lojistas, quase 4.000 terminais, 60 mil transações em 2024. Base e análises em PostgreSQL, dashboard no Power BI.
>
> No SQL usei CTE, window function (RANK pra ranquear lojista por volume, LAG pra crescimento mês a mês) e PERCENTILE_CONT pra olhar a distribuição de ticket por segmento.
>
> TPV de R$ 7,71 milhões no ano, taxa de aprovação de 91,16% e chargeback rate de 1,99% — dentro do que o mercado considera saudável. O que mais chamou atenção: o MDR do crédito parcelado é 3,2x o do débito (4,34% contra 1,35%), e dezembro sozinho processa 61,6% a mais que a média mensal, puxado por Black Friday e Natal.
>
> Sou eng civil em transição pra dados. Se você tá no mesmo caminho, chega junto. Recrutador que quiser conversar sobre vaga jr, chama no DM.
>
> Link do repo no primeiro comentário.
>
> #analisededados #sql #powerbi

---

## Primeiro comentário (colar após publicar)

Repositório completo com todos os arquivos aqui:
https://github.com/vitordealbuquerque/projeto-adquirencia-pagamentos

---

# Versões descartadas (arquivo)

Três versões — escolha a que combina mais com sua voz. Todas escritas pra sair natural, sem cara de IA.

---

## VERSÃO 1 — Storytelling da transição (recomendada)

> Terceiro projeto do meu portfólio de análise de dados. Dessa vez fui pra pagamentos.
>
> Modelei uma operação de adquirência: 3.000 lojistas, 3.990 maquininhas, 60 mil transações em 2024, cobrindo 19 UFs. Tudo em PostgreSQL, dashboard em Power BI.
>
> O que saiu:
>
> → TPV de R$ 7,71 milhões · taxa de aprovação de 91,16%
> → Chargeback rate de 1,99% · dentro da faixa saudável do setor
> → MDR do crédito parcelado é 3,2x o do débito (4,34% vs 1,35%)
> → Dezembro processa 61,6% a mais que a média mensal, puxado por Black Friday e Natal
> → Os 15 maiores lojistas (todos porte Grande) somam 8,6% de todo o TPV
> → Top motivo de chargeback: duplicidade de cobrança (22% dos casos)
>
> O que aprendi montando: taxa de aprovação e chargeback rate parecem saudáveis quando olhadas isoladas (91% e 2%). O que muda a leitura é cruzar com modalidade — o parcelado custa 3x mais em MDR pro lojista, então empurrar o mix pra lá sem entender o motivo pode parecer bom pro caixa e ruim pro relacionamento comercial.
>
> Repositório completo (SQL + CSV + Excel + guia de Power BI) no primeiro comentário.
>
> Se você também está em transição, chega junto. Compartilhar tropeço economiza tempo dos dois.
>
> #dados #sql #postgresql #powerbi #pagamentos #transicaodecarreira

---

## VERSÃO 2 — Direta, focada no que fez

> Novo projeto no portfólio: panorama de pagamentos de uma adquirente de maquininhas.
>
> **Stack:** PostgreSQL (modelagem + análise), Power BI (dashboard).
>
> **O que fiz:**
> · Modelei 3 tabelas em modelo estrela (lojistas, maquininhas, transacoes)
> · Escrevi 4 scripts SQL — DDL, carga, limpeza e 10 análises
> · Usei CTE, window functions (RANK, LAG) e PERCENTILE_CONT
> · Dashboard com evolução mensal, TPV por bandeira, ranking de lojistas e modalidade x MDR
>
> **Insight que valeu a construção:** o MDR médio do crédito parcelado (4,34%) é mais que o triplo do débito (1,35%). Isso significa que decisões de mix de modalidade pesam direto na margem — olhar só o TPV total esconde isso.
>
> Deixei tudo público no primeiro comentário. Feedback é bem-vindo.
>
> #sql #postgresql #powerbi #pagamentos #dataanalytics

---

## VERSÃO 3 — Curta

> Novo projeto: panorama de pagamentos de uma adquirente de cartão.
>
> 60 mil transações, PostgreSQL, Power BI, 10 análises.
>
> Três coisas que descobri:
> 1. Taxa de aprovação de 91% parece boa — mas varia por bandeira e modalidade
> 2. MDR do parcelado é 3,2x o do débito
> 3. Dezembro sozinho processa 61,6% a mais que a média mensal
>
> Repositório no comentário.
>
> #dados #sql #powerbi

---

## Dicas de postagem

**Ordem sugerida de imagens no post (prints reais, conferidos contra a execução do SQL):**
1. `06_prints/capa_linkedin.png` — abre com os 3 números que prendem atenção (TPV, taxa de aprovação, transações)
2. `06_prints/print_dashboard_final.png` — dashboard completo do Power BI (print real, tirado depois de fechar o modelo)
3. `06_prints/print_sql_ranking_lojistas.png` — mostra o SQL de verdade (window function RANK)
4. `06_prints/print_sql_evolucao_mensal.png` — window function LAG, crescimento MoM

**Melhor horário para publicar:** terça a quinta, 8h-10h ou 18h-20h.

**No primeiro comentário** (LinkedIn penaliza link no corpo):
> Repositório completo aqui: [link do GitHub]
> Se preferir só o dashboard: [link direto do arquivo]

**O que responder ao recrutador:**
> "Se quiser conversar sobre a vaga, me chama no DM — mando o currículo e a gente marca uma call."
