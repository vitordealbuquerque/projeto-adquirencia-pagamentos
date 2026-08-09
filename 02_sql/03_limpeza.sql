-- ============================================================================
-- Script 03/04 - Checagens + colunas derivadas
-- ============================================================================

SET search_path TO adquirencia, public;

-- Checagem de nulos em colunas obrigatórias
SELECT
    COUNT(*) FILTER (WHERE lojista_id IS NULL)      AS null_lojista,
    COUNT(*) FILTER (WHERE valor_bruto IS NULL)      AS null_valor_bruto,
    COUNT(*) FILTER (WHERE data_transacao IS NULL)   AS null_data,
    COUNT(*) FILTER (WHERE status IS NULL)            AS null_status
FROM transacoes;

-- Coluna derivada: ano_mes (YYYY-MM), pra evolução mensal sem tabela calendário
ALTER TABLE transacoes ADD COLUMN IF NOT EXISTS ano_mes VARCHAR(7);
UPDATE transacoes SET ano_mes = TO_CHAR(data_transacao, 'YYYY-MM');

-- Coluna derivada: aprovada (1/0), facilita FILTER e AVG em taxa de aprovação
ALTER TABLE transacoes ADD COLUMN IF NOT EXISTS aprovada SMALLINT;
UPDATE transacoes SET aprovada = CASE WHEN status = 'Aprovada' THEN 1 ELSE 0 END;

-- Coluna derivada: chargeback (1/0)
ALTER TABLE transacoes ADD COLUMN IF NOT EXISTS chargeback SMALLINT;
UPDATE transacoes SET chargeback = CASE WHEN status = 'Chargeback' THEN 1 ELSE 0 END;

-- Coluna derivada: dia_semana (pra eventual análise de sazonalidade semanal)
ALTER TABLE transacoes ADD COLUMN IF NOT EXISTS dia_semana VARCHAR(15);
UPDATE transacoes SET dia_semana = TO_CHAR(data_transacao, 'Day');

-- Conferência pós-limpeza
SELECT ano_mes, COUNT(*) FROM transacoes GROUP BY ano_mes ORDER BY ano_mes;
