-- ============================================================================
-- Script 04/04 - Análises intermediárias
-- Usa: CTE, window functions (RANK/LAG), PERCENTILE_CONT, FILTER, JOIN
-- Cada bloco alimenta um card ou visual do dashboard.
-- ============================================================================

SET search_path TO adquirencia, public;

-- ============================================================================
-- KPI 1 — Panorama executivo
-- ============================================================================
SELECT
    COUNT(*)                                          AS transacoes_total,
    COUNT(*) FILTER (WHERE status = 'Aprovada')       AS aprovadas,
    COUNT(*) FILTER (WHERE status = 'Negada')         AS negadas,
    COUNT(*) FILTER (WHERE status = 'Chargeback')     AS chargebacks,
    ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'Aprovada') / COUNT(*), 2)   AS taxa_aprovacao_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'Chargeback') / COUNT(*), 3) AS chargeback_rate_pct,
    ROUND(SUM(valor_bruto) FILTER (WHERE status = 'Aprovada')::numeric, 2)     AS tpv_total,
    ROUND(AVG(valor_bruto) FILTER (WHERE status = 'Aprovada')::numeric, 2)     AS ticket_medio,
    ROUND(SUM(valor_taxa) FILTER (WHERE status = 'Aprovada')::numeric, 2)      AS receita_mdr_total,
    ROUND(100.0 * SUM(valor_taxa) FILTER (WHERE status = 'Aprovada') /
                  NULLIF(SUM(valor_bruto) FILTER (WHERE status = 'Aprovada'), 0), 3) AS mdr_medio_blended_pct
FROM transacoes;

-- ============================================================================
-- KPI 2 — TPV e aprovação por bandeira
-- ============================================================================
SELECT
    bandeira,
    COUNT(*)                                                    AS transacoes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE status='Aprovada') / COUNT(*), 2) AS taxa_aprovacao_pct,
    ROUND(SUM(valor_bruto) FILTER (WHERE status='Aprovada')::numeric, 2)   AS tpv,
    ROUND(100.0*SUM(valor_bruto) FILTER (WHERE status='Aprovada')
              / SUM(SUM(valor_bruto) FILTER (WHERE status='Aprovada')) OVER (), 2) AS share_tpv_pct
FROM transacoes
GROUP BY bandeira
ORDER BY tpv DESC;

-- ============================================================================
-- KPI 3 — Ranking de lojistas por TPV (top 15)
-- Usa window function pra ranquear e share sobre o total
-- ============================================================================
WITH stats AS (
    SELECT
        l.lojista_id,
        l.nome_fantasia,
        l.segmento,
        l.porte,
        l.uf,
        COUNT(*) FILTER (WHERE t.status='Aprovada')                       AS transacoes_aprovadas,
        ROUND(SUM(t.valor_bruto) FILTER (WHERE t.status='Aprovada')::numeric, 2) AS tpv
    FROM transacoes t
    JOIN lojistas l USING (lojista_id)
    GROUP BY l.lojista_id, l.nome_fantasia, l.segmento, l.porte, l.uf
)
SELECT
    nome_fantasia,
    segmento,
    porte,
    uf,
    transacoes_aprovadas,
    tpv,
    RANK() OVER (ORDER BY tpv DESC)                       AS rank_tpv,
    ROUND(100.0*tpv / SUM(tpv) OVER (), 3)                AS share_tpv_pct
FROM stats
ORDER BY tpv DESC
LIMIT 15;

-- ============================================================================
-- KPI 4 — Evolução mensal e crescimento MoM (LAG)
-- ============================================================================
WITH mensal AS (
    SELECT
        ano_mes,
        COUNT(*) FILTER (WHERE status='Aprovada')                              AS transacoes,
        ROUND(SUM(valor_bruto) FILTER (WHERE status='Aprovada')::numeric, 2)   AS tpv,
        ROUND(100.0 * COUNT(*) FILTER (WHERE status='Aprovada') / COUNT(*), 2) AS taxa_aprovacao_pct,
        ROUND(100.0 * COUNT(*) FILTER (WHERE status='Chargeback') / COUNT(*), 3) AS chargeback_rate_pct
    FROM transacoes
    GROUP BY ano_mes
)
SELECT
    ano_mes,
    transacoes,
    tpv,
    taxa_aprovacao_pct,
    chargeback_rate_pct,
    LAG(tpv) OVER (ORDER BY ano_mes)                                       AS tpv_mes_anterior,
    ROUND(100.0*(tpv - LAG(tpv) OVER (ORDER BY ano_mes))
              / NULLIF(LAG(tpv) OVER (ORDER BY ano_mes), 0), 2)           AS crescimento_pct
FROM mensal
ORDER BY ano_mes;

-- ============================================================================
-- KPI 5 — Top motivos de negada e chargeback
-- ============================================================================
SELECT
    status,
    motivo,
    COUNT(*)                                          AS ocorrencias,
    ROUND(100.0*COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY status), 2)  AS pct_do_status
FROM transacoes
WHERE status IN ('Negada','Chargeback')
GROUP BY status, motivo
ORDER BY status, ocorrencias DESC;

-- ============================================================================
-- KPI 6 — Modalidade x MDR médio x ticket médio
-- ============================================================================
SELECT
    modalidade,
    COUNT(*) FILTER (WHERE status='Aprovada')                                AS transacoes,
    ROUND(AVG(valor_bruto) FILTER (WHERE status='Aprovada')::numeric, 2)     AS ticket_medio,
    ROUND(AVG(taxa_mdr_pct) FILTER (WHERE status='Aprovada')::numeric, 2)    AS mdr_medio_pct,
    ROUND(SUM(valor_bruto) FILTER (WHERE status='Aprovada')::numeric, 2)     AS tpv,
    ROUND(SUM(valor_taxa) FILTER (WHERE status='Aprovada')::numeric, 2)      AS receita_mdr
FROM transacoes
GROUP BY modalidade
ORDER BY tpv DESC;

-- ============================================================================
-- KPI 7 — Percentis de ticket por segmento (mín. 30 transações aprovadas)
-- ============================================================================
WITH seg AS (
    SELECT
        l.segmento,
        t.valor_bruto
    FROM transacoes t
    JOIN lojistas l USING (lojista_id)
    WHERE t.status = 'Aprovada'
)
SELECT
    segmento,
    COUNT(*)                                                                AS transacoes,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY valor_bruto)::numeric, 2) AS p50_ticket,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY valor_bruto)::numeric, 2) AS p90_ticket,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY valor_bruto)::numeric, 2) AS p99_ticket
FROM seg
GROUP BY segmento
HAVING COUNT(*) >= 30
ORDER BY p90_ticket DESC;

-- ============================================================================
-- KPI 8 — Chargeback rate por segmento (RANK)
-- ============================================================================
SELECT
    l.segmento,
    COUNT(*)                                                                    AS transacoes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE t.status='Chargeback') / COUNT(*), 3)  AS chargeback_rate_pct,
    RANK() OVER (ORDER BY 100.0 * COUNT(*) FILTER (WHERE t.status='Chargeback') / COUNT(*) DESC) AS rank_risco
FROM transacoes t
JOIN lojistas l USING (lojista_id)
GROUP BY l.segmento
ORDER BY chargeback_rate_pct DESC;

-- ============================================================================
-- KPI 9 — TPV e receita de MDR por região/UF
-- ============================================================================
SELECT
    l.regiao,
    l.uf,
    COUNT(*) FILTER (WHERE t.status='Aprovada')                              AS transacoes,
    ROUND(SUM(t.valor_bruto) FILTER (WHERE t.status='Aprovada')::numeric, 2) AS tpv,
    ROUND(SUM(t.valor_taxa) FILTER (WHERE t.status='Aprovada')::numeric, 2)  AS receita_mdr,
    ROUND(100.0 * COUNT(*) FILTER (WHERE t.status='Aprovada') /
                  COUNT(*), 2)                                                AS taxa_aprovacao_pct
FROM transacoes t
JOIN lojistas l USING (lojista_id)
GROUP BY l.regiao, l.uf
ORDER BY tpv DESC;

-- ============================================================================
-- KPI 10 — TPV médio por porte e plano de taxa
-- ============================================================================
SELECT
    l.porte,
    l.plano_taxa,
    COUNT(DISTINCT l.lojista_id)                                                AS lojistas,
    ROUND(SUM(t.valor_bruto) FILTER (WHERE t.status='Aprovada')::numeric, 2)    AS tpv,
    ROUND(SUM(t.valor_bruto) FILTER (WHERE t.status='Aprovada')::numeric /
              NULLIF(COUNT(DISTINCT l.lojista_id), 0), 2)                        AS tpv_medio_por_lojista,
    ROUND(100.0 * SUM(CASE WHEN t.antecipada THEN 1 ELSE 0 END) FILTER (WHERE t.status='Aprovada') /
                  NULLIF(COUNT(*) FILTER (WHERE t.status='Aprovada' AND t.modalidade != 'Débito'), 0), 2) AS pct_antecipacao_credito
FROM transacoes t
JOIN lojistas l USING (lojista_id)
GROUP BY l.porte, l.plano_taxa
ORDER BY tpv DESC;
