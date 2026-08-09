-- ============================================================================
-- Script 02/04 - Carga dos CSVs
-- ============================================================================

SET search_path TO adquirencia, public;

\copy adquirencia.lojistas FROM '03_dados/lojistas.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy adquirencia.maquininhas FROM '03_dados/maquininhas.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy adquirencia.transacoes FROM '03_dados/transacoes.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';', NULL '')

-- Conferência rápida
SELECT 'lojistas' AS tabela, COUNT(*) FROM lojistas
UNION ALL
SELECT 'maquininhas', COUNT(*) FROM maquininhas
UNION ALL
SELECT 'transacoes', COUNT(*) FROM transacoes;
