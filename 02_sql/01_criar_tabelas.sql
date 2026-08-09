-- ============================================================================
-- Script 01/04 - DDL: schema, tabelas, constraints, índices
-- Projeto: Adquirência de Pagamentos (maquininha de cartão)
-- ============================================================================

DROP SCHEMA IF EXISTS adquirencia CASCADE;
CREATE SCHEMA adquirencia;
SET search_path TO adquirencia, public;

-- ============================================================================
-- TABELA: lojistas (dimensão)
-- ============================================================================
CREATE TABLE lojistas (
    lojista_id      INTEGER PRIMARY KEY,
    nome_fantasia   VARCHAR(100) NOT NULL,
    segmento        VARCHAR(30)  NOT NULL CHECK (segmento IN
                        ('Varejo','Alimentação','Serviços','Saúde','Moda e Beleza','Educação','Outros')),
    porte           VARCHAR(15)  NOT NULL CHECK (porte IN ('MEI','Pequena','Média','Grande')),
    plano_taxa      VARCHAR(15)  NOT NULL CHECK (plano_taxa IN ('Standard','Premium','Enterprise')),
    uf              CHAR(2)      NOT NULL,
    cidade          VARCHAR(60)  NOT NULL,
    regiao          VARCHAR(20)  NOT NULL,
    data_cadastro   DATE         NOT NULL
);

-- ============================================================================
-- TABELA: maquininhas (dimensão)
-- ============================================================================
CREATE TABLE maquininhas (
    maquininha_id   INTEGER PRIMARY KEY,
    lojista_id      INTEGER NOT NULL REFERENCES lojistas(lojista_id),
    modelo          VARCHAR(30) NOT NULL CHECK (modelo IN
                        ('Modelo Chip Básico','Modelo Pro c/ Impressora','Modelo Smart Android')),
    data_ativacao   DATE NOT NULL,
    status          VARCHAR(15) NOT NULL CHECK (status IN ('Ativa','Inativa','Bloqueada'))
);

-- ============================================================================
-- TABELA: transacoes (fato)
-- ============================================================================
CREATE TABLE transacoes (
    transacao_id          INTEGER PRIMARY KEY,
    lojista_id             INTEGER NOT NULL REFERENCES lojistas(lojista_id),
    maquininha_id          INTEGER NOT NULL REFERENCES maquininhas(maquininha_id),
    data_transacao          TIMESTAMP NOT NULL,
    bandeira                VARCHAR(15) NOT NULL CHECK (bandeira IN ('Visa','Mastercard','Elo','Amex','Outras')),
    modalidade               VARCHAR(20) NOT NULL CHECK (modalidade IN ('Débito','Crédito à Vista','Crédito Parcelado')),
    parcelas                 SMALLINT NOT NULL CHECK (parcelas BETWEEN 1 AND 12),
    valor_bruto               NUMERIC(12,2) NOT NULL CHECK (valor_bruto > 0),
    taxa_mdr_pct               NUMERIC(5,2) NOT NULL CHECK (taxa_mdr_pct >= 0),
    valor_taxa                  NUMERIC(12,2) NOT NULL CHECK (valor_taxa >= 0),
    valor_liquido                NUMERIC(12,2) NOT NULL CHECK (valor_liquido >= 0),
    status                        VARCHAR(15) NOT NULL CHECK (status IN ('Aprovada','Negada','Chargeback')),
    motivo                        VARCHAR(50),
    antecipada                    BOOLEAN NOT NULL DEFAULT FALSE,
    prazo_recebimento_dias        SMALLINT
);

CREATE INDEX idx_transacoes_lojista    ON transacoes(lojista_id);
CREATE INDEX idx_transacoes_data       ON transacoes(data_transacao);
CREATE INDEX idx_transacoes_status     ON transacoes(status);
CREATE INDEX idx_maquininhas_lojista   ON maquininhas(lojista_id);
