Terceiro projeto do portfólio. Dessa vez fui pra meios de pagamento.

Modelei a operação de uma adquirente de maquininhas do zero: 3.000 lojistas, quase 4.000 terminais, 60 mil transações em 2024. Base sintética gerada com apoio de IA, modelagem e análise em PostgreSQL, dashboard no Power BI.

No SQL usei CTE, window function (RANK pra ranquear lojista por volume, LAG pra crescimento mês a mês) e PERCENTILE_CONT pra olhar a distribuição de ticket por segmento.

TPV de R$ 7,71 milhões no ano, taxa de aprovação de 91,16% e chargeback rate de 1,99% — dentro do que o mercado considera saudável. O que mais chamou atenção: o MDR do crédito parcelado é 3,2x o do débito (4,34% contra 1,35%), e dezembro sozinho processa 61,6% a mais que a média mensal, puxado por Black Friday e Natal.

Sou eng civil em transição pra dados. Se você tá no mesmo caminho, chega junto. Recrutador que quiser conversar sobre vaga jr, chama no DM.

Link do repo no primeiro comentário.

#analisededados #sql #powerbi

---

Primeiro comentário (colar após publicar):

Repositório completo aqui: https://github.com/vitordealbuquerque/projeto-adquirencia-pagamentos
